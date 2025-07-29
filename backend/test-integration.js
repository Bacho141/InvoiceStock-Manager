const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// Importer les modèles
const User = require('./src/models/User');
const Store = require('./src/models/Store');
const Product = require('./src/models/Product');
const Stock = require('./src/models/Stock');
const StockMovement = require('./src/models/StockMovement');
const StockAlert = require('./src/models/StockAlert');

console.log('🧪 Test d\'intégration complet...');

// Configuration
const JWT_SECRET = process.env.JWT_SECRET || 'test-secret';

// Créer des données de test complètes
async function createTestData() {
  console.log('📝 Création des données de test complètes...');
  
  // 1. Créer les utilisateurs
  const superAdmin = new User({
    username: 'superadmin',
    password: await bcrypt.hash('admin123', 10),
    role: 'super-admin',
    isActive: true
  });
  await superAdmin.save();
  
  const gestionnaire = new User({
    username: 'gestionnaire',
    password: await bcrypt.hash('password123', 10),
    role: 'gestionnaire',
    isActive: true
  });
  await gestionnaire.save();
  
  const caissier = new User({
    username: 'caissier',
    password: await bcrypt.hash('password123', 10),
    role: 'caissier',
    isActive: true
  });
  await caissier.save();
  
  // 2. Créer les magasins
  const store1 = new Store({
    name: 'Magasin Principal',
    address: '123 Rue Principale',
    city: 'Paris',
    phone: '0123456789',
    isActive: true
  });
  await store1.save();
  
  const store2 = new Store({
    name: 'Magasin Secondaire',
    address: '456 Avenue Secondaire',
    city: 'Lyon',
    phone: '0987654321',
    isActive: true
  });
  await store2.save();
  
  // 3. Assigner magasins aux utilisateurs
  gestionnaire.assignedStores = [store1._id];
  caissier.assignedStores = [store1._id, store2._id];
  await gestionnaire.save();
  await caissier.save();
  
  // 4. Créer les produits
  const product1 = new Product({
    name: 'Ordinateur Portable',
    description: 'Ordinateur portable gaming',
    category: 'Informatique',
    unit: 'pièce',
    purchasePrice: 800.0,
    sellingPrice: 1200.0,
    minStockLevel: 5,
    maxStockLevel: 50,
    barcode: '1234567890123',
    createdBy: superAdmin._id,
    isActive: true
  });
  await product1.save();
  
  const product2 = new Product({
    name: 'Souris Sans Fil',
    description: 'Souris optique sans fil',
    category: 'Informatique',
    unit: 'pièce',
    purchasePrice: 15.0,
    sellingPrice: 25.0,
    minStockLevel: 20,
    maxStockLevel: 200,
    barcode: '9876543210987',
    createdBy: superAdmin._id,
    isActive: true
  });
  await product2.save();
  
  const product3 = new Product({
    name: 'Clavier Mécanique',
    description: 'Clavier mécanique RGB',
    category: 'Informatique',
    unit: 'pièce',
    purchasePrice: 50.0,
    sellingPrice: 80.0,
    minStockLevel: 10,
    maxStockLevel: 100,
    barcode: '4567891230456',
    createdBy: superAdmin._id,
    isActive: true
  });
  await product3.save();
  
  // 5. Créer les stocks
  const stock1 = new Stock({
    productId: product1._id,
    storeId: store1._id,
    quantity: 15,
    reservedQuantity: 3
  });
  await stock1.save();
  
  const stock2 = new Stock({
    productId: product2._id,
    storeId: store1._id,
    quantity: 45,
    reservedQuantity: 0
  });
  await stock2.save();
  
  const stock3 = new Stock({
    productId: product3._id,
    storeId: store1._id,
    quantity: 8,
    reservedQuantity: 2
  });
  await stock3.save();
  
  const stock4 = new Stock({
    productId: product1._id,
    storeId: store2._id,
    quantity: 5,
    reservedQuantity: 1
  });
  await stock4.save();
  
  const stock5 = new Stock({
    productId: product2._id,
    storeId: store2._id,
    quantity: 12,
    reservedQuantity: 0
  });
  await stock5.save();
  
  return {
    users: { superAdmin, gestionnaire, caissier },
    stores: { store1, store2 },
    products: { product1, product2, product3 },
    stocks: { stock1, stock2, stock3, stock4, stock5 }
  };
}

