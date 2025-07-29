const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

let mongod;

// Configuration globale pour les tests
beforeAll(async () => {
  console.log('[TEST] Démarrage de MongoDB en mémoire');
  mongod = await MongoMemoryServer.create();
  const uri = mongod.getUri();
  await mongoose.connect(uri);
});

// Nettoyage après chaque test
afterEach(async () => {
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    const collection = collections[key];
    await collection.deleteMany();
  }
});

// Fermeture après tous les tests
afterAll(async () => {
  console.log('[TEST] Fermeture de MongoDB en mémoire');
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
  await mongod.stop();
});

// Configuration globale pour les tests
global.testTimeout = 30000; 