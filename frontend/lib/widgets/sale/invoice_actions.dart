import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../screens/sale/add_product_modal.dart';
import '../../../screens/sale/edit_invoice_modal.dart';
import '../../../screens/sale/delete_product_modal.dart';
import '../../services/printer_service.dart';
import '../../services/invoice_service.dart';
import './pos_ticket.dart';
import './printer_selector.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';

import '../../utiles/store_helper.dart';

class InvoiceActions extends StatelessWidget {
  final Map<String, dynamic> facture;
  final VoidCallback onReload;
  final bool isMobile;
  final CartProvider cartProvider;
  final String? storeId;
  final bool showSaleActions;

  const InvoiceActions({
    Key? key,
    required this.facture,
    required this.onReload,
    required this.cartProvider,
    this.isMobile = false,
    this.storeId,
    this.showSaleActions = true,
  }) : super(key: key);

  Future<void> _printDocument(BuildContext context) async {
    try {
      print('=== DÉBUT DU PROCESSUS D\'IMPRESSION ===');
      print('Facture ID: ${facture['_id']}');
      print(
        'Plateforme: ${Platform.isWindows
            ? 'Windows'
            : Platform.isAndroid
            ? 'Android'
            : 'Autre'}',
      );

      final printerService = PrinterService();
      final ticket = PosTicket(facture: facture);

      print('Services créés, génération du ticket...');

      final ticketBytes = await ticket.generateTicket();

      print('Ticket généré avec succès:');
      print('- Taille: ${ticketBytes.length} bytes');
      print('- Premiers bytes: ${ticketBytes.take(20).toList()}');
      print(
        '- Derniers bytes: ${ticketBytes.skip(ticketBytes.length - 20).toList()}',
      );

      // Vérifier si on est sur mobile ou desktop
      final isMobilePlatform =
          !kIsWeb && (Platform.isAndroid || Platform.isIOS);

      if (isMobilePlatform) {
        // Sur mobile, on utilise directement le Bluetooth
        if (kDebugMode)
          print('Plateforme mobile détectée, utilisation du Bluetooth');
        await _scanAndPrint(context, printerService, ticketBytes, 'bluetooth');
      } else {
        // Sur desktop, on demande le type d'impression
        if (kDebugMode)
          print(
            'Plateforme desktop détectée, affichage du dialogue d\'impression',
          );
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
                  _scanAndPrint(
                    context,
                    printerService,
                    ticketBytes,
                    'bluetooth',
                  );
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
          child: PrinterSelector(printerService: printerService, type: type),
        ),
      );

      print(
        'Sélecteur fermé. Imprimante sélectionnée: ${selectedDevice?.name ?? "Aucune"}',
      );
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

  Future<void> _downloadPDF(BuildContext context) async {
    print(
      '[DEBUG][_downloadPDF] Début de _downloadPDF pour facture ${facture['_id']}',
    );
    print('[DEBUG][_downloadPDF] Context mounted: ${context.mounted}');

    // Afficher un menu d'options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Options PDF - Facture ${facture['number'] ?? ''}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.visibility, color: Color(0xFF7717E8)),
                title: const Text('Aperçu PDF'),
                subtitle: const Text('Ouvrir dans le navigateur'),
                onTap: () {
                  Navigator.pop(context);
                  _previewPDF(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text('Télécharger'),
                subtitle: const Text('Sauvegarder sur l\'appareil'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadPDFLocal(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.orange),
                title: const Text('Partager'),
                subtitle: const Text('Via email, WhatsApp, etc.'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePDF(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _previewPDF(BuildContext context) async {
    print(
      '[DEBUG][_previewPDF] Début de _previewPDF pour facture ${facture['_id']}',
    );
    try {
      // Afficher un indicateur de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Génération du PDF en cours...'),
          duration: Duration(seconds: 2),
        ),
      );

      print('[DEBUG][_previewPDF] Création du service InvoiceService');
      final invoiceService = InvoiceService();
      print(
        '[DEBUG][_previewPDF] Appel de downloadInvoicePDF avec ID: ${facture['_id']}',
      );
      final pdfUrl = await invoiceService.downloadInvoicePDF(facture['_id']);
      print('[DEBUG][_previewPDF] URL PDF récupérée: $pdfUrl');

      // Ouvrir le PDF dans le navigateur
      print('[DEBUG][_previewPDF] Tentative d\'ouverture de l\'URL: $pdfUrl');
      final uri = Uri.parse(pdfUrl);
      print('[DEBUG][_previewPDF] URI créé: $uri');

      if (await canLaunchUrl(uri)) {
        print('[DEBUG][_previewPDF] URL peut être lancée, lancement...');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('[DEBUG][_previewPDF] URL lancée avec succès');

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF ouvert avec succès !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('[DEBUG][_previewPDF] Impossible de lancer l\'URL: $pdfUrl');
        throw Exception('Impossible d\'ouvrir le lien PDF');
      }
    } catch (e) {
      print('[DEBUG][_previewPDF] ERREUR dans _previewPDF: $e');
      await _handlePDFError(context, e);
    }
  }

  Future<void> _downloadPDFLocal(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Téléchargement en cours...'),
          duration: Duration(seconds: 3),
        ),
      );

      // TODO: Implémenter le téléchargement local réel
      // Pour l'instant, ouvrir dans le navigateur
      await _previewPDF(context);
    } catch (e) {
      await _handlePDFError(context, e);
    }
  }

  Future<void> _sharePDF(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préparation du partage...'),
          duration: Duration(seconds: 2),
        ),
      );

      final invoiceService = InvoiceService();
      final pdfUrl = await invoiceService.downloadInvoicePDF(facture['_id']);

      // Partager l'URL du PDF
      await Share.share(
        'Facture ${facture['number'] ?? ''} - ${pdfUrl}',
        subject: 'Facture ${facture['number'] ?? ''}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      await _handlePDFError(context, e);
    }
  }

  Future<void> _handlePDFError(BuildContext context, dynamic error) async {
    if (kDebugMode) {
      print('Erreur PDF: $error');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${error.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () => _downloadPDF(context),
          ),
        ),
      );
    }
  }

  void _showAddProductModal(BuildContext context) async {
    String? effectiveStoreId = storeId;
    if (effectiveStoreId == null) {
      effectiveStoreId = await getSelectedStoreId(
        context: context,
        showError: true,
      );
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
          child: AddProductModal(
            facture: facture,
            onProductAdded: onReload,
            storeId: effectiveStoreId,
          ),
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

        const SizedBox(width: 8),

        // Bouton PDF
        ElevatedButton.icon(
          onPressed: () {
            print('[DEBUG][BOUTON_PDF] Bouton PDF cliqué!');
            print('[DEBUG][BOUTON_PDF] Context mounted: ${context.mounted}');
            print('[DEBUG][BOUTON_PDF] Facture ID: ${facture['_id']}');
            print('[DEBUG][BOUTON_PDF] Facture number: ${facture['number']}');
            _downloadPDF(context);
          },
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: const Text('PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: isMobile
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        if (showSaleActions) ...[
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
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF7717E8),
              size: 28,
            ),
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
      ],
    );
  }
}
