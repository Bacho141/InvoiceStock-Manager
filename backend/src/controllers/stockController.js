import Stock from '../models/Stock.js';
import Product from '../models/Product.js';
import StockMovement from '../models/StockMovement.js';
import StockAlert from '../models/StockAlert.js';

/**
 * Récupérer le stock d'un magasin
 */
const getStock = async (req, res) => {
  const { storeId } = req.params;
  const { page = 1, limit = 50, search = '' } = req.query;
  console.log(`[STOCK][GET] Récupération du stock pour magasin ${storeId}`);
  try {
    // Recherche des stocks pour ce magasin
    let stockFilter = { storeId };
    if (search) {
      // On doit d'abord trouver les produits correspondants
      const products = await Product.find({
        $or: [
          { name: { $regex: search, $options: 'i' } },
          { barcode: { $regex: search, $options: 'i' } }
        ]
      }).select('_id');
      stockFilter.productId = { $in: products.map(p => p._id) };
    }
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const stocks = await Stock.find(stockFilter)
      .populate('productId')
      .populate('storeId')
      .sort({ lastUpdated: -1 })
      .skip(skip)
      .limit(parseInt(limit));
    const total = await Stock.countDocuments(stockFilter);
    res.json({
      success: true,
      data: stocks,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('[STOCK][GET] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors de la récupération du stock.' });
  }
};

/**
 * Ajuster manuellement le stock d'un produit dans un magasin
 */
const adjustStock = async (req, res) => {
  const { storeId } = req.params;
  const { productId, newQuantity, reason } = req.body;
  const userId = req.user._id;
  console.log(`[STOCK][ADJUST] Ajustement du stock produit ${productId} magasin ${storeId}`);
  try {
    let stock = await Stock.findOne({ productId, storeId });
    if (!stock) {
      // Création si inexistant
      stock = new Stock({ productId, storeId, quantity: 0 });
    }
    const previousQuantity = stock.quantity;
    stock.quantity = newQuantity;
    stock.lastUpdated = new Date();
    await stock.save();
    // Log mouvement
    await StockMovement.create({
      productId,
      storeId,
      type: 'ADJUSTMENT',
      quantity: newQuantity,
      previousQuantity,
      newQuantity,
      userId,
      reason: reason || 'Ajustement manuel'
    });
    res.json({ success: true, message: 'Stock ajusté', data: stock });
  } catch (error) {
    console.error('[STOCK][ADJUST] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors de l\'ajustement du stock.' });
  }
};

/**
 * Listing avancé des stocks avec indicateurs et filtres
 */
const listStocks = async (req, res) => {
  const { storeId, category, statut, search } = req.query;
  const match = {};
  if (storeId) match.storeId = storeId;
  if (category) match['productId.category'] = category;
  if (statut) {
    if (statut === 'rupture') match.quantity = 0;
    else if (statut === 'faible') match.$expr = { $lte: ["$quantity", "$minQuantity"] };
    else if (statut === 'ok') match.$expr = { $gt: ["$quantity", "$minQuantity"] };
  }
  let productFilter = {};
  if (search) {
    productFilter = {
      $or: [
        { name: { $regex: search, $options: 'i' } },
        { reference: { $regex: search, $options: 'i' } },
        { category: { $regex: search, $options: 'i' } }
      ]
    };
  }
  try {
    const stocks = await Stock.find(match)
      .populate({
        path: 'productId',
        match: productFilter
      })
      .populate('storeId');
    const filteredStocks = stocks.filter(s => s.productId);
    const valeurTotale = filteredStocks.reduce((sum, s) => sum + ((s.productId?.purchasePrice || 0) * (s.quantity || 0)), 0);
    const nbActives = filteredStocks.filter(s => s.quantity > 0).length;
    const nbInactives = filteredStocks.filter(s => s.quantity === 0).length;
    const nbAlertes = filteredStocks.filter(s => s.quantity <= (s.minQuantity || 0) && s.quantity > 0).length;
    const nbRuptures = filteredStocks.filter(s => s.quantity === 0).length;
    res.json({
      success: true,
      stocks: filteredStocks,
      indicateurs: {
        valeurTotale,
        nbActives,
        nbInactives,
        nbAlertes,
        nbRuptures
      }
    });
  } catch (error) {
    console.error('[STOCK][LIST] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors du listing des stocks.' });
  }
};

/**
 * Transfert de stock entre magasins
 */
