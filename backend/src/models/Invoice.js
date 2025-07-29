import mongoose from 'mongoose';
import invoiceLineSchema from './InvoiceLine.js';

const invoiceHistorySchema = new mongoose.Schema({
  action: { type: String, required: true }, // 'created', 'cancelled', 'updated', etc.
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  date: { type: Date, default: Date.now },
  reason: { type: String },
}, { _id: false });

const invoiceSchema = new mongoose.Schema({
  number: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  date: {
    type: Date,
    required: true,
    default: Date.now,
  },
  client: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Client',
    required: true,
  },
  store: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Store',
    required: true,
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  lines: {
    type: [invoiceLineSchema],
    required: true,
    validate: v => Array.isArray(v) && v.length > 0,
  },
  total: {
    type: Number,
    required: true,
    min: 0,
  },
  montantPaye: {
    type: Number,
    default: 0,
    min: 0,
  },
  totalInWords: {
    type: String,
    required: true,
    trim: true,
  },
  discountTotal: {
    type: Number,
    default: 0,
    min: 0,
  },
  status: {
    type: String,
    enum: ['payee', 'reste_a_payer', 'annulee', 'en_attente'],
    required: true,
  },
  format: {
    type: String,
    enum: ['A5', 'POS'],
    required: true,
  },
  history: [invoiceHistorySchema],
  cancelledBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  cancelReason: {
    type: String,
    trim: true,
  },
  cancelledAt: {
    type: Date,
  },
}, {
  timestamps: true,
});

export default mongoose.model('Invoice', invoiceSchema); 