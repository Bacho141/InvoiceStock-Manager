const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../../src/models/User');
const Store = require('../../src/models/Store');
const Product = require('../../src/models/Product');
const Stock = require('../../src/models/Stock');

/**
 * Créer un utilisateur de test
 */
const createTestUser = async (userData = {}) => {
  const defaultData = {
    username: 'testuser',
    password: 'password123',
    role: 'gestionnaire',
    isActive: true,
    ...userData
  };

  const hashedPassword = await bcrypt.hash(defaultData.password, 10);
  const user = new User({
    ...defaultData,
    password: hashedPassword
  });

  return await user.save();
};

/**
 * Créer un super-admin de test
 */
const createTestSuperAdmin = async () => {
  return await createTestUser({
    username: 'superadmin',
    password: 'admin123',
    role: 'super-admin'
  });
};

/**
 * Créer un magasin de test
 */
const createTestStore = async (storeData = {}) => {
  const defaultData = {
    name: 'Magasin Test',
    address: '123 Rue Test',
    city: 'Ville Test',
    phone: '0123456789',
    isActive: true,
    ...storeData
  };

  const store = new Store(defaultData);
  return await store.save();
};

/**
 * Créer un produit de test
 */
const createTestProduct = async (productData = {}, userId) => {
  const defaultData = {
    name: 'Produit Test',
    description: 'Description du produit test',
    category: 'Test',
    unit: 'pièce',
    purchasePrice: 10.0,
    sellingPrice: 15.0,
    minStockLevel: 5,
    maxStockLevel: 100,
    isActive: true,
    createdBy: userId,
    ...productData
  };

  const product = new Product(defaultData);
  return await product.save();
};

/**
 * Créer un stock de test
 */
const createTestStock = async (productId, storeId, quantity = 50) => {
  const stock = new Stock({
    productId,
    storeId,
    quantity,
    reservedQuantity: 0
  });

  return await stock.save();
};

/**
 * Générer un token JWT pour un utilisateur
 */
const generateTestToken = (user) => {
  return jwt.sign(
    { 
      userId: user._id, 
      username: user.username, 
      role: user.role 
    },
    process.env.JWT_SECRET || 'test-secret',
    { expiresIn: '1h' }
  );
};

/**
 * Créer un setup complet pour les tests multi-magasins
 */
const createTestSetup = async () => {
  // Créer super-admin
  const superAdmin = await createTestSuperAdmin();
  
  // Créer gestionnaire
  const gestionnaire = await createTestUser({
    username: 'gestionnaire',
    role: 'gestionnaire'
  });
  
  // Créer caissier
  const caissier = await createTestUser({
    username: 'caissier',
    role: 'caissier'
  });

  // Créer magasins
  const store1 = await createTestStore({ name: 'Magasin 1' });
  const store2 = await createTestStore({ name: 'Magasin 2' });

  // Assigner magasins aux utilisateurs
  gestionnaire.assignedStores = [store1._id];
  caissier.assignedStores = [store1._id, store2._id];
  await gestionnaire.save();
  await caissier.save();

  // Créer produits
  const product1 = await createTestProduct({ name: 'Produit 1' }, superAdmin._id);
  const product2 = await createTestProduct({ name: 'Produit 2' }, superAdmin._id);

  // Créer stocks
  const stock1 = await createTestStock(product1._id, store1._id, 25);
  const stock2 = await createTestStock(product2._id, store1._id, 10);
  const stock3 = await createTestStock(product1._id, store2._id, 15);

  return {
    users: { superAdmin, gestionnaire, caissier },
    stores: { store1, store2 },
    products: { product1, product2 },
    stocks: { stock1, stock2, stock3 }
  };
};

module.exports = {
  createTestUser,
  createTestSuperAdmin,
  createTestStore,
  createTestProduct,
  createTestStock,
  generateTestToken,
  createTestSetup
}; 