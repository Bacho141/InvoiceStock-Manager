const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// Importer les modèles
const User = require('./src/models/User');
const Store = require('./src/models/Store');
const Product = require('./src/models/Product');
const Stock = require('./src/models/Stock');

// Importer les contrôleurs
const productController = require('./src/controllers/productController');
const stockController = require('./src/controllers/stockController');

console.log('🧪 Test des contrôleurs...');

// Mock des objets req et res
function createMockRequest(user, params = {}, body = {}, query = {}) {
  return {
    user,
    params,
    body,
    query,
    headers: {}
  };
}

function createMockResponse() {
  const res = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
    send: jest.fn().mockReturnThis()
  };
  return res;
}

// Créer des données de test
async function createTestData() {
  console.log('📝 Création des données de test...');
  
  // Créer un super-admin
  const superAdmin = new User({
    username: 'superadmin',
    password: await bcrypt.hash('admin123', 10),
    role: 'super-admin',
    isActive: true
  });
  await superAdmin.save();
  
  // Créer un gestionnaire
  const gestionnaire = new User({
    username: 'gestionnaire',
    password: await bcrypt.hash('password123', 10),
    role: 'gestionnaire',
    isActive: true
  });
  await gestionnaire.save();
  
  // Créer des magasins
  const store1 = new Store({
    name: 'Magasin 1',
    address: '123 Rue Test',
    city: 'Ville Test',
    phone: '0123456789'
  });
  await store1.save();
  
  const store2 = new Store({
    name: 'Magasin 2',
    address: '456 Avenue Test',
    city: 'Ville Test 2',
    phone: '0987654321'
  });
  await store2.save();
  
  // Assigner magasins aux utilisateurs
  gestionnaire.assignedStores = [store1._id];
  await gestionnaire.save();
  
  // Créer des produits
  const product1 = new Product({
    name: 'Produit 1',
    description: 'Description produit 1',
    category: 'Test',
    unit: 'pièce',
    purchasePrice: 10.0,
    sellingPrice: 15.0,
    minStockLevel: 5,
    maxStockLevel: 100,
    createdBy: superAdmin._id
  });
  await product1.save();
  
  const product2 = new Product({
    name: 'Produit 2',
    description: 'Description produit 2',
    category: 'Test',
    unit: 'kg',
    purchasePrice: 20.0,
    sellingPrice: 30.0,
    minStockLevel: 10,
    maxStockLevel: 200,
    createdBy: superAdmin._id
  });
  await product2.save();
  
  // Créer des stocks
  const stock1 = new Stock({
    productId: product1._id,
    storeId: store1._id,
    quantity: 25,
    reservedQuantity: 5
  });
  await stock1.save();
  
  const stock2 = new Stock({
    productId: product2._id,
    storeId: store1._id,
    quantity: 15,
    reservedQuantity: 0
  });
  await stock2.save();
  
  return {
    users: { superAdmin, gestionnaire },
    stores: { store1, store2 },
    products: { product1, product2 },
    stocks: { stock1, stock2 }
  };
}

// Test du contrôleur produit
async function testProductController(data) {
  console.log('\n📦 Test du contrôleur produit...');
  
  // Test GET /api/products (super-admin)
  console.log('🔍 Test récupération produits (super-admin)...');
  const req1 = createMockRequest(data.users.superAdmin, {}, {}, {});
  const res1 = createMockResponse();
  
  await productController.getProducts(req1, res1);
  
  if (res1.status.mock.calls.length > 0) {
    console.log('✅ Status:', res1.status.mock.calls[0][0]);
  }
  if (res1.json.mock.calls.length > 0) {
    const response = res1.json.mock.calls[0][0];
    console.log('📊 Nombre de produits:', response.data?.length || 0);
    console.log('✅ Succès:', response.success);
  }
  
  // Test GET /api/products (gestionnaire)
  console.log('🔍 Test récupération produits (gestionnaire)...');
  const req2 = createMockRequest(data.users.gestionnaire, {}, {}, {});
  const res2 = createMockResponse();
  
  await productController.getProducts(req2, res2);
  
  if (res2.json.mock.calls.length > 0) {
    const response = res2.json.mock.calls[0][0];
    console.log('📊 Nombre de produits (gestionnaire):', response.data?.length || 0);
    console.log('✅ Succès:', response.success);
  }
  
  // Test POST /api/products
  console.log('➕ Test création produit...');
  const newProduct = {
    name: 'Nouveau Produit',
    description: 'Description nouveau produit',
    category: 'Test',
    unit: 'pièce',
    purchasePrice: 12.0,
    sellingPrice: 18.0,
    minStockLevel: 5,
    maxStockLevel: 100
  };
  
  const req3 = createMockRequest(data.users.superAdmin, {}, newProduct, {});
  const res3 = createMockResponse();
  
  await productController.createProduct(req3, res3);
  
  if (res3.status.mock.calls.length > 0) {
    console.log('✅ Status création:', res3.status.mock.calls[0][0]);
  }
  if (res3.json.mock.calls.length > 0) {
    const response = res3.json.mock.calls[0][0];
    console.log('✅ Produit créé:', response.success);
    if (response.data) {
      console.log('📝 Nom:', response.data.name);
      console.log('💰 Prix de vente:', response.data.sellingPrice);
    }
  }
}

