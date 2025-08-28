import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/invoice.dart';
import '../invoice_detail/invoice_detail_widget.dart';
import '../../../layout/invoice_a5_layout.dart';
import '../payment/payment_history_safe.dart';
import '../invoice_common/invoice_status_badge.dart';
import '../../../services/invoice_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class MobileDetailLayout extends StatefulWidget {
  final Invoice invoice;
  final VoidCallback onInvoiceUpdated;

  const MobileDetailLayout({
    Key? key,
    required this.invoice,
    required this.onInvoiceUpdated,
  }) : super(key: key);

  @override
  _MobileDetailLayoutState createState() => _MobileDetailLayoutState();
}

class _MobileDetailLayoutState extends State<MobileDetailLayout>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Facture #${widget.invoice.number}')),
            IconButton(
              onPressed: () => _downloadPDF(context),
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Télécharger PDF',
              color: const Color(0xFF7717E8),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Détails'),
            Tab(icon: Icon(Icons.visibility_outlined), text: 'Aperçu'),
            Tab(icon: Icon(Icons.payment), text: 'Paiements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(context),
          SingleChildScrollView(
            child: InvoiceA5Layout(
              facture: widget.invoice.toJson(),
              showAppBar: false,
              isCentered: false,
              showSaleActions: false,
            ),
          ),
          PaymentHistoryWidget(
            invoice: widget.invoice,
            onPaymentUpdated: () {
              widget.onInvoiceUpdated();
            },
          ),
        ],
      ),
      floatingActionButton: widget.invoice.montantPaye < widget.invoice.total
          ? FloatingActionButton.extended(
              onPressed: () {
                // Le bouton d'ajout de paiement est maintenant dans PaymentHistoryWidget
                _tabController.animateTo(2); // Aller à l'onglet Paiements
              },
              label: const Text('Ajouter Paiement'),
              icon: const Icon(Icons.payment),
              backgroundColor: const Color(0xFF7717E8),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  /// Obtient le meilleur répertoire pour sauvegarder le fichier selon la plateforme
  Future<Directory> _getBestDirectory() async {
    if (kIsWeb) {
      return await getTemporaryDirectory();
    }

    if (Platform.isWindows) {
      // Sur Windows, utiliser le dossier Documents qui est plus accessible
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        final invoicesDir = Directory('${documentsDir.path}/InvoiceStock');
        if (!await invoicesDir.exists()) {
          await invoicesDir.create(recursive: true);
        }
        print(
          '[DEBUG][PDF_MOBILE] Utilisation du dossier Documents Windows: ${invoicesDir.path}',
        );
        return invoicesDir;
      } catch (e) {
        print('[DEBUG][PDF_MOBILE] Erreur accès Documents Windows: $e');
      }
    }

    if (Platform.isAndroid) {
      // Sur Android, essayer d'abord le répertoire externe
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Créer un dossier dans le répertoire externe
          final invoicesDir = Directory('${externalDir.path}/InvoiceStock');
          if (!await invoicesDir.exists()) {
            await invoicesDir.create(recursive: true);
          }
          return invoicesDir;
        }
      } catch (e) {
        print('[DEBUG][PDF_MOBILE] Erreur accès stockage externe: $e');
      }
    }

    // Fallback vers le répertoire temporaire
    return await getTemporaryDirectory();
  }

  Future<void> _downloadPDF(BuildContext context) async {
    print(
      '[DEBUG][PDF_MOBILE] Début de _downloadPDF pour facture ${widget.invoice.id}',
    );

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
                'Options PDF - Facture ${widget.invoice.number}',
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
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Partager'),
                subtitle: const Text('Partager le fichier PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePDF(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _previewPDF(BuildContext context) async {
    print(
      '[DEBUG][PDF_MOBILE] Début de _previewPDF pour facture ${widget.invoice.id}',
    );

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final invoiceService = InvoiceService();
      final pdfUrl = await invoiceService.downloadInvoicePDF(widget.invoice.id);

      print('[DEBUG][PDF_MOBILE] URL PDF reçue: $pdfUrl');

      // Fermer l'indicateur de chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Ouvrir dans le navigateur
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('[DEBUG][PDF_MOBILE] PDF ouvert dans le navigateur');
      } else {
        throw Exception('Impossible d\'ouvrir l\'URL: $pdfUrl');
      }
    } catch (e) {
      print('[DEBUG][PDF_MOBILE] Erreur preview PDF: $e');

      // Fermer l'indicateur de chargement s'il est encore ouvert
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Afficher un message d'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'aperçu du PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPDFLocal(BuildContext context) async {
    print(
      '[DEBUG][PDF_MOBILE] Début de _downloadPDFLocal pour facture ${widget.invoice.id}',
    );

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final invoiceService = InvoiceService();
      final pdfUrl = await invoiceService.downloadInvoicePDF(widget.invoice.id);

      print('[DEBUG][PDF_MOBILE] URL PDF reçue: $pdfUrl');

      // Télécharger le fichier PDF
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw Exception(
          'Erreur serveur: ${response.statusCode} - ${response.body}',
        );
      }

      print(
        '[DEBUG][PDF_MOBILE] Fichier PDF téléchargé (${response.bodyBytes.length} bytes)',
      );

      // Obtenir le répertoire de destination
      final directory = await _getBestDirectory();
      final fileName =
          'Facture_${widget.invoice.number}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      // Écrire le fichier
      await file.writeAsBytes(response.bodyBytes);
      print('[DEBUG][PDF_MOBILE] Fichier sauvegardé: ${file.path}');

      // Fermer l'indicateur de chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Afficher un message de succès avec le chemin
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF téléchargé avec succès!\nEmplacement: ${file.path}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: Platform.isWindows
                ? SnackBarAction(
                    label: 'Ouvrir dossier',
                    onPressed: () async {
                      try {
                        await Process.run('explorer', [directory.path]);
                      } catch (e) {
                        print(
                          '[DEBUG][PDF_MOBILE] Erreur ouverture dossier: $e',
                        );
                      }
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      print('[DEBUG][PDF_MOBILE] Erreur téléchargement local PDF: $e');

      // Fermer l'indicateur de chargement s'il est encore ouvert
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Afficher un message d'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePDF(BuildContext context) async {
    print(
      '[DEBUG][PDF_MOBILE] Début de _sharePDF pour facture ${widget.invoice.id}',
    );

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final invoiceService = InvoiceService();
      final pdfUrl = await invoiceService.downloadInvoicePDF(widget.invoice.id);

      print('[DEBUG][PDF_MOBILE] URL PDF reçue: $pdfUrl');

      // Télécharger le fichier PDF en mémoire
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw Exception(
          'Erreur serveur: ${response.statusCode} - ${response.body}',
        );
      }

      print(
        '[DEBUG][PDF_MOBILE] Fichier PDF téléchargé pour partage (${response.bodyBytes.length} bytes)',
      );

      // Créer un fichier temporaire pour le partage
      final tempDir = await getTemporaryDirectory();
      final fileName = 'Facture_${widget.invoice.number}.pdf';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(response.bodyBytes);

      print('[DEBUG][PDF_MOBILE] Fichier temporaire créé: ${tempFile.path}');

      // Fermer l'indicateur de chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Partager le fichier PDF avec MIME type explicite
      final xFile = XFile(
        tempFile.path,
        name: fileName,
        mimeType: 'application/pdf',
      );

      await Share.shareXFiles(
        [xFile],
        text: 'Facture ${widget.invoice.number} - InvoiceStock Manager',
        subject: 'Facture ${widget.invoice.number}',
      );

      print('[DEBUG][PDF_MOBILE] Partage initié avec succès');
    } catch (e) {
      print('[DEBUG][PDF_MOBILE] Erreur partage PDF: $e');

      // Fermer l'indicateur de chargement s'il est encore ouvert
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Afficher un message d'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Fallback vers le partage de lien si le partage de fichier échoue
      try {
        final invoiceService = InvoiceService();
        final pdfUrl = await invoiceService.downloadInvoicePDF(
          widget.invoice.id,
        );
        await Share.share(
          'Facture ${widget.invoice.number}\nLien: $pdfUrl',
          subject: 'Facture ${widget.invoice.number}',
        );
        print('[DEBUG][PDF_MOBILE] Fallback partage lien réussi');
      } catch (fallbackError) {
        print('[DEBUG][PDF_MOBILE] Erreur fallback: $fallbackError');
      }
    }
  }

  Widget _buildDetailsTab(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd/MM/yyyy').format(widget.invoice.date);
    final remainingAmount = widget.invoice.total - widget.invoice.montantPaye;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client: ${widget.invoice.client.fullName.isNotEmpty ? widget.invoice.client.fullName : 'N/A'}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Date: $formattedDate', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Statut: '),
              InvoiceStatusBadge(status: widget.invoice.status),
            ],
          ),
          const Divider(height: 32),
          _buildMobileInfoRow(
            'Total TTC:',
            '${widget.invoice.total.toStringAsFixed(2)} F',
            theme,
          ),
          _buildMobileInfoRow(
            'Remise:',
            '- ${widget.invoice.discountTotal.toStringAsFixed(2)} F',
            theme,
            color: Colors.green[700],
          ),
          _buildMobileInfoRow(
            'Montant Payé:',
            '${widget.invoice.montantPaye.toStringAsFixed(2)} F',
            theme,
          ),
          _buildMobileInfoRow(
            'Reste à Payer:',
            '${remainingAmount.toStringAsFixed(2)} F',
            theme,
            isBold: true,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
