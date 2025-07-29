import StockAlert from '../models/StockAlert.js';
import Product from '../models/Product.js';
import Store from '../models/Store.js';

/**
 * Lister les alertes d'un magasin
 */
const getAlerts = async (req, res) => {
  const { storeId } = req.params;
  const { page = 1, limit = 50, isActive = true } = req.query;
  console.log(`[ALERT][LIST] Alertes magasin ${storeId}`);
  try {
    const filter = { storeId, isActive: isActive === 'true' };
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const alerts = await StockAlert.find(filter)
      .populate('productId')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));
    const total = await StockAlert.countDocuments(filter);
    res.json({
      success: true,
      data: alerts,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('[ALERT][LIST] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors de la récupération des alertes.' });
  }
};

/**
 * Marquer une alerte comme lue
 */
const markAsRead = async (req, res) => {
  const { alertId } = req.params;
  const userId = req.user._id;
  console.log(`[ALERT][READ] Marquer l'alerte ${alertId} comme lue`);
  try {
    const alert = await StockAlert.findById(alertId);
    if (!alert) {
      return res.status(404).json({ message: 'Alerte non trouvée' });
    }
    alert.markAsRead(userId);
    await alert.save();
    res.json({ success: true, message: 'Alerte marquée comme lue', data: alert });
  } catch (error) {
    console.error('[ALERT][READ] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors du marquage de l\'alerte.' });
  }
};

/**
 * Résoudre une alerte
 */
const resolveAlert = async (req, res) => {
  const { alertId } = req.params;
  const userId = req.user._id;
  const { notes } = req.body;
  console.log(`[ALERT][RESOLVE] Résolution de l'alerte ${alertId}`);
  try {
    const alert = await StockAlert.findById(alertId);
    if (!alert) {
      return res.status(404).json({ message: 'Alerte non trouvée' });
    }
    alert.resolve(userId, notes);
    await alert.save();
    res.json({ success: true, message: 'Alerte résolue', data: alert });
  } catch (error) {
    console.error('[ALERT][RESOLVE] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors de la résolution de l\'alerte.' });
  }
};

/**
 * Lister toutes les alertes de tous les magasins
 */
const getAllAlerts = async (req, res) => {
  const { page = 1, limit = 50, isActive = true } = req.query;
  console.log(`[ALERT][LIST][GLOBAL] Toutes les alertes (tous magasins)`);
  try {
    const filter = { isActive: isActive === 'true' };
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const alerts = await StockAlert.find(filter)
      .populate('productId')
      .populate('storeId')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));
    const total = await StockAlert.countDocuments(filter);
    res.json({
      success: true,
      data: alerts,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('[ALERT][LIST][GLOBAL] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur lors de la récupération des alertes globales.' });
  }
};

export default {
  getAlerts,
  markAsRead,
  resolveAlert,
  getAllAlerts
}; 