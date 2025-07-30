import mongoose from 'mongoose';

const AuditLogSchema = new mongoose.Schema({
  event: { type: String, required: true }, // ex: 'INVOICE_ROLLBACK', 'INVOICE_CANCEL', 'STOCK_ERROR'
  invoiceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Invoice' },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  storeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Store' },
  details: { type: Object }, // Détail libre (produit, quantité, message...)
  message: { type: String },
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model('AuditLog', AuditLogSchema);