const transferStock = async (req, res) => {
  const { productId, fromStoreId, toStoreId, quantity, reason } = req.body;
  const user = req.user;
  try {
    // Sortie du magasin source
    let stockSource = await Stock.findOne({ storeId: fromStoreId, productId });
    if (!stockSource || stockSource.quantity < quantity)
      return res.status(400).json({ message: 'Stock source insuffisant.' });
    const stockAvantSource = stockSource.quantity;
    stockSource.quantity -= quantity;
    await stockSource.save();
    // Entrée dans le magasin destination
    let stockDest = await Stock.findOne({ storeId: toStoreId, productId });
    if (!stockDest) {
      stockDest = await Stock.create({
        storeId: toStoreId,
        productId,
        quantity: 0,
        minQuantity: 0,
        isActive: true
      });
    }
    const stockAvantDest = stockDest.quantity;
    stockDest.quantity += quantity;
    await stockDest.save();
    // Mouvements
    const mouvementSortie = await StockMovement.create({
      productId,
      storeId: fromStoreId,
      type: 'TRANSFER_OUT',
      quantity: -quantity,
      stockAvant: stockAvantSource,
      stockApres: stockSource.quantity,
      user: { _id: user._id, username: user.username, role: user.role },
      reason: `Transfert vers magasin ${toStoreId} - ${reason}`
    });
    const mouvementEntree = await StockMovement.create({
      productId,
      storeId: toStoreId,
      type: 'TRANSFER_IN',
      quantity: quantity,
      stockAvant: stockAvantDest,
      stockApres: stockDest.quantity,
      user: { _id: user._id, username: user.username, role: user.role },
      reason: `Transfert depuis magasin ${fromStoreId} - ${reason}`
    });
    res.json({ success: true, mouvements: [mouvementSortie, mouvementEntree] });
  } catch (error) {
    console.error('[STOCK][TRANSFER] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors du transfert de stock.' });
  }
};

/**
 * Indicateurs clés pour un magasin
 */
const getIndicators = async (req, res) => {
  const { storeId } = req.params;
  console.log(`[STOCK][INDICATORS] Début du calcul pour le magasin: ${storeId}`);
  try {
    // Récupérer tous les stocks du magasin avec les produits
    console.log(`[STOCK][INDICATORS] Récupération des stocks...`);
    const stocks = await Stock.find({ storeId }).populate('productId');
    console.log(`[STOCK][INDICATORS] ${stocks.length} stocks trouvés.`);

    const validStocks = stocks.filter(s => {
      if (!s.productId) {
        console.warn(`[STOCK][INDICATORS] Stock orphelin trouvé (ID: ${s._id}), produit non existant. Il sera ignoré.`);
        return false;
      }
      return true;
    });
    console.log(`[STOCK][INDICATORS] ${validStocks.length} stocks valides après filtrage.`);

    // Valeur totale du stock
    const valeurTotale = validStocks.reduce((sum, s) => {
      const price = s.productId?.purchasePrice || 0;
      const quantity = s.quantity || 0;
      return sum + (price * quantity);
    }, 0);
    console.log(`[STOCK][INDICATORS] Valeur totale calculée: ${valeurTotale}`);

    // Nombre de références actives (stock > 0)
    const nbActives = validStocks.filter(s => s.quantity > 0).length;
    console.log(`[STOCK][INDICATORS] Nombre de références actives: ${nbActives}`);

    // Nombre de produits en rupture (stock = 0)
    const nbRuptures = validStocks.filter(s => s.quantity === 0).length;
    console.log(`[STOCK][INDICATORS] Nombre de produits en rupture: ${nbRuptures}`);

    // Nombre d'alertes (seuil critique ou rupture)
    console.log(`[STOCK][INDICATORS] Comptage des alertes...`);
    const nbAlertes = await StockAlert.countDocuments({ storeId, isResolved: false });
    console.log(`[STOCK][INDICATORS] Nombre d'alertes trouvées: ${nbAlertes}`);

    // Nombre d'alertes de seuil (stock <= minQuantity mais > 0)
    const nbAlertesSeuil = validStocks.filter(s => s.quantity <= (s.minQuantity || 0) && s.quantity > 0).length;
    console.log(`[STOCK][INDICATORS] Nombre d'alertes de seuil: ${nbAlertesSeuil}`);

    const responseData = {
      valeurTotale,
      nbActives,
      nbRuptures,
      nbAlertes,
      nbAlertesSeuil
    };
    console.log('[STOCK][INDICATORS] Données finales:', responseData);

    res.json({
      success: true,
      data: responseData
    });
  } catch (error) {
    console.error('[STOCK][INDICATORS] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors du calcul des indicateurs.' });
  }
};

/**
 * Indicateurs globaux pour tous les magasins
 */
