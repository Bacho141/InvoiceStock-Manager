import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import connectDB from './src/config/db.js';
import userRoutes from './src/routes/userRoutes.js';
import authRoutes from './src/routes/authRoutes.js';
import storeRoutes from './src/routes/storeRoutes.js';
import productRoutes from './src/routes/productRoutes.js';
import stockRoutes from './src/routes/stockRoutes.js';
import clientRoutes from './src/routes/clientRoutes.js';
import invoiceRoutes from './src/routes/invoiceRoutes.js';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 5050;

connectDB();

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'InvoiceStock backend is running.' });
});

app.use('/api/users', userRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/stores', storeRoutes);
app.use('/api/stocks', stockRoutes);
app.use('/api/clients', clientRoutes);
app.use('/api/invoices', invoiceRoutes);

console.log('[SERVER] Toutes les routes montées avec succès');

app.listen(PORT, () => {
  console.log(`[SERVER] Serveur démarré sur le port ${PORT}`);
});

export default app; 