import mongoose from 'mongoose';

const stockMovementSchema = new mongoose.Schema({
  productId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Product', 
    required: true 
  },
  storeId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Store', 
    required: true 
  },
  type: { 
    type: String, 
    enum: ['IN', 'OUT', 'ADJUSTMENT', 'TRANSFER_IN', 'TRANSFER_OUT', 'RESERVATION', 'RELEASE'], 
    required: true 
  },
  quantity: { 
    type: Number, 
    required: true 
  },
  previousQuantity: { 
    type: Number, 
    required: true 
  },
  newQuantity: { 
    type: Number, 
    required: true 
  },
  previousReservedQuantity: { 
    type: Number, 
    default: 0 
  },
  newReservedQuantity: { 
    type: Number, 
    default: 0 
  },
  reason: { 
    type: String, 
    trim: true,
    maxlength: 200
  },
  reference: { 
    type: String, 
    trim: true,
    maxlength: 100
  }, // Numéro de facture, bon de commande, etc.
  referenceType: {
    type: String,
    enum: ['INVOICE', 'PURCHASE_ORDER', 'TRANSFER', 'ADJUSTMENT', 'MANUAL'],
    default: 'MANUAL'
  },
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  notes: { 
    type: String, 
    trim: true,
    maxlength: 500
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  },
  stockAvant: {
    type: Number,
    required: false
  },
  stockApres: {
    type: Number,
    required: false
  },
  user: {
    _id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: false },
    username: { type: String },
    role: { type: String }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Index pour optimiser les recherches
stockMovementSchema.index({ productId: 1, storeId: 1, createdAt: -1 });
stockMovementSchema.index({ storeId: 1, type: 1, createdAt: -1 });
stockMovementSchema.index({ userId: 1, createdAt: -1 });
stockMovementSchema.index({ reference: 1, referenceType: 1 });
stockMovementSchema.index({ createdAt: -1 });

// Virtual pour calculer la variation de stock
stockMovementSchema.virtual('stockVariation').get(function() {
  return this.newQuantity - this.previousQuantity;
});

// Virtual pour calculer la variation de stock réservé
stockMovementSchema.virtual('reservedVariation').get(function() {
  return this.newReservedQuantity - this.previousReservedQuantity;
});

// Virtual pour obtenir le type d'affichage
stockMovementSchema.virtual('displayType').get(function() {
  const typeLabels = {
    'IN': 'Entrée',
    'OUT': 'Sortie',
    'ADJUSTMENT': 'Ajustement',
    'TRANSFER_IN': 'Transfert entrant',
    'TRANSFER_OUT': 'Transfert sortant',
    'RESERVATION': 'Réservation',
    'RELEASE': 'Libération'
  };
  return typeLabels[this.type] || this.type;
});

// Virtual pour obtenir la couleur selon le type
stockMovementSchema.virtual('typeColor').get(function() {
  const colorMap = {
    'IN': 'green',
    'OUT': 'red',
    'ADJUSTMENT': 'orange',
    'TRANSFER_IN': 'blue',
    'TRANSFER_OUT': 'purple',
    'RESERVATION': 'yellow',
    'RELEASE': 'cyan'
  };
  return colorMap[this.type] || 'gray';
});

// Méthode statique pour créer un mouvement d'entrée
stockMovementSchema.statics.createInMovement = function(data) {
  return new this({
    ...data,
    type: 'IN',
    newQuantity: data.previousQuantity + data.quantity
  });
};

// Méthode statique pour créer un mouvement de sortie
stockMovementSchema.statics.createOutMovement = function(data) {
  return new this({
    ...data,
    type: 'OUT',
    newQuantity: data.previousQuantity - data.quantity
  });
};

// Méthode statique pour créer un mouvement d'ajustement
stockMovementSchema.statics.createAdjustmentMovement = function(data) {
  return new this({
    ...data,
    type: 'ADJUSTMENT',
    newQuantity: data.quantity // Dans ce cas, quantity = nouvelle quantité
  });
};

// Méthode statique pour créer un mouvement de réservation
stockMovementSchema.statics.createReservationMovement = function(data) {
  return new this({
    ...data,
    type: 'RESERVATION',
    newReservedQuantity: data.previousReservedQuantity + data.quantity
  });
};

// Méthode statique pour créer un mouvement de libération
stockMovementSchema.statics.createReleaseMovement = function(data) {
  return new this({
    ...data,
    type: 'RELEASE',
    newReservedQuantity: data.previousReservedQuantity - data.quantity
  });
};

export default mongoose.model('StockMovement', stockMovementSchema); 