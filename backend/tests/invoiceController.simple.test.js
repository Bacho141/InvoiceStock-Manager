// app/backend/tests/invoiceController.simple.test.js
import mongoose from 'mongoose';
import Invoice from '../src/models/Invoice.js';
import Client from '../src/models/Client.js';
import Store from '../src/models/Store.js';
import User from '../src/models/User.js';
import Product from '../src/models/Product.js';
import Stock from '../src/models/Stock.js';
import app from '../server.js';
import request from 'supertest';

const uniq = () => Math.random().toString(36).substring(2, 8);

async function main() {
  // Connexion à la base de test
  await mongoose.connect('mongodb://localhost:27017/invoicestock_test', { useNewUrlParser: true, useUnifiedTopology: true });

  // Nettoyage des collections
  await Promise.all([
    Invoice.deleteMany({}),
    Client.deleteMany({}),
    Store.deleteMany({}),
    User.deleteMany({}),
    Product.deleteMany({}),
    Stock.deleteMany({})
  ]);

  // Création d'un utilisateur
  const user = await User.create({
    username: 'testuser_' + uniq(),
    passwordHash: 'hash',
    role: 'gestionnaire',
    isActive: true
  });

  // Création d'un magasin
  const store = await Store.create({
    name: 'Test Store ' + uniq(),
    address: '123 rue test',
    createdBy: user._id
  });

  // Mise à jour de l'utilisateur avec le store assigné
  user.assignedStores = [store._id];
  await user.save();

  // Création d'un client
  const client = await Client.create({
    firstName: 'Jean',
    lastName: 'Test',
    phone: '06' + Math.floor(Math.random()*100000000),
    address: '1 rue test'
  });

  // Création d'un produit
  const product = await Product.create({
    name: 'Produit Test ' + uniq(),
    reference: 'REF' + uniq(),
    description: 'desc',
    purchasePrice: 10,
    sellingPrice: 20,
    createdBy: user._id
  });

  // Création du stock pour ce produit dans ce magasin
  await Stock.create({
    productId: product._id,
    storeId: store._id,
    quantity: 100
  });

  // Création d'une facture valide via l'API
  const invoiceData = {
    client: client._id,
    store: store._id,
    user: user._id,
    lines: [
      { product: product._id, productName: product.name, quantity: 2, unitPrice: 20, totalLine: 40 }
    ],
    total: 40,
    totalInWords: 'quarante',
    status: 'payee',
    format: 'A5'
  };
  let res = await request(app)
    .post('/api/invoices')
    .send(invoiceData)
    .expect(201);
  console.log('Création facture:', res.body);

  // Création sans client (doit échouer)
  res = await request(app)
    .post('/api/invoices')
    .send({ ...invoiceData, client: undefined })
    .expect(400);
  console.log('Erreur client manquant:', res.body);

  // Listing des factures
  res = await request(app)
    .get('/api/invoices')
    .expect(200);
  console.log('Liste factures:', res.body);

  // Détail d’une facture existante
  const invoiceId = res.body.data[0]._id;
  res = await request(app)
    .get(`/api/invoices/${invoiceId}`)
    .expect(200);
  console.log('Détail facture:', res.body);

  // Détail d’une facture inexistante
  res = await request(app)
    .get('/api/invoices/000000000000000000000000')
    .expect(404);
  console.log('Facture inexistante:', res.body);

  // Modification d’une facture
  res = await request(app)
    .put(`/api/invoices/${invoiceId}`)
    .send({ status: 'modifiee' })
    .expect(200);
  console.log('Modification facture:', res.body);

  // Annulation d’une facture
  res = await request(app)
    .delete(`/api/invoices/${invoiceId}`)
    .send({ reason: 'Erreur', userId: user._id })
    .expect(200);
  console.log('Annulation facture:', res.body);

  // Annulation d’une facture déjà annulée
  res = await request(app)
    .delete(`/api/invoices/${invoiceId}`)
    .send({ reason: 'Erreur', userId: user._id })
    .expect(400);
  console.log('Annulation déjà faite:', res.body);

  // Fermer la connexion mongoose
  await mongoose.connection.close();
}

main().catch(err => {
  console.error('Erreur dans le test:', err);
  mongoose.connection.close();
}); 