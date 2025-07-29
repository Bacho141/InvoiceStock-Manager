import mongoose from 'mongoose';

const clientSchema = new mongoose.Schema({
  firstName: {
    type: String,
    required: true,
    trim: true,
  },
  lastName: {
    type: String,
    required: true,
    trim: true,
  },
  phone: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    index: true,
  },
  email: {
    type: String,
    unique: true,
    sparse: true,
    trim: true,
  },
  address: {
    type: String,
    trim: true,
  },
  purchaseHistory: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Invoice',
  }],
}, {
  timestamps: true,
});

export default mongoose.model('Client', clientSchema); 