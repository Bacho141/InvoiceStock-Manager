// widgets/invoice_filters/desktop_filter_bar.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/invoice_provider.dart';
import 'search_text_field.dart';
import 'status_dropdown_filter.dart';
import 'period_filter_button.dart';

class DesktopFilterBar extends StatelessWidget {
  final InvoiceProvider provider;

  const DesktopFilterBar({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Partie gauche - Filtres
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchTextField(
                hintText: '🔍 Rech. (N°, client)...',
                width: 280,
                onSubmitted: (value) => provider.setSearchTerm(value),
              ),
              const SizedBox(width: 15),
              StatusDropdownFilter(
                value: provider.statusFilter,
                width: 180,
                onChanged: (value) => provider.setStatusFilter(value),
              ),
              const SizedBox(width: 15),
              PeriodFilterButton(provider: provider, width: 200),
              const SizedBox(width: 12),
              _buildBulkActionsMenu(context),
            ],
          ),
          // Partie droite - Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/new-sale'),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text(' Nouvelle Vente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'download_zip') {
          await _handleDownloadZIP(context);
        }
      },
      enabled: provider.selectedInvoices.isNotEmpty,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'download_zip',
          child: Row(
            children: [
              const Icon(Icons.archive, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Télécharger ZIP (${provider.selectedInvoices.length})'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                color: provider.selectedInvoices.isNotEmpty
                    ? Colors.black
                    : Colors.grey,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: provider.selectedInvoices.isNotEmpty
                  ? Colors.black
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  /// Gère le téléchargement ZIP des factures sélectionnées
  Future<void> _handleDownloadZIP(BuildContext context) async {
    debugPrint(
      '[DesktopFilterBar] Début téléchargement ZIP de ${provider.selectedInvoices.length} factures',
    );

    // Afficher un indicateur de chargement
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Génération de l\'archive ZIP en cours... (${provider.selectedInvoices.length} factures)',
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      final downloadUrl = await provider.downloadSelectedInvoicesZIP();
      debugPrint('[DesktopFilterBar] URL ZIP générée: $downloadUrl');

      // Lancer le téléchargement
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);

        // Afficher un message de succès
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // Vérifier si l'archive contient un fichier de résumé pour détecter les erreurs
          final selectedCount = provider.selectedInvoices.length;
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
                        Text(
                          'Archive ZIP téléchargée ! ($selectedCount factures demandées)',
                        ),
                        const Text(
                          'Vérifiez le fichier RESUME_GENERATION.txt dans l\'archive pour les détails',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        // Vider la sélection après téléchargement réussi
        provider.selectAll(false);
      } else {
        throw Exception('Impossible de lancer le téléchargement');
      }
    } catch (e) {
      debugPrint('[DesktopFilterBar] Erreur téléchargement ZIP: $e');

      // Afficher un message d'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Erreur lors du téléchargement: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () => _handleDownloadZIP(context),
            ),
          ),
        );
      }
    }
  }
}