// Test du contrôleur stock
async function testStockController(data) {
  console.log('\n📊 Test du contrôleur stock...');
  
  // Test GET /api/stock (super-admin)
  console.log('🔍 Test récupération stock (super-admin)...');
  const req1 = createMockRequest(data.users.superAdmin, {}, {}, {});
  const res1 = createMockResponse();
  
  await stockController.getStock(req1, res1);
  
  if (res1.json.mock.calls.length > 0) {
    const response = res1.json.mock.calls[0][0];
    console.log('📊 Nombre d\'entrées stock:', response.data?.length || 0);
    console.log('✅ Succès:', response.success);
  }
  
  // Test GET /api/stock/:storeId
  console.log('🏪 Test récupération stock par magasin...');
  const req2 = createMockRequest(
    data.users.superAdmin, 
    { storeId: data.stores.store1._id.toString() }, 
    {}, 
    {}
  );
  const res2 = createMockResponse();
  
  await stockController.getStockByStore(req2, res2);
  
  if (res2.json.mock.calls.length > 0) {
    const response = res2.json.mock.calls[0][0];
    console.log('📊 Stock du magasin:', response.data?.length || 0, 'produits');
    console.log('✅ Succès:', response.success);
  }
  
  // Test POST /api/stock/adjust
  console.log('📝 Test ajustement stock...');
  const adjustment = {
    productId: data.products.product1._id.toString(),
    storeId: data.stores.store1._id.toString(),
    quantity: 10,
    type: 'add',
    reason: 'Réception commande',
    reference: 'CMD-001'
  };
  
  const req3 = createMockRequest(data.users.superAdmin, {}, adjustment, {});
  const res3 = createMockResponse();
  
  await stockController.adjustStock(req3, res3);
  
  if (res3.json.mock.calls.length > 0) {
    const response = res3.json.mock.calls[0][0];
    console.log('✅ Ajustement:', response.success);
    if (response.data) {
      console.log('📦 Nouvelle quantité:', response.data.quantity);
    }
  }
}

// Test principal
async function runControllerTests() {
  try {
    console.log('🚀 Démarrage des tests des contrôleurs...');
    
    // Connexion à MongoDB
    await mongoose.connect('mongodb://localhost:27017/invoicestock-test');
    console.log('🔗 Connecté à MongoDB');
    
    // Nettoyer la base
    await mongoose.connection.dropDatabase();
    console.log('🧹 Base de données nettoyée');
    
    // Créer les données de test
    const testData = await createTestData();
    console.log('✅ Données de test créées');
    
    // Tester les contrôleurs
    await testProductController(testData);
    await testStockController(testData);
    
    console.log('\n🎉 Tests des contrôleurs terminés !');
    
  } catch (error) {
    console.error('💥 Erreur lors des tests:', error);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Connexion fermée');
  }
}

// Mock de jest.fn pour les tests
global.jest = {
  fn: () => ({
    mock: {
      calls: [],
      returnThis: function() { return this; }
    },
    mockReturnThis: function() { return this; }
  })
};

// Exécuter les tests
runControllerTests(); 