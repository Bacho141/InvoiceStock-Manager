const Product = require('../../src/models/Product');
const { createTestUser } = require('../utils/testHelpers');

describe('Product Model', () => {
  let testUser;

  beforeEach(async () => {
    testUser = await createTestUser();
  });

  describe('Validation', () => {
    it('should create a valid product', async () => {
      const productData = {
        name: 'Test Product',
        description: 'Test Description',
        category: 'Test Category',
        unit: 'pièce',
        purchasePrice: 10.0,
        sellingPrice: 15.0,
        minStockLevel: 5,
        maxStockLevel: 100,
        createdBy: testUser._id
      };

      const product = new Product(productData);
      const savedProduct = await product.save();

      expect(savedProduct.name).toBe(productData.name);
      expect(savedProduct.purchasePrice).toBe(productData.purchasePrice);
      expect(savedProduct.sellingPrice).toBe(productData.sellingPrice);
      expect(savedProduct.isActive).toBe(true);
    });

    it('should require name', async () => {
      const productData = {
        purchasePrice: 10.0,
        sellingPrice: 15.0,
        createdBy: testUser._id
      };

      const product = new Product(productData);
      let err;
      try {
        await product.save();
      } catch (error) {
        err = error;
      }
      expect(err).toBeDefined();
      expect(err.errors.name).toBeDefined();
    });

    it('should require purchasePrice', async () => {
      const productData = {
        name: 'Test Product',
        sellingPrice: 15.0,
        createdBy: testUser._id
      };

      const product = new Product(productData);
      let err;
      try {
        await product.save();
      } catch (error) {
        err = error;
      }
      expect(err).toBeDefined();
      expect(err.errors.purchasePrice).toBeDefined();
    });

    it('should require sellingPrice', async () => {
      const productData = {
        name: 'Test Product',
        purchasePrice: 10.0,
        createdBy: testUser._id
      };

      const product = new Product(productData);
      let err;
      try {
        await product.save();
      } catch (error) {
        err = error;
      }
      expect(err).toBeDefined();
      expect(err.errors.sellingPrice).toBeDefined();
    });

    it('should validate sellingPrice >= purchasePrice', async () => {
      const productData = {
        name: 'Test Product',
        purchasePrice: 15.0,
        sellingPrice: 10.0, // Plus bas que purchasePrice
        createdBy: testUser._id
      };

      const product = new Product(productData);
      let err;
      try {
        await product.save();
      } catch (error) {
        err = error;
      }
      expect(err).toBeDefined();
      expect(err.message).toContain('Le prix de vente ne peut pas être inférieur au prix d\'achat');
    });

    it('should validate unit enum values', async () => {
      const productData = {
        name: 'Test Product',
        purchasePrice: 10.0,
        sellingPrice: 15.0,
        unit: 'invalid_unit',
        createdBy: testUser._id
      };

      const product = new Product(productData);
      let err;
      try {
        await product.save();
      } catch (error) {
        err = error;
      }
      expect(err).toBeDefined();
      expect(err.errors.unit).toBeDefined();
    });
  });

  describe('Virtuals', () => {
    it('should calculate margin correctly', async () => {
      const product = new Product({
        name: 'Test Product',
        purchasePrice: 10.0,
        sellingPrice: 15.0,
        createdBy: testUser._id
      });

      expect(product.margin).toBe(50); // (15-10)/10 * 100
    });

    it('should calculate gross margin correctly', async () => {
      const product = new Product({
        name: 'Test Product',
        purchasePrice: 10.0,
        sellingPrice: 15.0,
        createdBy: testUser._id
      });

      expect(product.grossMargin).toBe(5); // 15-10
    });

    it('should handle zero purchase price', async () => {
      const product = new Product({
        name: 'Test Product',
        purchasePrice: 0,
        sellingPrice: 15.0,
        createdBy: testUser._id
      });

      expect(product.margin).toBe(0);
    });
  });

  describe('Methods', () => {
    it('should validate prices correctly', async () => {
      const product = new Product({
        name: 'Test Product',
        purchasePrice: 10.0,
        sellingPrice: 15.0,
        createdBy: testUser._id
      });

      expect(product.validatePrices()).toBe(true);
    });

    it('should throw error for invalid prices', async () => {
      const product = new Product({
        name: 'Test Product',
        purchasePrice: 15.0,
        sellingPrice: 10.0,
        createdBy: testUser._id
      });

      expect(() => product.validatePrices()).toThrow('Le prix de vente ne peut pas être inférieur au prix d\'achat');
    });
  });

  describe('Indexes', () => {
    it('should create indexes', async () => {
      const indexes = await Product.collection.getIndexes();
      
      expect(indexes).toHaveProperty('name_1');
      expect(indexes).toHaveProperty('category_1');
      expect(indexes).toHaveProperty('barcode_1');
      expect(indexes).toHaveProperty('isActive_1');
      expect(indexes).toHaveProperty('createdAt_-1');
    });
  });
}); 