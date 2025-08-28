import express from 'express';
import invoiceController from '../controllers/invoiceController.js';
import { checkStoreAccess } from '../middleware/storeAccessMiddleware.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// Créer une facture
router.post('/', verifyToken, invoiceController.createInvoice);
// Lister les factures
router.get('/', invoiceController.getInvoices);
// Détail d'une facture
router.get('/:id', invoiceController.getInvoiceById);
// Modifier une facture
router.put('/:id', invoiceController.updateInvoice);
// Annuler une facture
router.delete('/:id', verifyToken, invoiceController.cancelInvoice);
// Mettre une facture en attente
router.post('/:id/wait', invoiceController.setInvoiceOnHold);

// Ajouter des lignes à une facture existante
router.patch('/:id/add-lines', invoiceController.addLinesToInvoice);

// Supprimer une ligne d'une facture existante
router.patch('/:id/remove-line', invoiceController.removeLineFromInvoice);

// Validation finale de la facture
router.post('/:id/validate/:storeId', verifyToken, checkStoreAccess, invoiceController.validateInvoice);

// Générer le PDF d'une facture avec historique de paiement
router.get('/:id/pdf', verifyToken, invoiceController.generateInvoicePDF);

// Télécharger plusieurs factures en ZIP (GET avec query params)
router.get('/download/zip', verifyToken, invoiceController.downloadInvoicesZIP);

// Route de test pour vérifier la génération PDF
router.get('/test/pdf/:id', verifyToken, invoiceController.testPDFGeneration);

// Route de test pour diagnostiquer l'annulation
router.post('/test/cancel/:id', verifyToken, invoiceController.testCancelInvoice);

export default router; 