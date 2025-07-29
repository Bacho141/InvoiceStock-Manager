const request = require('supertest');
const app = require('../../server');
const { createTestSetup, generateTestToken } = require('../utils/testHelpers');

describe('Store Access Middleware', () => {
  let setup, superAdminToken, gestionnaireToken, caissierToken;

  beforeEach(async () => {
    setup = await createTestSetup();
    superAdminToken = generateTestToken(setup.users.superAdmin);
    gestionnaireToken = generateTestToken(setup.users.gestionnaire);
    caissierToken = generateTestToken(setup.users.caissier);
  });

  describe('checkStoreAccess', () => {
    it('should allow super-admin access to any store', async () => {
      const response = await request(app)
        .get(`/api/stores/${setup.stores.store1._id}/stock`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should allow user access to assigned store', async () => {
      const response = await request(app)
        .get(`/api/stores/${setup.stores.store1._id}/stock`)
        .set('Authorization', `Bearer ${gestionnaireToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should deny user access to non-assigned store', async () => {
      const response = await request(app)
        .get(`/api/stores/${setup.stores.store2._id}/stock`)
        .set('Authorization', `Bearer ${gestionnaireToken}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Accès refusé');
      expect(response.body.error).toBe('STORE_ACCESS_DENIED');
    });

    it('should allow caissier access to both assigned stores', async () => {
      // Accès au premier magasin assigné
      const response1 = await request(app)
        .get(`/api/stores/${setup.stores.store1._id}/stock`)
        .set('Authorization', `Bearer ${caissierToken}`)
        .expect(200);

      expect(response1.body.success).toBe(true);

      // Accès au deuxième magasin assigné
      const response2 = await request(app)
        .get(`/api/stores/${setup.stores.store2._id}/stock`)
        .set('Authorization', `Bearer ${caissierToken}`)
        .expect(200);

      expect(response2.body.success).toBe(true);
    });

    it('should return 400 for missing storeId', async () => {
      const response = await request(app)
        .get('/api/stores//stock')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(400);

      expect(response.body.message).toBe('ID du magasin requis');
    });

    it('should return 500 for invalid storeId format', async () => {
      const response = await request(app)
        .get('/api/stores/invalid-id/stock')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(500);

      expect(response.body.error).toBe('STORE_ACCESS_ERROR');
    });
  });

  describe('addStoreContext', () => {
    it('should add allStores context for super-admin', async () => {
      const response = await request(app)
        .get('/api/products')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      // Le super-admin devrait voir tous les produits
      expect(response.body.data.length).toBeGreaterThan(0);
    });

    it('should add assignedStores context for other roles', async () => {
      const response = await request(app)
        .get('/api/products')
        .set('Authorization', `Bearer ${gestionnaireToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      // Le gestionnaire ne devrait voir que les produits de ses magasins assignés
      expect(response.body.data.length).toBeGreaterThan(0);
    });
  });

  describe('checkMultipleStoreAccess', () => {
    it('should allow super-admin access to multiple stores', async () => {
      const response = await request(app)
        .post('/api/bulk-operation')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send({
          storeIds: [setup.stores.store1._id.toString(), setup.stores.store2._id.toString()]
        })
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should allow user access to all requested assigned stores', async () => {
      const response = await request(app)
        .post('/api/bulk-operation')
        .set('Authorization', `Bearer ${caissierToken}`)
        .send({
          storeIds: [setup.stores.store1._id.toString(), setup.stores.store2._id.toString()]
        })
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should deny access if user cannot access all requested stores', async () => {
      const response = await request(app)
        .post('/api/bulk-operation')
        .set('Authorization', `Bearer ${gestionnaireToken}`)
        .send({
          storeIds: [setup.stores.store1._id.toString(), setup.stores.store2._id.toString()]
        })
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Accès refusé');
      expect(response.body.error).toBe('MULTI_STORE_ACCESS_DENIED');
    });

    it('should return 400 for missing storeIds', async () => {
      const response = await request(app)
        .post('/api/bulk-operation')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send({})
        .expect(400);

      expect(response.body.message).toBe('Liste des IDs de magasins requise');
    });

    it('should return 400 for invalid storeIds format', async () => {
      const response = await request(app)
        .post('/api/bulk-operation')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send({ storeIds: 'invalid' })
        .expect(400);

      expect(response.body.message).toBe('Liste des IDs de magasins requise');
    });
  });

  describe('checkHasAssignedStores', () => {
    it('should allow super-admin access without assigned stores', async () => {
      // Créer un super-admin sans magasins assignés
      const superAdminNoStores = await setup.users.superAdmin;
      superAdminNoStores.assignedStores = [];
      await superAdminNoStores.save();

      const token = generateTestToken(superAdminNoStores);

      const response = await request(app)
        .get('/api/products')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should deny access for user without assigned stores', async () => {
      // Créer un utilisateur sans magasins assignés
      const userNoStores = await setup.users.gestionnaire;
      userNoStores.assignedStores = [];
      await userNoStores.save();

      const token = generateTestToken(userNoStores);

      const response = await request(app)
        .get('/api/products')
        .set('Authorization', `Bearer ${token}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toContain('Aucun magasin assigné');
      expect(response.body.error).toBe('NO_ASSIGNED_STORES');
    });
  });
}); 