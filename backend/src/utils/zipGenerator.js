import archiver from 'archiver';
import { generateInvoiceHTML } from './pdfGenerator.js';
import puppeteer from 'puppeteer';

/**
 * Génère une archive ZIP contenant les PDFs des factures sélectionnées
 * @param {Array} invoices - Tableau des factures à inclure
 * @param {Object} res - Objet response Express
 * @returns {Promise<void>}
 */
export async function generateInvoicesZIP(invoices, res) {
  console.log(`[ZIP][GENERATOR] Génération ZIP pour ${invoices.length} factures`);
  
  if (!invoices || invoices.length === 0) {
    throw new Error('Aucune facture fournie pour la génération ZIP');
  }

  let browser = null;
  let successCount = 0;
  let errorCount = 0;
  const errors = [];

  try {
    // Créer l'archive ZIP
    const archive = archiver('zip', {
      zlib: { level: 9 } // Compression maximale
    });

    // Configurer les en-têtes de réponse
    const timestamp = new Date().toISOString().split('T')[0];
    const filename = `factures_${timestamp}_${invoices.length}docs.zip`;
    
    res.setHeader('Content-Type', 'application/zip');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.setHeader('Cache-Control', 'no-cache');

    // Connecter l'archive à la réponse
    archive.pipe(res);

    // Lancer Puppeteer une seule fois pour toutes les factures
    console.log('[ZIP][GENERATOR] Lancement de Puppeteer...');
    browser = await puppeteer.launch({
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-web-security',
        '--disable-features=VizDisplayCompositor',
        '--disable-background-timer-throttling',
        '--disable-backgrounding-occluded-windows',
        '--disable-renderer-backgrounding'
      ]
    });

    // Générer chaque PDF et l'ajouter à l'archive
    let consecutiveErrors = 0;
    const maxConsecutiveErrors = 2; // Redémarrer Puppeteer après 2 erreurs consécutives
    
    for (let i = 0; i < invoices.length; i++) {
      const invoice = invoices[i];
      const invoiceNumber = i + 1;
      
      // Redémarrer Puppeteer si trop d'erreurs consécutives
      if (consecutiveErrors >= maxConsecutiveErrors) {
        console.log('[ZIP][GENERATOR] 🔄 Redémarrage de Puppeteer après erreurs multiples...');
        await browser.close();
        browser = await puppeteer.launch({
          headless: true,
          args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-web-security',
            '--disable-features=VizDisplayCompositor',
            '--disable-background-timer-throttling',
            '--disable-backgrounding-occluded-windows',
            '--disable-renderer-backgrounding'
          ]
        });
        consecutiveErrors = 0;
      }
      
      try {
        console.log(`[ZIP][GENERATOR] Génération PDF ${invoiceNumber}/${invoices.length} pour facture ${invoice.number}`);
        
        // Créer une nouvelle page pour chaque facture (plus stable)
        const page = await browser.newPage();
        
        try {
          // Générer le HTML de la facture
          console.log(`[ZIP][GENERATOR] Génération HTML pour facture ${invoice.number}`);
          const htmlContent = generateInvoiceHTML(invoice);
          
          // Vérifier que le HTML n'est pas vide
          if (!htmlContent || htmlContent.length < 100) {
            console.error(`[ZIP][GENERATOR] HTML invalide pour ${invoice.number}:`, {
              length: htmlContent ? htmlContent.length : 0,
              invoice: {
                id: invoice._id || invoice.id,
                number: invoice.number,
                client: invoice.client ? 'présent' : 'absent',
                store: invoice.store ? 'présent' : 'absent',
                lines: invoice.lines ? invoice.lines.length : 0
              }
            });
            throw new Error(`Contenu HTML invalide ou vide pour facture ${invoice.number}`);
          }
          
          // Configuration simplifiée de la page pour éviter les timeouts
          console.log(`[ZIP][GENERATOR] Configuration de la page pour ${invoice.number}`);
          
          // Méthode simplifiée : définir directement le contenu
          await page.setContent(htmlContent, { 
            waitUntil: 'load',
            timeout: 30000
          });
          
          console.log(`[ZIP][GENERATOR] Contenu défini, attente de stabilisation...`);
          
          // Attendre que la page soit stable
          await new Promise(resolve => setTimeout(resolve, 2000));
          
          console.log(`[ZIP][GENERATOR] Génération du PDF pour ${invoice.number}...`);
          
          // Générer le PDF avec des options simplifiées
          const pdfBuffer = await page.pdf({
            format: 'A4',
            printBackground: true,
            margin: {
              top: '20mm',
              right: '20mm',
              bottom: '20mm',
              left: '20mm'
            }
          });
          
          console.log(`[ZIP][GENERATOR] PDF généré pour ${invoice.number}, taille: ${pdfBuffer ? pdfBuffer.length : 0} bytes`);

          // Vérifier que le PDF est valide
          if (!pdfBuffer || pdfBuffer.length === 0) {
            throw new Error(`PDF vide généré pour facture ${invoice.number}`);
          }

          // Convertir en Buffer si nécessaire
          const finalBuffer = Buffer.isBuffer(pdfBuffer) ? pdfBuffer : Buffer.from(pdfBuffer);
          
          // Vérifier l'en-tête PDF
          const pdfHeader = finalBuffer.slice(0, 4).toString();
          if (!pdfHeader.startsWith('%PDF')) {
            throw new Error(`PDF invalide pour facture ${invoice.number}`);
          }

          // Ajouter le PDF à l'archive
          const pdfFilename = `facture_${invoice.number}.pdf`;
          archive.append(finalBuffer, { name: pdfFilename });
          
          successCount++;
          consecutiveErrors = 0; // Reset le compteur d'erreurs
          console.log(`[ZIP][GENERATOR] ✅ PDF ${invoiceNumber}/${invoices.length} ajouté: ${pdfFilename} (${finalBuffer.length} bytes)`);
          
        } finally {
          // Toujours fermer la page, même en cas d'erreur
          try {
            await page.close();
          } catch (closeError) {
            console.warn(`[ZIP][GENERATOR] Erreur fermeture page: ${closeError.message}`);
          }
        }
      } catch (pdfError) {
        errorCount++;
        consecutiveErrors++;
        const errorMsg = `Erreur génération PDF pour facture ${invoice.number}: ${pdfError.message}`;
        console.error(`[ZIP][GENERATOR] ❌ ${errorMsg}`);
        errors.push(errorMsg);
        
        // Optionnel: Ajouter un fichier d'erreur dans l'archive pour traçabilité
        const errorContent = `Erreur lors de la génération de la facture ${invoice.number}\n\nDétails de l'erreur:\n${pdfError.message}\n\nHeure: ${new Date().toISOString()}`;
        archive.append(Buffer.from(errorContent, 'utf8'), { name: `ERREUR_facture_${invoice.number}.txt` });
      }
    }

    // Ajouter un fichier de résumé dans l'archive
    const summaryContent = `RÉSUMÉ DE GÉNÉRATION\n` +
      `========================\n\n` +
      `Total factures demandées: ${invoices.length}\n` +
      `PDFs générés avec succès: ${successCount}\n` +
      `Erreurs: ${errorCount}\n\n` +
      `Date de génération: ${new Date().toISOString()}\n\n` +
      (errors.length > 0 ? `ERREURS DÉTAILLÉES:\n${errors.join('\n')}` : 'Aucune erreur');
    
    archive.append(Buffer.from(summaryContent, 'utf8'), { name: 'RESUME_GENERATION.txt' });

    // Fermer l'archive
    await archive.finalize();
    
    console.log(`[ZIP][GENERATOR] ✅ Archive ZIP générée avec succès: ${filename}`);
    console.log(`[ZIP][GENERATOR] 📊 Résultats: ${successCount} réussis, ${errorCount} erreurs`);
    
    if (errorCount > 0) {
      console.warn(`[ZIP][GENERATOR] ⚠️ Attention: ${errorCount} factures n'ont pas pu être générées`);
    }

  } catch (error) {
    console.error('[ZIP][GENERATOR] Erreur critique lors de la génération ZIP:', error.message);
    throw error;
  } finally {
    if (browser) {
      console.log('[ZIP][GENERATOR] Fermeture de Puppeteer...');
      await browser.close();
    }
  }
}

