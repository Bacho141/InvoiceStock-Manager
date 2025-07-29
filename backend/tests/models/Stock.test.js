const Stock = require('../../src/models/Stock');
const { createTestUser, createTestStore, createTestProduct } = require('../utils/testHelpers');

describe('Stock Model', () => {
  let testUser, testStore, testProduct;

  beforeEach(async () => {
    testUser = await createTestUser();
    testStore = await createTestStore();
    testProduct = await createTestProduct({}, testUser._id);
  });

  describe('Validation', () => {
    it('should create a valid stock', async () => {
      const stockData = {
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50,
        reservedQuantity: 5
      };

      const stock = new Stock(stockData);
      const savedStock = await stock.save();

      expect(savedStock.productId.toString()).toBe(testProduct._id.toString());
      expect(savedStock.storeId.toString()).toBe(testStore._id.toString());
      expect(savedStock.quantity).toBe(50);
      expect(savedStock.reservedQuantity).toBe(5);
    });

    it('should require productId', async () => {
      const stockData = {
        storeId: testStore._id,
        quantity: 50
      };

      const stock = new Stock(stockData);
      let err;
      try {
        await stock.save();
      } catch (error) {
        err = error;
      }
      expect(err).toBeDefined();
      expect(err.errors.productId).toBeDefined();
    });

    it('should require storeId', async () => {
      const stockData = {
        productId: testProduct._id,
        quantity: 50
      };

      const stock = new Stock(stockData);
      let err;
      try {
        await stock.save();
      } catch (error) {
        err = error;
      }
      expect(err).toBeDefined();
      expect(err.errors.storeId).toBeDefined();
    });

    it('should not allow negative quantity', async () => {
      const stockData = {
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: -10
      };

      const stock = new Stock(stockData);
      let err;
      try {
        await stock.save();
      } catch (error) {
        err = error;
      }
      expect(err).toBeDefined();
      expect(err.errors.quantity).toBeDefined();
    });

    it('should not allow negative reservedQuantity', async () => {
      const stockData = {
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50,
        reservedQuantity: -5
      };

      const stock = new Stock(stockData);
      let err;
      try {
        await stock.save();
      } catch (error) {
        err = error;
      }
      expect(err).toBeDefined();
      expect(err.errors.reservedQuantity).toBeDefined();
    });
  });

  describe('Virtuals', () => {
    it('should calculate availableQuantity correctly', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50,
        reservedQuantity: 10
      });

      expect(stock.availableQuantity).toBe(40); // 50 - 10
    });

    it('should handle zero reserved quantity', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50,
        reservedQuantity: 0
      });

      expect(stock.availableQuantity).toBe(50);
    });

    it('should handle reserved quantity greater than total', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 10,
        reservedQuantity: 15
      });

      expect(stock.availableQuantity).toBe(0); // Math.max(0, 10-15)
    });

    it('should detect low stock', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 3
      });

      expect(stock.isLowStock).toBe(true);
    });

    it('should detect out of stock', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 0
      });

      expect(stock.isOutOfStock).toBe(true);
    });
  });

  describe('Methods', () => {
    it('should add stock correctly', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50
      });

      stock.addStock(25);
      expect(stock.quantity).toBe(75);
    });

    it('should remove stock correctly', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50
      });

      stock.removeStock(20);
      expect(stock.quantity).toBe(30);
    });

    it('should throw error when removing more than available', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50
      });

      expect(() => stock.removeStock(60)).toThrow('Stock insuffisant');
    });

    it('should reserve stock correctly', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50,
        reservedQuantity: 10
      });

      stock.reserveStock(15);
      expect(stock.reservedQuantity).toBe(25);
    });

    it('should throw error when reserving more than available', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50,
        reservedQuantity: 10
      });

      expect(() => stock.reserveStock(50)).toThrow('Stock disponible insuffisant');
    });

    it('should release reserved stock correctly', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50,
        reservedQuantity: 20
      });

      stock.releaseReservedStock(10);
      expect(stock.reservedQuantity).toBe(10);
    });

    it('should throw error when releasing more than reserved', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50,
        reservedQuantity: 10
      });

      expect(() => stock.releaseReservedStock(15)).toThrow('Stock réservé insuffisant');
    });

    it('should adjust stock correctly', async () => {
      const stock = new Stock({
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50
      });

      stock.adjustStock(75);
      expect(stock.quantity).toBe(75);
    });
  });

  describe('Indexes', () => {
    it('should create unique compound index on productId and storeId', async () => {
      const indexes = await Stock.collection.getIndexes();
      
      expect(indexes).toHaveProperty('productId_1_storeId_1');
      expect(indexes['productId_1_storeId_1'].unique).toBe(true);
    });

    it('should prevent duplicate product-store combinations', async () => {
      const stockData = {
        productId: testProduct._id,
        storeId: testStore._id,
        quantity: 50
      };

      await new Stock(stockData).save();

      const duplicateStock = new Stock(stockData);
      let err;
      try {
        await duplicateStock.save();
      } catch (error) {
        err = error;
      }
      expect(err).toBeDefined();
      expect(err.code).toBe(11000); // Duplicate key error
    });
  });
}); 