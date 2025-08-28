// widgets/invoice_common/invoice_actions_menu.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/invoice.dart';
import '../../../services/invoice_service.dart';
import '../cancel/cancel_invoice_dialog.dart';

typedef InvoiceActionCallback = void Function(String action, Invoice invoice);

class InvoiceActionsMenu extends StatelessWidget {
  final Invoice invoice;
  final InvoiceActionCallback? onActionSelected;
  final bool isCompact;

  const InvoiceActionsMenu({
    Key? key,
    required this.invoice,
    this.onActionSelected,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'pdf') {
          await _downloadPDFDirect(context);
        } else if (value == 'cancel') {
          await _handleCancelInvoice(context);
        } else {
          onActionSelected?.call(value, invoice);
        }
      },
      itemBuilder: (context) => _buildMenuItems(),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    final items = <PopupMenuEntry<String>>[];

    // Action "Voir les détails" - toujours disponible
    items.add(
      PopupMenuItem(
        value: 'details',
        child: isCompact
            ? const Text('Détails')
            : const ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Voir les détails'),
              ),
      ),
    );

    // Action "Télécharger PDF" - toujours disponible
    items.add(
      PopupMenuItem(
        value: 'pdf',
        child: isCompact
            ? const Text('PDF')
            : const ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('Télécharger PDF'),
              ),
      ),
    );

    // Action "Enregistrer un paiement" - seulement si facture non payée
    if (_canReceivePayment()) {
      items.add(
        PopupMenuItem(
          value: 'payment',
          child: isCompact
              ? const Text('Payer')
              : const ListTile(
                  leading: Icon(Icons.payment),
                  title: Text('Enregistrer un paiement'),
                ),
        ),
      );
    }

    // Action "Annuler la facture" - seulement si pas déjà annulée
    if (_canBeCancelled()) {
      items.add(
        PopupMenuItem(
          value: 'cancel',
          child: isCompact
              ? const Text('Annuler')
              : const ListTile(
                  leading: Icon(Icons.cancel_outlined),
                  title: Text('Annuler la facture'),
                ),
        ),
      );
    }

    return items;
  }

  bool _canReceivePayment() {
    return invoice.status == 'reste_a_payer' || invoice.status == 'en_attente';
  }

  bool _canBeCancelled() {
    return invoice.status != 'annulee';
  }

  /// Télécharge directement le PDF sans menu d'options
  Future<void> _downloadPDFDirect(BuildContext context) async {
    debugPrint(
      '[InvoiceActionsMenu] Téléchargement direct PDF facture ${invoice.id}',
    );

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text('Téléchargement PDF #${invoice.number}...'),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ),
      );

      final invoiceService = InvoiceService();
      final pdfUrl = await invoiceService.downloadInvoicePDFForced(invoice.id);
      debugPrint('[InvoiceActionsMenu] URL PDF obtenue: $pdfUrl');

      // Lancer le téléchargement avec mode platformDefault pour forcer la sauvegarde
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        debugPrint('[InvoiceActionsMenu] Lancement du téléchargement...');

        await launchUrl(uri, mode: LaunchMode.platformDefault);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 16),
                  Text('PDF #${invoice.number} téléchargé !'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Impossible de lancer le téléchargement');
      }
    } catch (e) {
      debugPrint('[InvoiceActionsMenu] Erreur téléchargement: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        String errorMessage = 'Erreur lors du téléchargement du PDF';

        // Messages d'erreur spécifiques
        if (e.toString().contains('Permission denied')) {
          errorMessage = 'Erreur de permission. Vérifiez les autorisations.';
        } else if (e.toString().contains('Network')) {
          errorMessage =
              'Erreur de connexion. Vérifiez votre connexion internet.';
        } else if (e.toString().contains('Token')) {
          errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () => _downloadPDFDirect(context),
            ),
          ),
        );
      }
    }
  }

  /// Gère l'annulation d'une facture avec confirmation utilisateur
  Future<void> _handleCancelInvoice(BuildContext context) async {
    debugPrint('[InvoiceActionsMenu] Début annulation facture ${invoice.id}');

    try {
      // Afficher le dialog de confirmation
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CancelInvoiceDialog(invoice: invoice),
      );

      if (result == null || result['confirmed'] != true) {
        debugPrint(
          '[InvoiceActionsMenu] Annulation annulée par l\'utilisateur',
        );
        return;
      }

      final reason = result['reason'] as String;
      debugPrint('[InvoiceActionsMenu] Confirmation reçue, motif: $reason');

      // Afficher un indicateur de chargement
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Annulation de la facture ${invoice.number}...'),
              ],
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Effectuer l'annulation
      final invoiceService = InvoiceService();
      final cancelResult = await invoiceService.cancelInvoice(
        invoice.id,
        reason,
      );

      debugPrint(
        '[InvoiceActionsMenu] Facture annulée avec succès: ${cancelResult['success']}',
      );

      // Afficher le succès
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Facture ${invoice.number} annulée !'),
                      const Text(
                        'Les produits ont été automatiquement remis en stock',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Notifier le callback parent si disponible
      onActionSelected?.call('refresh', invoice);
    } catch (e) {
      debugPrint('[InvoiceActionsMenu] Erreur annulation facture: $e');

      // Afficher l'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Erreur lors de l\'annulation: ${e.toString()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () => _handleCancelInvoice(context),
            ),
          ),
        );
      }
    }
  }
}
