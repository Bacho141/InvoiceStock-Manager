import express from 'express';
import invoiceController from '../controllers/invoiceController.js';

const router = express.Router();

// Créer une facture
router.post('/', invoiceController.createInvoice);
// Lister les factures
router.get('/', invoiceController.getInvoices);
// Détail d'une facture
router.get('/:id', invoiceController.getInvoiceById);
// Modifier une facture
router.put('/:id', invoiceController.updateInvoice);
// Annuler une facture
router.delete('/:id', invoiceController.cancelInvoice);
// Mettre une facture en attente
router.post('/:id/wait', invoiceController.setInvoiceOnHold);

// Ajouter des lignes à une facture existante
router.patch('/:id/add-lines', invoiceController.addLinesToInvoice);

// Supprimer une ligne d'une facture existante
router.patch('/:id/remove-line', invoiceController.removeLineFromInvoice);

export default router; 