const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

// Importer les modèles
const User = require('./src/models/User');
const Store = require('./src/models/Store');
const Product = require('./src/models/Product');
const Stock = require('./src/models/Stock');

console.log('🧪 Test d\'intégration simple...');

async function runSimpleTests() {
  try {
    console.log('🚀 Démarrage des tests...');
    
    // Connexion à MongoDB
    await mongoose.connect('mongodb://localhost:27017/invoicestock-test');
    console.log('🔗 Connecté à MongoDB');
    
    // Nettoyer la base
    await mongoose.connection.dropDatabase();
    console.log('🧹 Base de données nettoyée');
    
    // 1. Créer un utilisateur
    console.log('👤 Création utilisateur...');
    const user = new User({
      username: 'testuser',
      password: await bcrypt.hash('password123', 10),
      role: 'gestionnaire'
    });
    await user.save();
    console.log('✅ Utilisateur créé:', user.username);
    
    // 2. Créer un magasin
    console.log('🏪 Création magasin...');
    const store = new Store({
      name: 'Magasin Test',
      address: '123 Rue Test',
      city: 'Ville Test',
      phone: '0123456789'
    });
    await store.save();
    console.log('✅ Magasin créé:', store.name);
    
    // 3. Créer un produit
    console.log('📦 Création produit...');
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
    await product.save();
    console.log('✅ Produit créé:', product.name);
    console.log('💰 Marge:', product.margin + '%');
    
    // 4. Créer un stock
    console.log('📊 Création stock...');
    const stock = new Stock({
      productId: product._id,
      storeId: store._id,
      quantity: 50,
      reservedQuantity: 10
    });
    await stock.save();
    console.log('✅ Stock créé');
    console.log('📦 Quantité disponible:', stock.availableQuantity);
    
    // 5. Test des opérations de stock
    console.log('🧪 Test opérations stock...');
    stock.addStock(25);
    console.log('➕ Après ajout de 25:', stock.quantity);
    
    stock.removeStock(15);
    console.log('➖ Après retrait de 15:', stock.quantity);
    
    stock.reserveStock(20);
    console.log('🔒 Après réservation de 20:', stock.reservedQuantity);
    
    await stock.save();
    
    // 6. Vérifier les index
    console.log('📋 Vérification des index...');
    const productIndexes = await Product.collection.getIndexes();
    const stockIndexes = await Stock.collection.getIndexes();
    
    console.log('Product indexes:', Object.keys(productIndexes));
    console.log('Stock indexes:', Object.keys(stockIndexes));
    
    console.log('\n🎉 Tests terminés avec succès !');
    
  } catch (error) {
    console.error('💥 Erreur:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Connexion fermée');
  }
}

runSimpleTests(); 