const mongoose = require('mongoose');
const Product = require('./src/models/Product');
const Stock = require('./src/models/Stock');
const Store = require('./src/models/Store');
const User = require('./src/models/User');

console.log('🧪 Test de configuration des modèles...');

// Test de création d'un produit
async function testProduct() {
  try {
    console.log('📦 Test du modèle Product...');
    
    // Créer un utilisateur de test
    const user = new User({
      username: 'testuser',
      password: 'password123',
      role: 'gestionnaire'
    });
    await user.save();
    
    // Créer un produit
    const product = new Product({
      name: 'Produit Test',
      description: 'Description test',
      category: 'Test',
      unit: 'pièce',
      purchasePrice: 10.0,
      sellingPrice: 15.0,
      minStockLevel: 5,
      maxStockLevel: 100,
      createdBy: user._id
    });
    
    const savedProduct = await product.save();
    console.log('✅ Produit créé:', savedProduct.name);
    console.log('💰 Marge:', savedProduct.margin + '%');
    console.log('💵 Marge brute:', savedProduct.grossMargin + '€');
    
    return { user, product: savedProduct };
  } catch (error) {
    console.error('❌ Erreur Product:', error.message);
    throw error;
  }
}

// Test de création d'un magasin
async function testStore() {
  try {
    console.log('🏪 Test du modèle Store...');
    
    const store = new Store({
      name: 'Magasin Test',
      address: '123 Rue Test',
      city: 'Ville Test',
      phone: '0123456789'
    });
    
    const savedStore = await store.save();
    console.log('✅ Magasin créé:', savedStore.name);
    
    return savedStore;
  } catch (error) {
    console.error('❌ Erreur Store:', error.message);
    throw error;
  }
}

// Test de création d'un stock
async function testStock(user, product, store) {
  try {
    console.log('📊 Test du modèle Stock...');
    
    const stock = new Stock({
      productId: product._id,
      storeId: store._id,
      quantity: 50,
      reservedQuantity: 10
    });
    
    const savedStock = await stock.save();
    console.log('✅ Stock créé');
    console.log('📦 Quantité totale:', savedStock.quantity);
    console.log('🔒 Quantité réservée:', savedStock.reservedQuantity);
    console.log('✅ Quantité disponible:', savedStock.availableQuantity);
    console.log('⚠️ Stock faible:', savedStock.isLowStock);
    console.log('❌ Rupture:', savedStock.isOutOfStock);
    
    // Test des méthodes
    console.log('🧪 Test des méthodes...');
    savedStock.addStock(25);
    console.log('➕ Après ajout de 25:', savedStock.quantity);
    
    savedStock.removeStock(15);
    console.log('➖ Après retrait de 15:', savedStock.quantity);
    
    savedStock.reserveStock(20);
    console.log('🔒 Après réservation de 20:', savedStock.reservedQuantity);
    
    return savedStock;
  } catch (error) {
    console.error('❌ Erreur Stock:', error.message);
    throw error;
  }
}

// Test principal
async function runTests() {
  try {
    console.log('🚀 Démarrage des tests...');
    
    // Connexion à MongoDB
    await mongoose.connect('mongodb://localhost:27017/invoicestock-test');
    console.log('🔗 Connecté à MongoDB');
    
    // Nettoyer la base
    await mongoose.connection.dropDatabase();
    console.log('🧹 Base de données nettoyée');
    
    // Exécuter les tests
    const user = await testProduct();
    const store = await testStore();
    const stock = await testStock(user.user, user.product, store);
    
    console.log('🎉 Tous les tests réussis !');
    
    // Afficher les index
    console.log('\n📋 Index créés:');
    const productIndexes = await Product.collection.getIndexes();
    console.log('Product indexes:', Object.keys(productIndexes));
    
    const stockIndexes = await Stock.collection.getIndexes();
    console.log('Stock indexes:', Object.keys(stockIndexes));
    
  } catch (error) {
    console.error('💥 Erreur lors des tests:', error);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Connexion fermée');
  }
}

// Exécuter les tests
runTests(); 