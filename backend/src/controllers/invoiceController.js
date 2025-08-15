import Invoice from '../models/Invoice.js';
import Client from '../models/Client.js';
import Store from '../models/Store.js';
import User from '../models/User.js';
import Stock from '../models/Stock.js';
import Product from '../models/Product.js';
import StockMovement from '../models/StockMovement.js';
import AuditLog from '../models/AuditLog.js';

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
  // [INVOICE][VALIDATE] Validation finale de la facture après transaction stock
  async validateInvoice(req, res) {
    console.log('[INVOICE][VALIDATE] Validation de la facture', req.params.id);
    try {
      const invoice = await Invoice.findById(req.params.id);
      if (!invoice) {
        return res.status(404).json({ message: 'Facture non trouvée.' });
      }
      // Idempotence : si déjà validée, rien à faire
      if (invoice.status === 'validée') {
        return res.json({ success: true, data: invoice, message: 'Facture déjà validée.' });
      }
      invoice.status = 'validée';
      invoice.validatedAt = new Date();
      // Historique
      const userId = (req.user && req.user._id) ? req.user._id : (invoice.user ? invoice.user : undefined);
      if (!userId) {
        console.error('[INVOICE][VALIDATE] Aucun utilisateur trouvé pour l\'historique.');
        return res.status(400).json({ message: 'Impossible de déterminer l\'utilisateur pour l\'historique.' });
      }
      invoice.history.push({
        action: 'validated',
        user: userId,
        date: new Date(),
        reason: 'Validation finale de la facture après transaction stock',
      });
      await invoice.save();
      const populatedInvoice = await Invoice.findById(invoice._id)
        .populate('client')
        .populate('store')
        .populate('user');
      console.log('[INVOICE][VALIDATE] Facture validée:', invoice.number);
      res.json({ success: true, data: populatedInvoice });
    } catch (error) {
      console.error('[INVOICE][VALIDATE] Erreur:', error.message);
      res.status(500).json({ message: 'Erreur lors de la validation de la facture.' });
    }
  },
  // [INVOICE][CREATE] Créer une nouvelle facture avec logique transactionnelle avancée
  async createInvoice(req, res) {
    console.log('[INVOICE][CREATE] Corps de la requête reçu:', JSON.stringify(req.body, null, 2));
    console.log('[INVOICE][CREATE] Tentative de création de facture');
    let invoiceData;
    const session = await Stock.startSession();
    session.startTransaction();
    try {
      invoiceData = req.body;
      if (!invoiceData.client) {
        await session.abortTransaction();
        return res.status(400).json({ message: 'Un client est obligatoire pour chaque facture.' });
      }
      invoiceData.number = await generateInvoiceNumber();
      invoiceData.history = [
        {
          action: 'created',
          user: invoiceData.user,
          date: new Date(),
          reason: 'Création de la facture',
        },
      ];

      // Calcul du statut de la facture
      const total = invoiceData.total || 0;
      const montantPaye = invoiceData.montantPaye || 0;
      invoiceData.status = invoiceData.status || (montantPaye >= total ? 'payee' : 'reste_a_payer');
      // Décrémenter stock + enregistrer mouvement pour chaque ligne
      for (const line of invoiceData.lines) {
        const stock = await Stock.findOne({ productId: line.product, storeId: invoiceData.store }).session(session);
        if (!stock) {
          console.warn(`[INVOICE][CREATE] Stock introuvable pour produit ${line.product} dans magasin ${invoiceData.store}`);
          throw new Error(`Stock introuvable pour produit ${line.product}`);
        }
        const previousQuantity = stock.quantity;
        stock.quantity -= line.quantity;
        if (stock.quantity < 0) {
          console.warn(`[INVOICE][CREATE] Stock négatif autorisé pour produit ${line.product} (stock: ${stock.quantity})`);
        }
        stock.lastUpdated = new Date();
        await stock.save({ session });
        // Mouvement OUT
        await StockMovement.create([{
          productId: line.product,
          storeId: invoiceData.store,
          type: 'OUT',
          quantity: line.quantity,
          previousQuantity: previousQuantity,
          newQuantity: stock.quantity,
          reason: 'Décrémentation stock à la création facture',
          reference: invoiceData.number,
          referenceType: 'INVOICE',
          userId: invoiceData.user,
        }], { session });
        console.log(`[INVOICE][CREATE][STOCK] Produit ${line.product} - Stock décrémenté de ${line.quantity} (avant: ${previousQuantity}, après: ${stock.quantity})`);
      }
      const invoice = new Invoice(invoiceData);
      await invoice.save({ session });
      await session.commitTransaction();
      session.endSession();
      console.log('[INVOICE][CREATE] Facture créée:', invoice.number);
      const populatedInvoice = await Invoice.findById(invoice._id)
        .populate('client')
        .populate('store')
        .populate('user');
      res.status(201).json({ success: true, data: populatedInvoice });
    } catch (error) {
      await session.abortTransaction();
      session.endSession();
      console.error('[INVOICE][CREATE][ROLLBACK] Erreur transactionnelle:', error.message);
      // Audit log
      await AuditLog.create({
        event: 'INVOICE_ROLLBACK',
        invoiceId: (invoiceData && invoiceData._id) ? invoiceData._id : undefined,
        userId: invoiceData && invoiceData.user,
        storeId: invoiceData && invoiceData.store,
        details: { data: invoiceData },
        message: error.message,
      });
      res.status(500).json({ message: 'Erreur lors de la création de la facture.', error: error.message });
    }
  },

  // [INVOICE][GET] Lister les factures avec filtres et pagination
  async getInvoices(req, res) {
    console.log(`[INVOICE][GET] Récupération de la liste des factures avec query:`, req.query);
    try {
      const { page = 1, limit = 10, storeId, status, search, period, startDate, endDate } = req.query;

      const query = {};

      if (storeId) {
        query.store = storeId;
      }
      if (status) {
        query.status = status;
      }
      if (search) {
        const searchRegex = new RegExp(search, 'i');
        const clients = await Client.find({
          $or: [
            { firstName: searchRegex },
            { lastName: searchRegex },
          ],
        }).select('_id');
        const clientIds = clients.map(c => c._id);
        
        query.$or = [
          { number: searchRegex },
          { client: { $in: clientIds } }
        ];
      }
      
      // Gérer la période
      if (startDate && endDate) {
        query.date = { $gte: new Date(startDate), $lte: new Date(endDate) };
      } else if (startDate) {
        const start = new Date(startDate);
        start.setHours(0, 0, 0, 0);
        const end = new Date(startDate);
        end.setHours(23, 59, 59, 999);
        query.date = { $gte: start, $lte: end };
      } else if (period) {
        const now = new Date();
        let startDatePeriod;
        if (period === 'today') {
          startDatePeriod = new Date(now.setHours(0, 0, 0, 0));
        } else if (period === 'this_month') {
          startDatePeriod = new Date(now.getFullYear(), now.getMonth(), 1);
        } else if (period === 'this_year') {
          startDatePeriod = new Date(now.getFullYear(), 0, 1);
        }
        if(startDatePeriod) {
            query.date = { $gte: startDatePeriod };
        }
      }

      const total = await Invoice.countDocuments(query);
      const invoices = await Invoice.find(query)
        .populate('client store user')
        .sort({ date: -1 })
        .skip((page - 1) * limit)
        .limit(parseInt(limit));

      res.json({
        success: true,
        data: invoices,
        total,
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / limit),
      });
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
   // [INVOICE][PUT] Modifier une facture (paiements, etc.)
  async updateInvoice(req, res) {
    console.log('[INVOICE][PUT] Modification de la facture', req.params.id);
    try {
      const { payment, ...otherUpdates } = req.body;
      const { id: invoiceId } = req.params;

      const invoice = await Invoice.findById(invoiceId);
      if (!invoice) {
        return res.status(404).json({ message: 'Facture non trouvée.' });
      }

      const userId = req.user?._id || invoice.user;
      if (!userId) {
        return res.status(400).json({ message: 'Impossible de déterminer l\'utilisateur pour l\'historique.' });
      }

      // --- Logique de mise à jour générale (inspirée de l'ancienne version) ---
      if (Object.keys(otherUpdates).length > 0) {
        // Validation métier pour les lignes
        if (otherUpdates.lines) {
          for (const line of otherUpdates.lines) {
            if (!line.quantity || line.quantity <= 0) {
              return res.status(400).json({ message: `Quantité invalide pour le produit ${line.productName || line.product}` });
            }
          }
          // Recalcul des totaux si les lignes changent
          otherUpdates.total = otherUpdates.lines.reduce((sum, l) => sum + (l.totalLine || 0), 0);
          otherUpdates.discountTotal = otherUpdates.lines.reduce((sum, l) => sum + (l.discount || 0), 0);
        }
        
        // Appliquer les autres mises à jour
        Object.assign(invoice, otherUpdates);

        invoice.history.push({
          action: 'update',
          user: userId,
          date: new Date(),
          reason: 'Modification manuelle de la facture',
        });
      }

      // --- Gestion d'un nouveau paiement ---
      if (payment && payment.amount > 0) {
        const paymentAmount = Number(payment.amount);
        
        if ((invoice.montantPaye + paymentAmount) > invoice.total) {
            return res.status(400).json({ message: 'Le montant total payé ne peut pas dépasser le total de la facture.' });
        }

        invoice.paymentHistory.push({
          amount: paymentAmount,
          method: payment.method || 'espece',
          user: userId,
          date: new Date(),
        });

        invoice.montantPaye += paymentAmount;

        if (invoice.montantPaye >= invoice.total) {
          invoice.status = 'payee';
        } else {
          invoice.status = 'reste_a_payer';
        }
        
        invoice.history.push({
          action: 'payment',
          user: userId,
          date: new Date(),
          reason: `Paiement de ${paymentAmount} par ${payment.method || 'espece'}`, 
        });
      }
      
      const updatedInvoice = await invoice.save();
      const populatedInvoice = await Invoice.findById(updatedInvoice._id).populate('client store user');

      res.json({ success: true, data: populatedInvoice });
    } catch (error) {
      console.error('[INVOICE][PUT] Erreur:', error.message);
      res.status(500).json({ message: 'Erreur lors de la modification de la facture.' });
    }
  },

  // [INVOICE][DELETE] Annuler une facture avec restockage, rollback et traçabilité
  async cancelInvoice(req, res) {
    console.log('[INVOICE][DELETE] Annulation de la facture', req.params.id);
    const session = await Stock.startSession();
    session.startTransaction();
    try {
      const { reason, userId } = req.body;
      const invoice = await Invoice.findById(req.params.id).session(session);
      if (!invoice) {
        await session.abortTransaction();
        return res.status(404).json({ message: 'Facture non trouvée.' });
      }
      if (invoice.status === 'annulee') {
        await session.abortTransaction();
        return res.status(400).json({ message: 'Facture déjà annulée.' });
      }
      // Restocker chaque produit + mouvement RELEASE
      for (const line of invoice.lines) {
        const stock = await Stock.findOne({ productId: line.product, storeId: invoice.store }).session(session);
        if (!stock) {
          console.warn(`[INVOICE][CANCEL] Stock introuvable pour produit ${line.product} dans magasin ${invoice.store}`);
          throw new Error(`Stock introuvable pour produit ${line.product}`);
        }
        const previousQuantity = stock.quantity;
        stock.quantity += line.quantity;
        stock.lastUpdated = new Date();
        await stock.save({ session });
        // Mouvement RELEASE
        await StockMovement.create({
          productId: line.product,
          storeId: invoice.store,
          type: 'RELEASE',
          quantity: line.quantity,
          previousQuantity,
          newQuantity: stock.quantity,
          reason: 'Restock suite annulation facture',
          reference: invoice.number,
          referenceType: 'INVOICE',
          userId,
        }, { session });
        console.log(`[INVOICE][CANCEL][STOCK] Produit ${line.product} - Stock restitué de ${line.quantity} (avant: ${previousQuantity}, après: ${stock.quantity})`);
      }
      invoice.status = 'annulee';
      invoice.cancelledBy = userId;
      invoice.cancelReason = reason;
      invoice.cancelledAt = new Date();
      invoice.history.push({ action: 'cancelled', user: userId, date: new Date(), reason });
      await invoice.save({ session });
      await session.commitTransaction();
      session.endSession();
      console.log('[INVOICE][DELETE] Facture annulée et stock rétabli');
      res.json({ success: true, data: invoice });
    } catch (error) {
      await session.abortTransaction();
      session.endSession();
      console.error('[INVOICE][DELETE][ROLLBACK] Erreur transactionnelle:', error.message);
      // Audit log
      await AuditLog.create({
        event: 'INVOICE_CANCEL_ROLLBACK',
        invoiceId: req.params.id,
        userId: req.body && req.body.userId,
        storeId: undefined, // Peut être enrichi si besoin
        details: { reason: req.body && req.body.reason },
        message: error.message,
      });
      res.status(500).json({ message: "Erreur lors de l'annulation de la facture.", error: error.message });
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