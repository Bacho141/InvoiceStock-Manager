import mongoose from 'mongoose';

const stockSchema = new mongoose.Schema({
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
  quantity: { 
    type: Number, 
    default: 0,
    min: 0
  },
  reservedQuantity: { 
    type: Number, 
    default: 0,
    min: 0
  }, // Pour les commandes en cours
  lastUpdated: { 
    type: Date, 
    default: Date.now 
  },
  lastMovementId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'StockMovement'
  },
  minQuantity: {
    type: Number,
    default: 0,
    min: 0
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Index composé pour éviter les doublons et optimiser les recherches
stockSchema.index({ productId: 1, storeId: 1 }, { unique: true });
stockSchema.index({ storeId: 1, quantity: 1 });
stockSchema.index({ storeId: 1, lastUpdated: -1 });

// Virtual pour calculer la quantité disponible
stockSchema.virtual('availableQuantity').get(function() {
  return Math.max(0, this.quantity - this.reservedQuantity);
});

// Virtual pour vérifier si le stock est bas
stockSchema.virtual('isLowStock').get(function() {
  // Cette logique sera complétée avec les données du produit
  return this.quantity <= 5; // Valeur par défaut
});

// Virtual pour vérifier si le stock est épuisé
stockSchema.virtual('isOutOfStock').get(function() {
  return this.quantity <= 0;
});

// Méthode pour ajouter du stock
stockSchema.methods.addStock = function(quantity, reason = 'Ajout manuel') {
  if (quantity <= 0) {
    throw new Error('La quantité doit être positive');
  }
  
  this.quantity += quantity;
  this.lastUpdated = new Date();
  
  return this;
};

// Méthode pour retirer du stock
stockSchema.methods.removeStock = function(quantity, reason = 'Retrait manuel') {
  if (quantity <= 0) {
    throw new Error('La quantité doit être positive');
  }
  
  if (this.quantity < quantity) {
    throw new Error('Stock insuffisant');
  }
  
  this.quantity -= quantity;
  this.lastUpdated = new Date();
  
  return this;
};

// Méthode pour réserver du stock
stockSchema.methods.reserveStock = function(quantity) {
  if (quantity <= 0) {
    throw new Error('La quantité doit être positive');
  }
  
  if (this.availableQuantity < quantity) {
    throw new Error('Stock disponible insuffisant');
  }
  
  this.reservedQuantity += quantity;
  this.lastUpdated = new Date();
  
  return this;
};

// Méthode pour libérer du stock réservé
stockSchema.methods.releaseReservedStock = function(quantity) {
  if (quantity <= 0) {
    throw new Error('La quantité doit être positive');
  }
  
  if (this.reservedQuantity < quantity) {
    throw new Error('Stock réservé insuffisant');
  }
  
  this.reservedQuantity -= quantity;
  this.lastUpdated = new Date();
  
  return this;
};

// Méthode pour ajuster le stock
stockSchema.methods.adjustStock = function(newQuantity, reason = 'Ajustement manuel') {
  if (newQuantity < 0) {
    throw new Error('La quantité ne peut pas être négative');
  }
  
  this.quantity = newQuantity;
  this.lastUpdated = new Date();
  
  return this;
};

export default mongoose.model('Stock', stockSchema); 