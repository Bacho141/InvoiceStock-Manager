import express from 'express';
import { 
  createStore, 
  getStores, 
  getStoreById, 
  updateStore, 
  toggleStoreStatus 
} from '../controllers/storeController.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// Toutes les routes nécessitent une authentification
router.use(verifyToken);

// Routes pour la gestion des magasins
router.post('/', createStore);           // Créer un magasin (super-admin)
router.get('/', getStores);              // Liste des magasins
router.get('/:id', getStoreById);        // Détails d'un magasin
router.put('/:id', updateStore);         // Modifier un magasin (super-admin)
router.patch('/:id/status', toggleStoreStatus); // Activer/désactiver (super-admin)

export default router; 