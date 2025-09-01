import express from 'express';
import { 
  createClient, 
  getClients, 
  getClientById, 
  updateClient, 
  deleteClient,
  addCommunication,
  updateScore,
  refreshMetrics,
  getOverdueInvoices, // Ajout de la nouvelle fonction
  getClientOverdueInvoices
} from '../controllers/clientController.js';
import * as clientAnalyticsController from '../controllers/clientAnalyticsController.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// Toutes les routes nécessitent une authentification
router.use(verifyToken);

// Routes Analytics (AVANT les routes paramétrées)
router.get('/analytics/dashboard', clientAnalyticsController.getDashboardMetrics);
router.get('/analytics/top-clients', clientAnalyticsController.getTopClients);
router.get('/analytics/creances', clientAnalyticsController.getCreancesAnalysis);
router.get('/analytics/overdue', clientAnalyticsController.getOverdueClients);

// Routes CRUD de base
router.post('/', createClient);
router.get('/', getClients);

// Route spécifique pour les factures en retard (AVANT les routes paramétrées)
router.get('/overdue-invoices', getOverdueInvoices);

// Routes spécifiques par client (APRÈS les routes analytics et autres routes spécifiques)
router.get('/:id/stats', clientAnalyticsController.getClientStats);
router.get('/:id/evolution', clientAnalyticsController.getClientEvolution);
router.get('/:id/overdue-invoices', getClientOverdueInvoices); // Ajout de la route pour les factures en retard d'un client
router.post('/:id/communication', addCommunication);
router.put('/:id/score', updateScore);
router.post('/:id/refresh-metrics', refreshMetrics);
router.get('/:id', getClientById);
router.put('/:id', updateClient);
router.delete('/:id', deleteClient);

export default router; 