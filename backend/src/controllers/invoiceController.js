import Invoice from '../models/Invoice.js';
import Client from '../models/Client.js';
import Store from '../models/Store.js';
import User from '../models/User.js';
import Stock from '../models/Stock.js';
import Product from '../models/Product.js';

function padNumber(num, size) {
  let s = num + '';
  while (s.length < size) s = '0' + s;
  return s;
}

async function generateInvoiceNumber() {
  const year = new Date().getFullYear();
  const regex = new RegExp(`^INV-${year}-\\d{4}$`);
  const lastInvoice = await Invoice.find({ number: { $regex: regex } })
    .sort({ number: -1 })
    .limit(1);
  let nextNumber = 1;
  if (lastInvoice.length > 0) {
    const lastNum = parseInt(lastInvoice[0].number.split('-')[2], 10);
    nextNumber = lastNum + 1;
  }
  return `INV-${year}-${padNumber(nextNumber, 4)}`;
}

const invoiceController = {
  // [INVOICE][CREATE] Créer une nouvelle facture avec logique métier avancée
  async createInvoice(req, res) {
    console.log('[INVOICE][CREATE] Tentative de création de facture');
    try {
      const invoiceData = req.body;
      // Vérification client obligatoire
      if (!invoiceData.client) {
        return res.status(400).json({ message: 'Un client est obligatoire pour chaque facture.' });
      }
      // Générer le numéro de facture global
      invoiceData.number = await generateInvoiceNumber();
      // Décrémentation du stock à la validation
      for (const line of invoiceData.lines) {
        const stock = await Stock.findOne({ productId: line.product, storeId: invoiceData.store });
        if (!stock) {
          console.warn(`[INVOICE][CREATE] Stock introuvable pour produit ${line.product} dans magasin ${invoiceData.store}`);
          continue; // Ou créer le stock si besoin
        }
        stock.quantity -= line.quantity;
        if (stock.quantity < 0) {
          console.warn(`[INVOICE][CREATE] Stock négatif autorisé pour produit ${line.product} (stock: ${stock.quantity})`);
        }
        stock.lastUpdated = new Date();
        await stock.save();
      }
      // Historique de création
      invoiceData.history = [
        {
          action: 'created',
          user: invoiceData.user, // L'ID de l'utilisateur créateur
          date: new Date(),
          reason: 'Création de la facture',
        },
      ];
      const invoice = new Invoice(invoiceData);
      await invoice.save();
      console.log('[INVOICE][CREATE] Facture créée:', invoice.number);
      // Populate avant de renvoyer
      const populatedInvoice = await Invoice.findById(invoice._id)
        .populate('client')
        .populate('store')
        .populate('user');
      res.status(201).json({ success: true, data: populatedInvoice });
    } catch (error) {
      console.error('[INVOICE][CREATE] Erreur:', error.message);
      res.status(500).json({ message: 'Erreur lors de la création de la facture.' });
    }
  },

  // [INVOICE][GET] Lister les factures
  async getInvoices(req, res) {
    console.log('[INVOICE][GET] Récupération de la liste des factures');
    try {
      const invoices = await Invoice.find().populate('client store user');
      res.json({ success: true, data: invoices });
    } catch (error) {
      console.error('[INVOICE][GET] Erreur:', error.message);
      res.status(500).json({ message: 'Erreur lors de la récupération des factures.' });
    }
  },

  // [INVOICE][GET] Détail d'une facture
  async getInvoiceById(req, res) {
    console.log('[INVOICE][GET] Récupération de la facture', req.params.id);
    try {
      const invoice = await Invoice.findById(req.params.id).populate('client store user');
      if (!invoice) {
        return res.status(404).json({ message: 'Facture non trouvée.' });
      }
      res.json({ success: true, data: invoice });
    } catch (error) {
      console.error('[INVOICE][GET] Erreur:', error.message);
      res.status(500).json({ message: 'Erreur lors de la récupération de la facture.' });
    }
  },

  // [INVOICE][PUT] Modifier une facture (optionnel)
  async updateInvoice(req, res) {
    console.log('[INVOICE][PUT] Modification de la facture', req.params.id);
    try {
      const update = req.body;
      // Validation métier
      if (update.lines) {
        for (const line of update.lines) {
          if (!line.quantity || line.quantity <= 0) {
            return res.status(400).json({ message: `Quantité invalide pour le produit ${line.productName || line.product}` });
          }
        }
      }
      // Recalcul des totaux si lines fourni
      if (update.lines) {
        update.total = update.lines.reduce((sum, l) => sum + (l.totalLine || 0), 0);
        update.discountTotal = update.lines.reduce((sum, l) => sum + (l.discount || 0), 0);
      }
      // Validation montant payé
      if (update.montantPaye && update.total && update.montantPaye > update.total) {
        return res.status(400).json({ message: 'Le montant payé ne peut pas dépasser le total.' });
      }
      // Ajout historique
      const invoiceBefore = await Invoice.findById(req.params.id);
      if (!invoiceBefore) {
        return res.status(404).json({ message: 'Facture non trouvée.' });
      }
      const userId = (req.user && req.user._id) ? req.user._id : (invoiceBefore.user ? invoiceBefore.user : undefined);
      if (!userId) {
        console.error('[INVOICE][PUT] Aucun utilisateur trouvé pour l\'historique.');
        return res.status(400).json({ message: 'Impossible de déterminer l\'utilisateur pour l\'historique.' });
      }
      const historyEntry = {
        action: 'update',
        user: userId,
        date: new Date(),
        reason: 'Modification du reçu via POS',
      };
      if (!update.history) update.history = invoiceBefore.history || [];
      update.history.push(historyEntry);
      // Mise à jour
      const invoice = await Invoice.findByIdAndUpdate(req.params.id, update, { new: true });
      if (!invoice) {
        return res.status(404).json({ message: 'Facture non trouvée.' });
      }
      res.json({ success: true, data: invoice });
    } catch (error) {
      console.error('[INVOICE][PUT] Erreur:', error.message);
      res.status(500).json({ message: 'Erreur lors de la modification de la facture.' });
    }
  },

  // [INVOICE][DELETE] Annuler une facture avec restockage et historique
  async cancelInvoice(req, res) {
    console.log('[INVOICE][DELETE] Annulation de la facture', req.params.id);
    try {
      const { reason, userId } = req.body;
      const invoice = await Invoice.findById(req.params.id);
      if (!invoice) {
        return res.status(404).json({ message: 'Facture non trouvée.' });
      }
      if (invoice.status === 'annulee') {
        return res.status(400).json({ message: 'Facture déjà annulée.' });
      }
      // TODO: Vérifier les permissions de l'utilisateur (userId)
      // Restocker chaque produit de la facture
      for (const line of invoice.lines) {
        const stock = await Stock.findOne({ productId: line.product, storeId: invoice.store });
        if (!stock) {
          console.warn(`[INVOICE][CANCEL] Stock introuvable pour produit ${line.product} dans magasin ${invoice.store}`);
          continue;
        }
        stock.quantity += line.quantity;
        stock.lastUpdated = new Date();
        await stock.save();
      }
      invoice.status = 'annulee';
      invoice.cancelledBy = userId;
      invoice.cancelReason = reason;
      invoice.cancelledAt = new Date();
      invoice.history.push({ action: 'cancelled', user: userId, date: new Date(), reason });
      await invoice.save();
      console.log('[INVOICE][DELETE] Facture annulée et stock rétabli');
      res.json({ success: true, data: invoice });
    } catch (error) {
      console.error('[INVOICE][DELETE] Erreur:', error.message);
      res.status(500).json({ message: "Erreur lors de l'annulation de la facture." });
    }
  },

  // [INVOICE][WAIT] Mettre une facture en attente
  async setInvoiceOnHold(req, res) {
    console.log('[INVOICE][WAIT] Mise en attente de la facture', req.params.id);
    try {
      const { userId } = req.body;
      const invoice = await Invoice.findById(req.params.id);
      if (!invoice) {
        return res.status(404).json({ message: 'Facture non trouvée.' });
      }
      invoice.status = 'en_attente';
      invoice.history.push({ action: 'on_hold', user: userId, date: new Date() });
      await invoice.save();
      res.json({ success: true, data: invoice });
    } catch (error) {
      console.error('[INVOICE][WAIT] Erreur:', error.message);
      res.status(500).json({ message: 'Erreur lors de la mise en attente de la facture.' });
    }
  },

  // [INVOICE][PATCH] Ajouter des lignes à une facture existante
  async addLinesToInvoice(req, res) {
    console.log('[INVOICE][ADD-LINES] Ajout de lignes à la facture', req.params.id);
    try {
      const { lines } = req.body;
      console.log('[INVOICE][ADD-LINES] Payload lines reçu:', lines);
      if (!Array.isArray(lines) || lines.length === 0) {
        return res.status(400).json({ message: 'Aucune ligne à ajouter.' });
      }
      const invoice = await Invoice.findById(req.params.id);
      if (!invoice) {
        return res.status(404).json({ message: 'Facture non trouvée.' });
      }
      let totalAdded = 0;
      let discountAdded = 0;
      for (const line of lines) {
        console.log('[INVOICE][ADD-LINES] Traitement de la ligne:', line);
        // On suppose que line.product est l'ID du produit et line.quantity la quantité
        const product = await Product.findById(line.product);
        if (!product) {
          console.warn(`[INVOICE][ADD-LINES] Produit non trouvé: ${line.product}`);
          continue;
        }
        // Calcul des champs de la ligne
        const productName = product.name;
        const unitPrice = product.sellingPrice;
        const quantity = Number(line.quantity) || 0;
        const discount = 0; // À adapter si tu veux gérer la remise par ligne
        const totalLine = unitPrice * quantity - discount;
        // Décrémenter le stock
        const stock = await Stock.findOne({ productId: product._id, storeId: invoice.store });
        if (!stock) {
          console.warn(`[INVOICE][ADD-LINES] Stock introuvable pour produit ${product._id} dans magasin ${invoice.store}`);
        } else {
          stock.quantity -= quantity;
          stock.lastUpdated = new Date();
          await stock.save();
        }
        // Ajouter la ligne à la facture
        invoice.lines.push({
          product: product._id,
          productName,
          quantity,
          unitPrice,
          discount,
          totalLine,
        });
        totalAdded += totalLine;
        discountAdded += discount;
      }
      // Recalculer les totaux
      invoice.total = (invoice.lines || []).reduce((sum, l) => sum + (l.totalLine || 0), 0);
      invoice.discountTotal = (invoice.lines || []).reduce((sum, l) => sum + (l.discount || 0), 0);
      // TODO: recalculer totalInWords si besoin (ici on laisse inchangé)
      // Historique
      const userId = (req.user && req.user._id) ? req.user._id : (invoice.user ? invoice.user : undefined);
      if (!userId) {
        console.error('[INVOICE][ADD-LINES] Aucun utilisateur trouvé pour l\'historique.');
        return res.status(400).json({ message: 'Impossible de déterminer l\'utilisateur pour l\'historique.' });
      }
      invoice.history.push({
        action: 'add_lines',
        user: userId,
        date: new Date(),
        reason: `Ajout de ${lines.length} ligne(s) via POS`,
      });
      await invoice.save();
      const populatedInvoice = await Invoice.findById(invoice._id)
        .populate('client')
        .populate('store')
        .populate('user');
      console.log('[INVOICE][ADD-LINES] Lignes ajoutées, facture mise à jour');
      res.json({ success: true, data: populatedInvoice });
    } catch (error) {
      console.error('[INVOICE][ADD-LINES] Erreur:', error);
      res.status(500).json({ message: 'Erreur lors de l\'ajout de lignes à la facture.' });
    }
  },

  // [INVOICE][PATCH] Supprimer une ligne d'une facture existante
  async removeLineFromInvoice(req, res) {
    console.log('[INVOICE][REMOVE-LINE] Suppression de ligne de la facture', req.params.id);
    try {
      const { lineId } = req.body;
      const { id: invoiceId } = req.params;

      if (!lineId) {
        return res.status(400).json({ message: 'ID de ligne manquant.' });
      }

      const invoice = await Invoice.findById(invoiceId);
      if (!invoice) {
        return res.status(404).json({ message: 'Facture non trouvée.' });
      }

      const lineIndex = invoice.lines.findIndex(line => line._id.toString() === lineId);
      if (lineIndex === -1) {
        return res.status(404).json({ message: 'Ligne non trouvée dans la facture.' });
      }

      const lineToRemove = invoice.lines[lineIndex];

      // Remettre le produit en stock
      const stock = await Stock.findOne({ productId: lineToRemove.product, storeId: invoice.store });
      if (stock) {
        stock.quantity += lineToRemove.quantity;
        stock.lastUpdated = new Date();
        await stock.save();
        console.log(`[INVOICE][REMOVE-LINE] Stock mis à jour pour le produit ${lineToRemove.product}: +${lineToRemove.quantity}`);
      } else {
        console.warn(`[INVOICE][REMOVE-LINE] Stock introuvable pour le produit ${lineToRemove.product}. Impossible de restocker.`);
      }

      // Supprimer la ligne
      invoice.lines.splice(lineIndex, 1);

      // Recalculer les totaux
      invoice.total = (invoice.lines || []).reduce((sum, l) => sum + (l.totalLine || 0), 0);
      invoice.discountTotal = (invoice.lines || []).reduce((sum, l) => sum + (l.discount || 0), 0);
      
      // Historique
      const userId = (req.user && req.user._id) ? req.user._id : (invoice.user ? invoice.user : undefined);
       if (!userId) {
        console.error('[INVOICE][REMOVE-LINE] Aucun utilisateur trouvé pour l\'historique.');
        return res.status(400).json({ message: 'Impossible de déterminer l\'utilisateur pour l\'historique.' });
      }
      invoice.history.push({
        action: 'remove_line',
        user: userId,
        date: new Date(),
        reason: `Suppression de la ligne produit ${lineToRemove.productName} (ID: ${lineId})`,
      });

      await invoice.save();

      const populatedInvoice = await Invoice.findById(invoice._id)
        .populate('client')
        .populate('store')
        .populate('user');

      console.log('[INVOICE][REMOVE-LINE] Ligne supprimée, facture mise à jour');
      res.json({ success: true, data: populatedInvoice });

    } catch (error) {
      console.error('[INVOICE][REMOVE-LINE] Erreur:', error);
      res.status(500).json({ message: 'Erreur lors de la suppression de la ligne.' });
    }
  },
};

export default invoiceController;