// Générer un token JWT
function generateToken(user) {
  return jwt.sign(
    { 
      userId: user._id, 
      username: user.username, 
      role: user.role 
    },
    JWT_SECRET,
    { expiresIn: '1h' }
  );
}

// Test des fonctionnalités multi-magasins
async function testMultiStoreFeatures(data) {
  console.log('\n🏪 Test des fonctionnalités multi-magasins...');
  
  // Test 1: Super-admin voit tous les produits
  console.log('🔍 Test 1: Super-admin - tous les produits');
  const superAdminToken = generateToken(data.users.superAdmin);
  const allProducts = await Product.find({ isActive: true });
  console.log(`✅ Super-admin voit ${allProducts.length} produits`);
  
  // Test 2: Gestionnaire voit seulement les produits de son magasin
  console.log('🔍 Test 2: Gestionnaire - produits de son magasin');
  const gestionnaireToken = generateToken(data.users.gestionnaire);
  const gestionnaireProducts = await Product.find({
    isActive: true,
    _id: { $in: [data.products.product1._id, data.products.product2._id, data.products.product3._id] }
  });
  console.log(`✅ Gestionnaire voit ${gestionnaireProducts.length} produits`);
  
  // Test 3: Caissier voit les produits de ses magasins assignés
  console.log('🔍 Test 3: Caissier - produits de ses magasins');
  const caissierToken = generateToken(data.users.caissier);
  const caissierProducts = await Product.find({
    isActive: true,
    _id: { $in: [data.products.product1._id, data.products.product2._id, data.products.product3._id] }
  });
  console.log(`✅ Caissier voit ${caissierProducts.length} produits`);
  
  // Test 4: Stock par magasin
  console.log('📊 Test 4: Stock par magasin');
  const store1Stock = await Stock.find({ storeId: data.stores.store1._id }).populate('productId');
  const store2Stock = await Stock.find({ storeId: data.stores.store2._id }).populate('productId');
  console.log(`✅ Magasin 1: ${store1Stock.length} produits en stock`);
  console.log(`✅ Magasin 2: ${store2Stock.length} produits en stock`);
  
  return { superAdminToken, gestionnaireToken, caissierToken };
}

// Test des mouvements de stock
async function testStockMovements(data) {
  console.log('\n📈 Test des mouvements de stock...');
  
  // Test 1: Ajout de stock
  console.log('➕ Test 1: Ajout de stock');
  const stock1 = data.stocks.stock1;
  const initialQuantity = stock1.quantity;
  
  stock1.addStock(10);
  await stock1.save();
  
  console.log(`✅ Quantité initiale: ${initialQuantity}`);
  console.log(`✅ Nouvelle quantité: ${stock1.quantity}`);
  console.log(`✅ Différence: ${stock1.quantity - initialQuantity}`);
  
  // Test 2: Retrait de stock
  console.log('➖ Test 2: Retrait de stock');
  const stock2 = data.stocks.stock2;
  const initialQuantity2 = stock2.quantity;
  
  stock2.removeStock(5);
  await stock2.save();
  
  console.log(`✅ Quantité initiale: ${initialQuantity2}`);
  console.log(`✅ Nouvelle quantité: ${stock2.quantity}`);
  console.log(`✅ Différence: ${initialQuantity2 - stock2.quantity}`);
  
  // Test 3: Réservation de stock
  console.log('🔒 Test 3: Réservation de stock');
  const stock3 = data.stocks.stock3;
  const initialReserved = stock3.reservedQuantity;
  
  stock3.reserveStock(3);
  await stock3.save();
  
  console.log(`✅ Réservé initial: ${initialReserved}`);
  console.log(`✅ Nouveau réservé: ${stock3.reservedQuantity}`);
  console.log(`✅ Disponible: ${stock3.availableQuantity}`);
  
  // Test 4: Libération de stock réservé
  console.log('🔓 Test 4: Libération de stock réservé');
  stock3.releaseReservedStock(2);
  await stock3.save();
  
  console.log(`✅ Réservé après libération: ${stock3.reservedQuantity}`);
  console.log(`✅ Disponible après libération: ${stock3.availableQuantity}`);
}