/**
 * Valide les IDs de factures et récupère les données complètes
 * @param {Array} invoiceIds - Tableau des IDs de factures
 * @param {Object} Invoice - Modèle Invoice de Mongoose
 * @returns {Promise<Array>} Tableau des factures avec données complètes
 */
export async function validateAndFetchInvoices(invoiceIds, Invoice) {
  console.log(`[ZIP][VALIDATOR] Validation de ${invoiceIds.length} IDs de factures`);
  
  if (!Array.isArray(invoiceIds) || invoiceIds.length === 0) {
    throw new Error('Liste d\'IDs de factures invalide');
  }

  if (invoiceIds.length > 50) {
    throw new Error('Trop de factures sélectionnées (maximum 50)');
  }

  // Récupérer les factures avec leurs relations
  const invoices = await Invoice.find({
    _id: { $in: invoiceIds }
  })
  .populate('client')
  .populate('store') 
  .populate('user')
  .lean(); // Utiliser lean() pour de meilleures performances

  if (invoices.length === 0) {
    throw new Error('Aucune facture trouvée pour les IDs fournis');
  }

  if (invoices.length !== invoiceIds.length) {
    console.warn(`[ZIP][VALIDATOR] ${invoiceIds.length - invoices.length} factures non trouvées`);
  }

  console.log(`[ZIP][VALIDATOR] ${invoices.length} factures validées`);
  return invoices;
}