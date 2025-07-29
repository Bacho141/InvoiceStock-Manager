import request from 'supertest';
import mongoose from 'mongoose';
import app from '../../server.js';
import Invoice from '../../src/models/Invoice.js';
import Client from '../../src/models/Client.js';
import Product from '../../src/models/Product.js';
import Store from '../../src/models/Store.js';
import Stock from '../../src/models/Stock.js';
import User from '../../src/models/User.js';

describe('Facturation - Invoice API', () => {
  let client, product, store, user, stock, invoiceId;

  beforeAll(async () => {
    // Nettoyer la base
    await Invoice.deleteMany({});
    await Client.deleteMany({});
    await Product.deleteMany({});
    await Store.deleteMany({});
    await Stock.deleteMany({});
    await User.deleteMany({});
    // Créer les entités nécessaires
    user = await User.create({ username: 'testuser', passwordHash: 'hash', role: 'caissier', isActive: true });
    store = await Store.create({ name: 'Magasin Test', address: 'Adresse', createdBy: user._id });
    product = await Product.create({ name: 'Produit Test', reference: 'REF1', description: 'desc', category: 'cat', unit: 'pièce', purchasePrice: 10, sellingPrice: 20, barcode: '123', isActive: true, createdBy: user._id });
    client = await Client.create({ firstName: 'Jean', lastName: 'Dupont', phone: '0600000000' });
    stock = await Stock.create({ productId: product._id, storeId: store._id, quantity: 100 });
  });

  afterAll(async () => {
    await mongoose.connection.close();
  });

  it('refuse la création de facture sans client', async () => {
    const res = await request(app)
      .post('/api/invoices')
      .send({ lines: [], store: store._id, user: user._id, total: 0, totalInWords: 'zéro', status: 'payee', format: 'A5' });
    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/client/);
  });

  it('crée une facture avec numérotation auto et décrémente le stock', async () => {
    const res = await request(app)
      .post('/api/invoices')
      .send({
        client: client._id,
        store: store._id,
        user: user._id,
        lines: [{ product: product._id, productName: product.name, quantity: 2, unitPrice: 20, discount: 0, totalLine: 40 }],
        total: 40,
        totalInWords: 'quarante',
        status: 'payee',
        format: 'A5',
      });
    expect(res.status).toBe(201);
    expect(res.body.data.number).toMatch(/^INV-\d{4}-\d{4}$/);
    invoiceId = res.body.data._id;
    const stockAfter = await Stock.findOne({ productId: product._id, storeId: store._id });
    expect(stockAfter.quantity).toBe(98);
  });

  it('récupère la liste des factures', async () => {
    const res = await request(app).get('/api/invoices');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThan(0);
  });

  it('récupère le détail d’une facture', async () => {
    const res = await request(app).get(`/api/invoices/${invoiceId}`);
    expect(res.status).toBe(200);
    expect(res.body.data._id).toBe(invoiceId);
  });

  it('met une facture en attente', async () => {
    const res = await request(app)
      .post(`/api/invoices/${invoiceId}/wait`)
      .send({ userId: user._id });
    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('en_attente');
  });

  it('annule une facture, restocke et historise', async () => {
    const res = await request(app)
      .delete(`/api/invoices/${invoiceId}`)
      .send({ reason: 'Erreur', userId: user._id });
    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('annulee');
    const stockAfter = await Stock.findOne({ productId: product._id, storeId: store._id });
    expect(stockAfter.quantity).toBe(100);
    expect(res.body.data.history.some(h => h.action === 'cancelled')).toBe(true);
  });

  it('refuse la double annulation', async () => {
    const res = await request(app)
      .delete(`/api/invoices/${invoiceId}`)
      .send({ reason: 'Encore', userId: user._id });
    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/déjà annulée/);
  });

  it('gère le cas stock inexistant (création)', async () => {
    const fakeProduct = await Product.create({ name: 'Fake', reference: 'FAKE', description: 'desc', category: 'cat', unit: 'pièce', purchasePrice: 5, sellingPrice: 10, barcode: '999', isActive: true, createdBy: user._id });
    const res = await request(app)
      .post('/api/invoices')
      .send({
        client: client._id,
        store: store._id,
        user: user._id,
        lines: [{ product: fakeProduct._id, productName: 'Fake', quantity: 1, unitPrice: 10, discount: 0, totalLine: 10 }],
        total: 10,
        totalInWords: 'dix',
        status: 'payee',
        format: 'POS',
      });
    expect(res.status).toBe(201);
    // Stock inexistant : pas d’erreur bloquante, log warning
  });
}); 