import express from 'express';
import { createClient, getClients, getClientById, updateClient, deleteClient } from '../controllers/clientController.js';

const router = express.Router();

// Créer un client
router.post('/', createClient);
// Lister les clients
router.get('/', getClients);
// Détail d'un client
router.get('/:id', getClientById);
// Modifier un client
router.put('/:id', updateClient);
// Supprimer un client
router.delete('/:id', deleteClient);

export default router; 