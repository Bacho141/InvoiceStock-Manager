import StockMovement from '../models/StockMovement.js';
import Stock from '../models/Stock.js';
import Product from '../models/Product.js';

/**
 * Ajouter un mouvement de stock (entrée, sortie, transfert...)
 */
const addMovement = async (req, res) => {
  const { storeId } = req.params;
  const { productId, type, quantity, reason, reference, referenceType } = req.body;
  const userId = req.user._id;
  console.log(`[MOVEMENT][ADD] ${type} produit ${productId} magasin ${storeId}`);
  try {
    let stock = await Stock.findOne({ productId, storeId });
    if (!stock) {
      stock = new Stock({ productId, storeId, quantity: 0 });
    }
    const previousQuantity = stock.quantity;
    let newQuantity = previousQuantity;
    if (type === 'IN') {
      newQuantity += quantity;
    } else if (type === 'OUT') {
      if (quantity > previousQuantity) {
        return res.status(400).json({ message: 'Stock insuffisant' });
      }
      newQuantity -= quantity;
    } else if (type === 'ADJUSTMENT') {
      newQuantity = quantity;
    } else {
      return res.status(400).json({ message: 'Type de mouvement non supporté' });
    }
    stock.quantity = newQuantity;
    stock.lastUpdated = new Date();
    await stock.save();
    const movement = await StockMovement.create({
      productId,
      storeId,
      type,
      quantity,
      previousQuantity,
      newQuantity,
      userId,
      reason,
      reference,
      referenceType
    });
    res.json({ success: true, message: 'Mouvement enregistré', data: movement });
  } catch (error) {
    console.error('[MOVEMENT][ADD] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors de l\'ajout du mouvement.' });
  }
};

/**
 * Lister les mouvements d'un magasin
 */
const getMovements = async (req, res) => {
  const { storeId } = req.params;
  const { page = 1, limit = 50, productId = '' } = req.query;
  console.log(`[MOVEMENT][LIST] Mouvements magasin ${storeId}`);
  try {
    let filter = { storeId };
    if (productId) filter.productId = productId;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const movements = await StockMovement.find(filter)
      .populate('productId')
      .populate('userId', 'username')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));
    const total = await StockMovement.countDocuments(filter);
    res.json({
      success: true,
      data: movements,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('[MOVEMENT][LIST] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors de la récupération des mouvements.' });
  }
};

/**
 * Historique des mouvements d'un produit donné dans un magasin, avec filtres
 */
const getProductMovements = async (req, res) => {
  const { storeId, productId } = req.params;
  const { startDate, endDate, userId, type } = req.query;
  const filter = { storeId, productId };
  if (type) filter.type = type;
  if (userId) filter.userId = userId;
  if (startDate || endDate) {
    filter.createdAt = {};
    if (startDate) filter.createdAt.$gte = new Date(startDate);
    if (endDate) filter.createdAt.$lte = new Date(endDate);
  }
  try {
    const mouvements = await StockMovement.find(filter)
      .populate('productId')
      .populate('userId', 'username')
      .sort({ createdAt: -1 });
    res.json({ success: true, data: mouvements });
  } catch (error) {
    console.error('[MOVEMENT][PRODUCT][LIST] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors de la récupération des mouvements.' });
  }
};

export default {
  addMovement,
  getMovements,
  getProductMovements
}; 