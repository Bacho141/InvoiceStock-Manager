import express from 'express';
import productController from '../controllers/productController.js';
import { addStoreContext } from '../middleware/storeAccessMiddleware.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// Toutes les routes nécessitent l'authentification et le contexte magasin
router.use(verifyToken, addStoreContext);

router.get('/', productController.getAllProducts);
router.get('/categories', productController.getCategories);
router.get('/:id', productController.getProduct);
router.post('/', productController.createProduct);
router.put('/:id', productController.updateProduct);
router.delete('/:id', productController.deleteProduct);

export default router; 