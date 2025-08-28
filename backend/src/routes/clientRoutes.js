import express from 'express';
import { createClient, getClients, getClientById, updateClient, deleteClient, addCommunication, updateScore, refreshMetrics } from '../controllers/clientController.js';
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

// Routes spécifiques par client (APRÈS les routes analytics)
router.get('/:id/stats', clientAnalyticsController.getClientStats);
router.get('/:id/evolution', clientAnalyticsController.getClientEvolution);
router.post('/:id/communication', addCommunication);
router.put('/:id/score', updateScore);
router.post('/:id/refresh-metrics', refreshMetrics);
router.get('/:id', getClientById);
router.put('/:id', updateClient);
router.delete('/:id', deleteClient);

export default router; 