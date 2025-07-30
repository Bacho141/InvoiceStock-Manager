import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../screens/sale/add_product_modal.dart';
import '../../../screens/sale/edit_invoice_modal.dart';
import '../../../screens/sale/delete_product_modal.dart';
import '../../services/printer_service.dart';
import './pos_ticket.dart';
import './printer_selector.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';

import '../../utiles/store_helper.dart';

class InvoiceActions extends StatelessWidget {
  final Map<String, dynamic> facture;
  final VoidCallback onReload;
  final bool isMobile;
  final CartProvider cartProvider;
  final String? storeId;

  const InvoiceActions({
    Key? key,
    required this.facture,
    required this.onReload,
    required this.cartProvider,
    this.isMobile = false,
    this.storeId,
  }) : super(key: key);

  Future<void> _printDocument(BuildContext context) async {
    try {
      print('=== DÉBUT DU PROCESSUS D\'IMPRESSION ===');
      print('Facture ID: ${facture['_id']}');
      print('Plateforme: ${Platform.isWindows ? 'Windows' : Platform.isAndroid ? 'Android' : 'Autre'}');
      
      final printerService = PrinterService();
      final ticket = PosTicket(facture: facture);
      
      print('Services créés, génération du ticket...');
      
      final ticketBytes = await ticket.generateTicket();
      
      print('Ticket généré avec succès:');
      print('- Taille: ${ticketBytes.length} bytes');
      print('- Premiers bytes: ${ticketBytes.take(20).toList()}');
      print('- Derniers bytes: ${ticketBytes.skip(ticketBytes.length - 20).toList()}');
      
      // Vérifier si on est sur mobile ou desktop
      final isMobilePlatform = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      
      if (isMobilePlatform) {
        // Sur mobile, on utilise directement le Bluetooth
        if (kDebugMode) print('Plateforme mobile détectée, utilisation du Bluetooth');
        await _scanAndPrint(context, printerService, ticketBytes, 'bluetooth');
      } else {
        // Sur desktop, on demande le type d'impression
        if (kDebugMode) print('Plateforme desktop détectée, affichage du dialogue d\'impression');
        _showPrintDialog(context, printerService, ticketBytes);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('ERREUR lors de la préparation de l\'impression: $e');
        print('Stack trace: $stackTrace');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'impression: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showPrintDialog(
    BuildContext context,
    PrinterService printerService,
    List<int> ticketBytes,
  ) {
    print('=== AFFICHAGE DU DIALOGUE D\'IMPRESSION ===');
    print('Taille des données à imprimer: ${ticketBytes.length} bytes');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisir le mode d\'impression'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.usb),
                title: const Text('Imprimer via USB'),
                onTap: () {
                  print('UTILISATEUR A CHOISI: Impression USB');
                  Navigator.of(context).pop();
                  _scanAndPrint(context, printerService, ticketBytes, 'usb');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bluetooth),
                title: const Text('Imprimer via Bluetooth'),
                onTap: () {
                  print('UTILISATEUR A CHOISI: Impression Bluetooth');
                  Navigator.of(context).pop();
                  _scanAndPrint(context, printerService, ticketBytes, 'bluetooth');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanAndPrint(
    BuildContext context,
    PrinterService printerService,
    List<int> ticketBytes,
    String type,
  ) async {
    print('=== DÉBUT DE _scanAndPrint ===');
    print('Type d\'impression demandé: $type');
    print('Taille des données à imprimer: ${ticketBytes.length} bytes');
    
    // Afficher un indicateur de chargement
    if (context.mounted) {
      print('Affichage du message de recherche d\'imprimantes');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recherche des imprimantes...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      print('Ouverture du sélecteur d\'imprimante...');
      // Sauvegarder le contexte avant l'ouverture du modal
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      // Afficher le sélecteur d'imprimante
      final selectedDevice = await showModalBottomSheet<PrinterDevice>(
        context: context,
        isScrollControlled: true,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.6,
          child: PrinterSelector(
            printerService: printerService,
            type: type,
          ),
        ),
      );

      print('Sélecteur fermé. Imprimante sélectionnée: ${selectedDevice?.name ?? "Aucune"}');
      print('selectedDevice == null: ${selectedDevice == null}');

      if (selectedDevice != null) {
        print('=== DÉBUT DE L\'IMPRESSION ===');
        print('Imprimante sélectionnée: ${selectedDevice.name}');
        print('Adresse: ${selectedDevice.address}');
        
        // Afficher un indicateur pendant l'impression
        print('Affichage du SnackBar de connexion...');
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Connexion à l\'imprimante...'),
            duration: Duration(seconds: 2),
          ),
        );

        print('Appel de connectAndPrint...');
        try {
          // Lancer l'impression
          final success = await printerService.connectAndPrint(
            device: selectedDevice,
            type: type,
            ticketBytes: ticketBytes,
          );

          print('Résultat de l\'impression: $success');
          
          // Afficher le résultat
          print('Affichage du résultat final...');
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                success 
                  ? 'Impression réussie !' 
                  : 'Échec de l\'impression. Vérifiez la connexion.',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (e, stackTrace) {
          print('ERREUR dans connectAndPrint: $e');
          print('StackTrace: $stackTrace');
        }
      } else {
        print('AUCUNE IMPRIMANTE SÉLECTIONNÉE ou contexte non monté');
        if (selectedDevice == null) {
          print('Raison: selectedDevice est null');
        }
        if (!context.mounted) {
          print('Raison: context n\'est pas monté');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la connexion à l\'imprimante'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddProductModal(BuildContext context) async {
    String? effectiveStoreId = storeId;
    if (effectiveStoreId == null) {
      effectiveStoreId = await getSelectedStoreId(context: context, showError: true);
      if (effectiveStoreId == null) {
        // Error already shown by helper
        return;
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ChangeNotifierProvider.value(
        value: cartProvider,
        child: FractionallySizedBox(
          heightFactor: isMobile ? 0.8 : 0.9,
          child: AddProductModal(facture: facture, onProductAdded: onReload, storeId: effectiveStoreId),
        ),
      ),
    );
  }

  void _showEditInvoiceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: isMobile ? 0.8 : 0.9,
        child: EditInvoiceModal(facture: facture, onInvoiceUpdated: onReload),
      ),
    );
  }

  void _showDeleteProductModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: isMobile ? 0.7 : 0.8,
        child: DeleteProductModal(facture: facture, onProductRemoved: onReload),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bouton Imprimer
        ElevatedButton.icon(
          onPressed: () => _printDocument(context),
          icon: const Icon(Icons.print, size: 18),
          label: const Text('Imprimer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7717E8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: isMobile
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(width: 16),
        // Bouton Ajouter
        ElevatedButton.icon(
          onPressed: () => _showAddProductModal(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7717E8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: isMobile
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        // Menu déroulant avec les actions supplémentaires
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF7717E8), size: 28),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditInvoiceModal(context);
                break;
              case 'delete':
                _showDeleteProductModal(context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, size: 20),
                title: Text('Modifier'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, size: 20, color: Colors.red),
                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
