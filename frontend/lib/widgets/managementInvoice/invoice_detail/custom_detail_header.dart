import 'package:flutter/material.dart';
import '../../../models/invoice.dart';
import '../../../services/invoice_service.dart';
import './payment_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

typedef OnInvoiceUpdatedCallback = void Function();

class CustomDetailHeader extends StatelessWidget {
  final Invoice invoice;
  final OnInvoiceUpdatedCallback onInvoiceUpdated;

  const CustomDetailHeader({
    Key? key,
    required this.invoice,
    required this.onInvoiceUpdated,
  }) : super(key: key);

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
          '[DEBUG][PDF_HEADER] Utilisation du dossier Documents Windows: ${invoicesDir.path}',
        );
        return invoicesDir;
      } catch (e) {
        print('[DEBUG][PDF_HEADER] Erreur accès Documents Windows: $e');
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
        print('[DEBUG][PDF_HEADER] Erreur accès stockage externe: $e');
      }
    }

    // Fallback vers le répertoire temporaire
    return await getTemporaryDirectory();
  }

  Future<void> _downloadPDF(BuildContext context) async {
    print(
      '[DEBUG][PDF_HEADER] Début de _downloadPDF pour facture ${invoice.id}',
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
                'Options PDF - Facture ${invoice.number}',
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
      '[DEBUG][PDF_HEADER] Début de _previewPDF pour facture ${invoice.id}',
    );
    try {
      // Afficher un indicateur de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Génération du PDF en cours...'),
          duration: Duration(seconds: 2),
        ),
      );

      print('[DEBUG][PDF_HEADER] Création du service InvoiceService');
      final invoiceService = InvoiceService();
      print(
        '[DEBUG][PDF_HEADER] Appel de downloadInvoicePDF avec ID: ${invoice.id}',
      );
      final pdfUrl = await invoiceService.downloadInvoicePDF(invoice.id);
      print('[DEBUG][PDF_HEADER] URL PDF récupérée: $pdfUrl');

      // Ouvrir le PDF dans le navigateur
      print('[DEBUG][PDF_HEADER] Tentative d\'ouverture de l\'URL: $pdfUrl');
      final uri = Uri.parse(pdfUrl);
      print('[DEBUG][PDF_HEADER] URI créé: $uri');

      if (await canLaunchUrl(uri)) {
        print('[DEBUG][PDF_HEADER] URL peut être lancée, lancement...');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('[DEBUG][PDF_HEADER] URL lancée avec succès');

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
        print('[DEBUG][PDF_HEADER] Impossible de lancer l\'URL: $pdfUrl');
        throw Exception('Impossible d\'ouvrir le lien PDF');
      }
    } catch (e) {
      print('[DEBUG][PDF_HEADER] ERREUR dans _previewPDF: $e');
      await _handlePDFError(context, e);
    }
  }

  Future<void> _downloadPDFLocal(BuildContext context) async {
    print(
      '[DEBUG][PDF_HEADER] Début de _downloadPDFLocal pour facture ${invoice.id}',
    );
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Téléchargement en cours...'),
          duration: Duration(seconds: 3),
        ),
      );

      final invoiceService = InvoiceService();
      final pdfUrl = await invoiceService.downloadInvoicePDFForced(invoice.id);
      print('[DEBUG][PDF_HEADER] URL PDF pour téléchargement: $pdfUrl');

      // Ouvrir avec mode de téléchargement explicite
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        print('[DEBUG][PDF_HEADER] Lancement du téléchargement...');
        // Utiliser mode platformDefault pour forcer le téléchargement
        await launchUrl(uri, mode: LaunchMode.platformDefault);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Téléchargement lancé !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('[DEBUG][PDF_HEADER] Impossible de lancer le téléchargement');
        throw Exception('Impossible de lancer le téléchargement');
      }
    } catch (e) {
      print('[DEBUG][PDF_HEADER] ERREUR dans _downloadPDFLocal: $e');
      await _handlePDFError(context, e);
    }
  }

  Future<void> _sharePDF(BuildContext context) async {
    print('[DEBUG][PDF_HEADER] Début de _sharePDF pour facture ${invoice.id}');
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Téléchargement du PDF pour partage...'),
          duration: Duration(seconds: 3),
        ),
      );

      final invoiceService = InvoiceService();
      final pdfUrl = await invoiceService.downloadInvoicePDF(invoice.id);
      print('[DEBUG][PDF_HEADER] URL PDF récupérée pour partage: $pdfUrl');

      print('[DEBUG][PDF_HEADER] Téléchargement du fichier PDF...');

      // Télécharger le PDF
      final response = await http.get(Uri.parse(pdfUrl));

      if (response.statusCode != 200) {
        throw Exception('Erreur de téléchargement: ${response.statusCode}');
      }

      print(
        '[DEBUG][PDF_HEADER] PDF téléchargé, taille: ${response.bodyBytes.length} bytes',
      );

      // Obtenir le meilleur répertoire selon la plateforme
      final saveDir = await _getBestDirectory();
      final fileName = 'facture_${invoice.number}.pdf';
      final filePath = '${saveDir.path}/$fileName';

      print('[DEBUG][PDF_HEADER] Sauvegarde du PDF dans: $filePath');
      print('[DEBUG][PDF_HEADER] Répertoire utilisé: ${saveDir.path}');

      // Sauvegarder une référence au répertoire pour la notification
      Directory currentSaveDir = saveDir;

      // Sauvegarder le fichier
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      print('[DEBUG][PDF_HEADER] PDF sauvegardé, vérification...');

      // Vérifier que le fichier existe et n'est pas vide
      if (await file.exists() && await file.length() > 0) {
        print('[DEBUG][PDF_HEADER] Fichier valide, lancement du partage...');

        // Masquer le snackbar de téléchargement
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        // Partager le fichier PDF
        final clientName =
            '${invoice.client?.firstName ?? ''} ${invoice.client?.lastName ?? ''}'
                .trim();

        // Préparer le texte d'accompagnement
        final shareText =
            'Facture ${invoice.number}${clientName.isNotEmpty ? ' - $clientName' : ''}';

        print('[DEBUG][PDF_HEADER] Tentative de partage du fichier: $filePath');
        print(
          '[DEBUG][PDF_HEADER] Taille du fichier: ${await file.length()} bytes',
        );
        print('[DEBUG][PDF_HEADER] Fichier existe: ${await file.exists()}');

        try {
          // Méthode 1: Partage avec MIME type explicite
          final result = await Share.shareXFiles(
            [XFile(filePath, mimeType: 'application/pdf')],
            text: shareText,
            subject: 'Facture ${invoice.number}',
          );

          print('[DEBUG][PDF_HEADER] Résultat du partage: ${result.status}');

          if (result.status == ShareResultStatus.dismissed) {
            print('[DEBUG][PDF_HEADER] Partage annulé par l\'utilisateur');
          } else if (result.status == ShareResultStatus.unavailable) {
            print(
              '[DEBUG][PDF_HEADER] Partage non disponible, essai méthode alternative',
            );
            // Méthode alternative
            await Share.shareFiles(
              [filePath],
              text: shareText,
              subject: 'Facture ${invoice.number}',
              mimeTypes: ['application/pdf'],
            );

            // Sur Windows, informer l'utilisateur de l'emplacement du fichier
            if (Platform.isWindows && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'PDF sauvegardé dans Documents/InvoiceStock\nFichier: ${fileName}',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Ouvrir dossier',
                    textColor: Colors.white,
                    onPressed: () async {
                      try {
                        // Ouvrir l'explorateur Windows au bon dossier
                        await Process.run('explorer', [currentSaveDir.path]);
                      } catch (e) {
                        print(
                          '[DEBUG][PDF_HEADER] Erreur ouverture explorateur: $e',
                        );
                      }
                    },
                  ),
                ),
              );
            }
          }
        } catch (shareError) {
          print('[DEBUG][PDF_HEADER] Erreur lors du partage: $shareError');
          // Si tout échoue, partager au moins le lien
          final pdfUrl = await invoiceService.downloadInvoicePDF(invoice.id);
          await Share.share(
            'Facture ${invoice.number}\n\nTéléchargez votre facture: $pdfUrl',
            subject: 'Facture ${invoice.number}',
          );
        }

        print('[DEBUG][PDF_HEADER] Partage lancé avec succès');

        // Nettoyer le fichier temporaire après un délai
        Future.delayed(const Duration(minutes: 5), () async {
          try {
            if (await file.exists()) {
              await file.delete();
              print('[DEBUG][PDF_HEADER] Fichier temporaire supprimé');
            }
          } catch (e) {
            print('[DEBUG][PDF_HEADER] Erreur suppression fichier temp: $e');
          }
        });
      } else {
        throw Exception('Le fichier PDF sauvegardé est invalide');
      }
    } catch (e) {
      print('[DEBUG][PDF_HEADER] ERREUR dans _sharePDF: $e');
      await _handlePDFError(context, e);
    }
  }

  Future<void> _handlePDFError(BuildContext context, dynamic error) async {
    print('[DEBUG][PDF_HEADER] Erreur PDF: $error');

    String errorMessage = 'Erreur: ${error.toString()}';

    // Messages d'erreur spécifiques
    if (error.toString().contains('Permission denied')) {
      errorMessage =
          'Erreur de permission. Vérifiez les autorisations de stockage.';
    } else if (error.toString().contains('No space left')) {
      errorMessage = 'Espace de stockage insuffisant.';
    } else if (error.toString().contains('Network')) {
      errorMessage = 'Erreur de connexion. Vérifiez votre connexion internet.';
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              text: 'Détail de la Facture ',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: '#${invoice.number}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!isMobile)
            TextButton.icon(
              onPressed: () {
                print(
                  '[DEBUG][PDF_HEADER] Bouton PDF cliqué dans custom_detail_header',
                );
                print('[DEBUG][PDF_HEADER] Facture ID: ${invoice.id}');
                _downloadPDF(context);
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Télécharger'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          const SizedBox(width: 8),
          if (!isMobile && invoice.status != 'payee')
            ElevatedButton.icon(
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (context) => PaymentDialog(
                    initialAmount: invoice.total - invoice.montantPaye,
                  ),
                );
                if (result != null) {
                  try {
                    final invoiceService = InvoiceService();
                    await invoiceService.addPayment(
                      invoice.id,
                      result['amount'],
                      result['method'],
                    );
                    onInvoiceUpdated();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paiement enregistré avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erreur lors de l\'enregistrement du paiement: $e',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.payment),
              label: const Text('Payer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
