import express from 'express';
import stockController from '../controllers/stockController.js';
import stockMovementController from '../controllers/stockMovementController.js';
import stockAlertController from '../controllers/stockAlertController.js';
import { checkStoreAccess } from '../middleware/storeAccessMiddleware.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// Toutes les routes nécessitent l'authentification et la vérification d'accès magasin
router.use(verifyToken);

// Libération de toutes les réservations de stock pour un utilisateur (via userId dans req.body)
router.post('/releaseAllReservations', stockController.releaseAllSessionReservations);

// Stock par magasin
router.get('/alerts', stockAlertController.getAllAlerts);
router.get('/indicators', stockController.getGlobalIndicators);
// Transfert de stock entre magasins
router.post('/transfer', stockController.transferStock);

router.get('/:storeId', checkStoreAccess, stockController.getStock);
router.post('/:storeId/adjust', checkStoreAccess, stockController.adjustStock);

// Mouvements de stock
router.post('/:storeId/movement', checkStoreAccess, stockMovementController.addMovement);
router.get('/:storeId/movements', checkStoreAccess, stockMovementController.getMovements);
// Vérification de la disponibilité d'un produit dans un magasin
router.get('/:storeId/:productId/availability', checkStoreAccess, stockController.checkAvailability);
// Stock d'un produit précis dans un magasin
router.get('/:storeId/:productId', checkStoreAccess, stockController.getProductStock);

// Historique d'un produit donné dans un magasin (avec filtres)
router.get('/:storeId/:productId/movements', checkStoreAccess, stockMovementController.getProductMovements);

// Alertes de stock
router.get('/:storeId/alerts', checkStoreAccess, stockAlertController.getAlerts);
router.post('/:storeId/alerts/:alertId/read', checkStoreAccess, stockAlertController.markAsRead);
router.post('/:storeId/alerts/:alertId/resolve', checkStoreAccess, stockAlertController.resolveAlert);

// Indicateurs clés du stock
router.get('/:storeId/indicators', checkStoreAccess, stockController.getIndicators);

// Listing avancé des stocks avec indicateurs et filtres
router.get('/', stockController.listStocks);



export default router; 