const getGlobalIndicators = async (req, res) => {
  try {
    // Récupérer tous les stocks avec les produits
    const stocks = await Stock.find({}).populate('productId');
    const validStocks = stocks.filter(s => s.productId);
    // Valeur totale du stock
    const valeurTotale = validStocks.reduce((sum, s) => sum + ((s.productId?.purchasePrice || 0) * (s.quantity || 0)), 0);
    // Nombre de références actives (stock > 0)
    const nbActives = validStocks.filter(s => s.quantity > 0).length;
    // Nombre de produits en rupture (stock = 0)
    const nbRuptures = validStocks.filter(s => s.quantity === 0).length;
    // Nombre d'alertes (seuil critique ou rupture)
    const nbAlertes = await StockAlert.countDocuments({ isResolved: false });
    // Nombre d'alertes de seuil (stock <= minQuantity mais > 0)
    const nbAlertesSeuil = validStocks.filter(s => s.quantity <= (s.minQuantity || 0) && s.quantity > 0).length;
    res.json({
      success: true,
      data: {
        valeurTotale,
        nbActives,
        nbRuptures,
        nbAlertes,
        nbAlertesSeuil
      }
    });
  } catch (error) {
    console.error('[STOCK][INDICATORS][GLOBAL] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors du calcul des indicateurs globaux.' });
  }
};

// Méthode pour réserver du stock
// quantity: quantité à réserver
// userId: identifiant utilisateur à associer à la réservation
Stock.schema.methods.reserveStock = function(quantity, userId) {
  this.reservedQuantity += quantity;
  this.reservationUserId = userId;
  this.lastUpdated = new Date();
  
  return this;
};

/**
 * Libère toutes les réservations de stock pour un utilisateur donné (userId)
 * Annule toutes les réservations en attente (reservedQuantity > 0)
 */
const releaseAllSessionReservations = async (req, res) => {
  try {
    const { userId } = req.body; // ou req.session.userId selon l'authentification
    if (!userId) {
      return res.status(400).json({ success: false, message: 'userId requis' });
    }
    // On suppose que chaque Stock est lié à un userId pour les réservations (sinon, il faut adapter le modèle)
    // Ici, on libère toutes les réservations de tous les stocks pour cet utilisateur
    const stocks = await Stock.find({ reservedQuantity: { $gt: 0 }, 'reservationUserId': userId });
    let nbLiberees = 0;
    for (const stock of stocks) {
      stock.reservedQuantity = 0;
      stock.reservationUserId = null;
      stock.lastUpdated = new Date();
      await stock.save();
      nbLiberees++;
    }
    res.json({ success: true, message: `Réservations libérées : ${nbLiberees}` });
  } catch (error) {
    console.error('[STOCK][RELEASE_ALL_RESERVATIONS] Erreur:', error.message);
    res.status(500).json({ success: false, message: 'Erreur lors de la libération des réservations.' });
  }
};

/**
 * Vérifie la disponibilité d'un produit dans un magasin
 * GET /:storeId/:productId/availability
 */
const checkAvailability = async (req, res) => {
  const { storeId, productId } = req.params;
  try {
    const stock = await Stock.findOne({ storeId, productId });
    if (!stock) {
      return res.status(404).json({
        success: false,
        available: false,
        quantity: 0,
        message: 'Stock non trouvé pour ce produit dans ce magasin.'
      });
    }
    return res.json({
      success: true,
      available: stock.quantity > 0,
      quantity: stock.quantity
    });
  } catch (error) {
    console.error('[STOCK][AVAILABILITY] Erreur:', error.message);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification de disponibilité.'
    });
  }
};

/**
 * Récupère le stock d'un produit précis dans un magasin
 * GET /:storeId/:productId
 */
const getProductStock = async (req, res) => {
  const { storeId, productId } = req.params;
  try {
    const stock = await Stock.findOne({ storeId, productId });
    if (!stock) {
      // Retourne un stock vide si non trouvé
      return res.json({ data: { quantity: 0, reserved: 0, available: 0, lastMovement: null } });
    }
    // Adapte selon ton modèle de Stock
    return res.json({
      data: {
        quantity: stock.quantity || 0,
        reserved: stock.reservedQuantity || 0,
        available: (stock.quantity || 0) - (stock.reservedQuantity || 0),
        lastMovement: stock.lastMovement || null
      }
    });
  } catch (error) {
    console.error('[STOCK][GET_PRODUCT_STOCK] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors de la récupération du stock du produit.' });
  }
};

export default {
  getStock,
  adjustStock,
  listStocks,
  transferStock,
  getIndicators,
  getGlobalIndicators,
  releaseAllSessionReservations,
  checkAvailability,
  getProductStock
};