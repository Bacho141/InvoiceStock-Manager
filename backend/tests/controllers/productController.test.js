const request = require('supertest');
const app = require('../../server');
const { createTestSetup, generateTestToken } = require('../utils/testHelpers');

describe('Product Controller', () => {
  let setup, superAdminToken, gestionnaireToken, caissierToken;

  beforeEach(async () => {
    setup = await createTestSetup();
    superAdminToken = generateTestToken(setup.users.superAdmin);
    gestionnaireToken = generateTestToken(setup.users.gestionnaire);
    caissierToken = generateTestToken(setup.users.caissier);
  });

  describe('GET /api/products', () => {
    it('should get all products for super-admin', async () => {
      const response = await request(app)
        .get('/api/products')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(2);
      expect(response.body.pagination).toBeDefined();
    });

    it('should filter products by assigned stores for gestionnaire', async () => {
      const response = await request(app)
        .get('/api/products')
        .set('Authorization', `Bearer ${gestionnaireToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      // Le gestionnaire ne devrait voir que les produits de son magasin assigné
      expect(response.body.data.length).toBeGreaterThan(0);
    });

    it('should filter products by assigned stores for caissier', async () => {
      const response = await request(app)
        .get('/api/products')
        .set('Authorization', `Bearer ${caissierToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      // Le caissier devrait voir les produits de ses magasins assignés
      expect(response.body.data.length).toBeGreaterThan(0);
    });

    it('should search products by name', async () => {
      const response = await request(app)
        .get('/api/products?search=Produit 1')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].name).toBe('Produit 1');
    });

    it('should filter by category', async () => {
      const response = await request(app)
        .get('/api/products?category=Test')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(2);
    });
  });

  describe('GET /api/products/:id', () => {
    it('should get product by id for super-admin', async () => {
      const response = await request(app)
        .get(`/api/products/${setup.products.product1._id}`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Produit 1');
    });

    it('should deny access to product not in assigned stores', async () => {
      // Créer un produit dans un magasin non assigné au gestionnaire
      const newProduct = await setup.products.product1;
      
      const response = await request(app)
        .get(`/api/products/${newProduct._id}`)
        .set('Authorization', `Bearer ${gestionnaireToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Accès refusé');
    });

    it('should return 404 for non-existent product', async () => {
      const fakeId = '507f1f77bcf86cd799439011';
      const response = await request(app)
        .get(`/api/products/${fakeId}`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Produit non trouvé');
    });
  });

  describe('POST /api/products', () => {
    it('should create product successfully', async () => {
      const productData = {
        name: 'Nouveau Produit',
        description: 'Description du nouveau produit',
        category: 'Test',
        unit: 'pièce',
        purchasePrice: 12.0,
        sellingPrice: 18.0,
        minStockLevel: 5,
        maxStockLevel: 100
      };

      const response = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send(productData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe(productData.name);
      expect(response.body.data.createdBy).toBeDefined();
    });

    it('should validate required fields', async () => {
      const productData = {
        description: 'Description sans nom'
        // Manque name, purchasePrice, sellingPrice
      };

      const response = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send(productData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('sont requis');
    });

    it('should prevent duplicate barcode', async () => {
      const productData = {
        name: 'Produit avec code-barres',
        purchasePrice: 10.0,
        sellingPrice: 15.0,
        barcode: '123456789'
      };

      // Créer le premier produit
      await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send(productData)
        .expect(201);

      // Essayer de créer un deuxième avec le même code-barres
      const response = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send(productData)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('code-barres existe déjà');
    });
  });

  describe('PUT /api/products/:id', () => {
    it('should update product successfully', async () => {
      const updateData = {
        name: 'Produit Modifié',
        description: 'Nouvelle description',
        sellingPrice: 20.0
      };

      const response = await request(app)
        .put(`/api/products/${setup.products.product1._id}`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe(updateData.name);
      expect(response.body.data.sellingPrice).toBe(updateData.sellingPrice);
    });

    it('should deny access to update product not in assigned stores', async () => {
      const updateData = { name: 'Produit Modifié' };

      const response = await request(app)
        .put(`/api/products/${setup.products.product1._id}`)
        .set('Authorization', `Bearer ${gestionnaireToken}`)
        .send(updateData)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Accès refusé');
    });
  });

  describe('DELETE /api/products/:id', () => {
    it('should delete product (deactivate) successfully', async () => {
      const response = await request(app)
        .delete(`/api/products/${setup.products.product1._id}`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Produit supprimé avec succès');

      // Vérifier que le produit est désactivé
      const product = await setup.products.product1.constructor.findById(setup.products.product1._id);
      expect(product.isActive).toBe(false);
    });

    it('should deny access to delete product not in assigned stores', async () => {
      const response = await request(app)
        .delete(`/api/products/${setup.products.product1._id}`)
        .set('Authorization', `Bearer ${gestionnaireToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Accès refusé');
    });
  });

  describe('GET /api/products/categories', () => {
    it('should get categories for super-admin', async () => {
      const response = await request(app)
        .get('/api/products/categories')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toContain('Test');
    });

    it('should filter categories by assigned stores for other roles', async () => {
      const response = await request(app)
        .get('/api/products/categories')
        .set('Authorization', `Bearer ${gestionnaireToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });
  });
}); 