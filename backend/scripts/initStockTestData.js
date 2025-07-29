// Script d'initialisation des stocks et mouvements pour tests
import mongoose from 'mongoose';
import fs from 'fs';
import path from 'path';
import Product from '../src/models/Product.js';
import Store from '../src/models/Store.js';
import Stock from '../src/models/Stock.js';
import StockMovement from '../src/models/StockMovement.js';
import User from '../src/models/User.js';
import dotenv from 'dotenv';

dotenv.config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/invoice_stock_manager';
const SUPER_ADMIN_ID = '686a7dfbb2c9b6b488f4d378';

const productsFile = path.resolve('..', 'invoice_stock_manager.products.json');
const storesFile = path.resolve('..', 'store.json');

async function main() {
  await mongoose.connect(MONGO_URI);
  console.log('Connecté à MongoDB');

  // Charger produits et magasins
  const products = JSON.parse(fs.readFileSync(productsFile, 'utf-8'));
  const stores = JSON.parse(fs.readFileSync(storesFile, 'utf-8'));

  // Créer les stocks pour chaque produit dans chaque magasin
  for (const store of stores) {
    for (const product of products) {
      const stock = await Stock.findOne({
        productId: product._id.$oid,
        storeId: store._id.$oid
      });
      if (!stock) {
        const quantity = Math.floor(Math.random() * 50) + 5; // Quantité aléatoire
        const minQuantity = product.minStockLevel || 5;
        const newStock = await Stock.create({
          productId: product._id.$oid,
          storeId: store._id.$oid,
          quantity,
          minQuantity,
          isActive: true,
          lastUpdated: new Date()
        });
        console.log(`Stock créé pour ${product.name} (${store.name}) : ${quantity}`);
        // Créer 2-3 mouvements pour chaque stock
        let prevQ = quantity;
        for (let i = 0; i < 3; i++) {
          const type = i === 0 ? 'IN' : (i === 1 ? 'OUT' : 'ADJUSTMENT');
          let q = 0;
          let newQ = prevQ;
          if (type === 'IN') {
            q = Math.floor(Math.random() * 10) + 1;
            newQ = prevQ + q;
          } else if (type === 'OUT') {
            q = Math.floor(Math.random() * Math.min(10, prevQ)) + 1;
            newQ = prevQ - q;
          } else if (type === 'ADJUSTMENT') {
            q = Math.floor(Math.random() * 50) + 1;
            newQ = q;
          }
          await StockMovement.create({
            productId: product._id.$oid,
            storeId: store._id.$oid,
            type,
            quantity: q,
            previousQuantity: prevQ,
            newQuantity: newQ,
            userId: SUPER_ADMIN_ID,
            reason: type === 'IN' ? 'Réception fournisseur' : (type === 'OUT' ? 'Vente' : 'Ajustement inventaire'),
            createdAt: new Date(Date.now() - (i * 86400000)),
          });
          prevQ = newQ;
        }
      }
    }
  }
  console.log('Stocks et mouvements générés !');
  await mongoose.disconnect();
}

main().catch(e => {
  console.error(e);
  process.exit(1);
}); 