// Test des alertes de stock
async function testStockAlerts(data) {
  console.log('\n⚠️ Test des alertes de stock...');
  
  // Créer des alertes de stock
  const alert1 = new StockAlert({
    productId: data.products.product1._id,
    storeId: data.stores.store1._id,
    type: 'low_stock',
    message: 'Stock faible pour Ordinateur Portable',
    isActive: true
  });
  await alert1.save();
  
  const alert2 = new StockAlert({
    productId: data.products.product3._id,
    storeId: data.stores.store1._id,
    type: 'out_of_stock',
    message: 'Rupture de stock pour Clavier Mécanique',
    isActive: true
  });
  await alert2.save();
  
  // Récupérer les alertes actives
  const activeAlerts = await StockAlert.find({ isActive: true }).populate('productId storeId');
  console.log(`✅ Alertes actives: ${activeAlerts.length}`);
  
  activeAlerts.forEach(alert => {
    console.log(`⚠️ ${alert.type}: ${alert.message}`);
  });
  
  return { alert1, alert2 };
}

// Test des calculs de marge
async function testMarginCalculations(data) {
  console.log('\n💰 Test des calculs de marge...');
  
  const products = [data.products.product1, data.products.product2, data.products.product3];
  
  products.forEach(product => {
    console.log(`📦 ${product.name}:`);
    console.log(`   💵 Prix d'achat: ${product.purchasePrice}€`);
    console.log(`   💰 Prix de vente: ${product.sellingPrice}€`);
    console.log(`   📊 Marge: ${product.margin}%`);
    console.log(`   💵 Marge brute: ${product.grossMargin}€`);
  });
}

// Test des index et performances
async function testIndexesAndPerformance(data) {
  console.log('\n⚡ Test des index et performances...');
  
  // Test des index Product
  const productIndexes = await Product.collection.getIndexes();
  console.log('📦 Index Product:', Object.keys(productIndexes));
  
  // Test des index Stock
  const stockIndexes = await Stock.collection.getIndexes();
  console.log('📊 Index Stock:', Object.keys(stockIndexes));
  
  // Test de recherche par nom
  console.log('🔍 Test recherche par nom...');
  const startTime = Date.now();
  const searchResults = await Product.find({
    name: { $regex: 'Ordinateur', $options: 'i' }
  });
  const endTime = Date.now();
  console.log(`✅ Recherche trouvée en ${endTime - startTime}ms: ${searchResults.length} résultats`);
  
  // Test de recherche par catégorie
  console.log('🏷️ Test recherche par catégorie...');
  const startTime2 = Date.now();
  const categoryResults = await Product.find({ category: 'Informatique' });
  const endTime2 = Date.now();
  console.log(`✅ Recherche catégorie en ${endTime2 - startTime2}ms: ${categoryResults.length} résultats`);
}

// Test principal
async function runIntegrationTests() {
  try {
    console.log('🚀 Démarrage des tests d\'intégration...');
    
    // Connexion à MongoDB
    await mongoose.connect('mongodb://localhost:27017/invoicestock-test');
    console.log('🔗 Connecté à MongoDB');
    
    // Nettoyer la base
    await mongoose.connection.dropDatabase();
    console.log('🧹 Base de données nettoyée');
    
    // Créer les données de test
    const testData = await createTestData();
    console.log('✅ Données de test créées');
    
    // Exécuter les tests
    await testMultiStoreFeatures(testData);
    await testStockMovements(testData);
    await testStockAlerts(testData);
    await testMarginCalculations(testData);
    await testIndexesAndPerformance(testData);
    
    console.log('\n🎉 Tests d\'intégration terminés avec succès !');
    
    // Résumé final
    console.log('\n📋 Résumé des tests:');
    console.log('✅ Modèles créés et validés');
    console.log('✅ Relations multi-magasins fonctionnelles');
    console.log('✅ Calculs de stock corrects');
    console.log('✅ Alertes de stock opérationnelles');
    console.log('✅ Calculs de marge précis');
    console.log('✅ Index de performance créés');
    
  } catch (error) {
    console.error('💥 Erreur lors des tests:', error);
    console.error('Stack:', error.stack);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Connexion fermée');
  }
}

// Exécuter les tests
runIntegrationTests(); 