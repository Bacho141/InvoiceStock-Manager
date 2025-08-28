import dotenv from 'dotenv';
import mongoose from 'mongoose';
import request from 'supertest';
import bcrypt from 'bcrypt';
import app from '../server.js';
import connectDB from '../src/config/db.js';
import User from '../src/models/User.js';
import Client from '../src/models/Client.js';
import Invoice from '../src/models/Invoice.js';

// Charger les variables d'environnement
dotenv.config();

/**
 * Script de test pour les nouvelles APIs clients et créances
 * Tests selon le plan Sprint 1
 */

let authToken = null;
let testUserId = null;
let testClientId = null;

// Configuration des données de test
const testPassword = 'test123';
const testUser = {
  username: 'test_analytics_' + Date.now(),
  role: 'super-admin',
  isActive: true
};

const testClient = {
  firstName: 'Test',
  lastName: 'Analytics',
  phone: '+227900000' + Math.floor(Math.random() * 1000),
  email: 'test.analytics@test.com',
  company: 'Test Company',
  customerType: 'entreprise',
  category: 'grossiste',
  creditLimit: 50000,
  paymentTerms: 30
};

async function setupTestData() {
  try {
    console.log('[TEST] Configuration des données de test...');
    
    await connectDB();
    
    // Hasher le mot de passe avant de créer l'utilisateur
    const hashedPassword = await bcrypt.hash(testPassword, 10);
    
    // Créer un utilisateur de test
    const user = await User.create({
      ...testUser,
      passwordHash: hashedPassword
    });
    testUserId = user._id;
    console.log('[TEST] Utilisateur de test créé:', user.username);
    
    // Obtenir un token d'authentification
    const loginResponse = await request(app)
      .post('/api/auth/login')
      .send({
        username: testUser.username,
        password: testPassword
      });
    
    if (loginResponse.status !== 200) {
      throw new Error('Échec de l\'authentification');
    }
    
    authToken = loginResponse.body.token;
    console.log("[TEST] Token d\\'authentification obtenu");
    
    // Créer un client de test
    const clientResponse = await request(app)
      .post('/api/clients')
      .set('Authorization', `Bearer ${authToken}`)
      .send(testClient);
    
    if (clientResponse.status !== 201) {
      throw new Error('Échec de création du client de test');
    }
    
    testClientId = clientResponse.body.data._id;
    console.log('[TEST] Client de test créé:', testClientId);
    
    // Créer quelques factures de test
    const invoiceData = {
      client: testClientId,
      total: 25000,
      montantPaye: 15000,
      status: 'reste_a_payer',
      lines: [{
        productName: 'Produit Test',
        quantity: 1,
        unitPrice: 25000,
        total: 25000
      }]
    };
    
    // Simuler la création directe en base (normalement via l'API factures)
    await Invoice.create({
      ...invoiceData,
      number: 'INV-TEST-001',
      date: new Date(),
      user: testUserId,
      store: new mongoose.Types.ObjectId(),
      totalInWords: 'Vingt-cinq mille francs',
      format: 'A5',
      history: []
    });
    
    console.log('[TEST] Facture de test créée');
    
  } catch (error) {
    console.error('[TEST] Erreur setup:', error);
    throw error;
  }
}

async function testDashboardMetrics() {
  console.log('\n[TEST] Test Dashboard Metrics...');
  
  const response = await request(app)
    .get('/api/clients/analytics/dashboard')
    .set('Authorization', `Bearer ${authToken}`);
  
  console.log('[TEST] Status:', response.status);
  console.log('[TEST] Response:', JSON.stringify(response.body, null, 2));
  
  if (response.status === 200) {
    console.log('[TEST] ✅ Dashboard Metrics - OK');
    return true;
  } else {
    console.log('[TEST] ❌ Dashboard Metrics - FAILED');
    return false;
  }
}

async function testTopClients() {
  console.log('\n[TEST] Test Top Clients...');
  
  const response = await request(app)
    .get('/api/clients/analytics/top-clients?limit=5')
    .set('Authorization', `Bearer ${authToken}`);
  
  console.log('[TEST] Status:', response.status);
  console.log('[TEST] Response:', JSON.stringify(response.body, null, 2));
  
  if (response.status === 200) {
    console.log('[TEST] ✅ Top Clients - OK');
    return true;
  } else {
    console.log('[TEST] ❌ Top Clients - FAILED');
    return false;
  }
}

async function testCreancesAnalysis() {
  console.log('\n[TEST] Test Créances Analysis...');
  
  const response = await request(app)
    .get('/api/clients/analytics/creances')
    .set('Authorization', `Bearer ${authToken}`);
  
  console.log('[TEST] Status:', response.status);
  console.log('[TEST] Response:', JSON.stringify(response.body, null, 2));
  
  if (response.status === 200) {
    console.log('[TEST] ✅ Créances Analysis - OK');
    return true;
  } else {
    console.log('[TEST] ❌ Créances Analysis - FAILED');
    return false;
  }
}

async function testClientStats() {
  console.log('\n[TEST] Test Client Stats...');
  
  const response = await request(app)
    .get(`/api/clients/${testClientId}/stats`)
    .set('Authorization', `Bearer ${authToken}`);
  
  console.log('[TEST] Status:', response.status);
  console.log('[TEST] Response:', JSON.stringify(response.body, null, 2));
  
  if (response.status === 200) {
    console.log('[TEST] ✅ Client Stats - OK');
    return true;
  } else {
    console.log('[TEST] ❌ Client Stats - FAILED');
    return false;
  }
}

async function testOverdueClients() {
  console.log('\n[TEST] Test Overdue Clients...');
  
  const response = await request(app)
    .get('/api/clients/analytics/overdue?days=30')
    .set('Authorization', `Bearer ${authToken}`);
  
  console.log('[TEST] Status:', response.status);
  console.log('[TEST] Response:', JSON.stringify(response.body, null, 2));
  
  if (response.status === 200) {
    console.log('[TEST] ✅ Overdue Clients - OK');
    return true;
  } else {
    console.log('[TEST] ❌ Overdue Clients - FAILED');
    return false;
  }
}

async function testClientEvolution() {
  console.log('\n[TEST] Test Client Evolution...');
  
  const response = await request(app)
    .get(`/api/clients/${testClientId}/evolution?months=6`)
    .set('Authorization', `Bearer ${authToken}`);
  
  console.log('[TEST] Status:', response.status);
  console.log('[TEST] Response:', JSON.stringify(response.body, null, 2));
  
  if (response.status === 200) {
    console.log('[TEST] ✅ Client Evolution - OK');
    return true;
  } else {
    console.log('[TEST] ❌ Client Evolution - FAILED');
    return false;
  }
}

async function testAddCommunication() {
  console.log('\n[TEST] Test Add Communication...');
  
  const communicationData = {
    type: 'email',
    subject: 'Test Communication',
    content: 'Ceci est un test de communication'
  };
  
  const response = await request(app)
    .post(`/api/clients/${testClientId}/communication`)
    .set('Authorization', `Bearer ${authToken}`)
    .send(communicationData);
  
  console.log('[TEST] Status:', response.status);
  console.log('[TEST] Response:', JSON.stringify(response.body, null, 2));
  
  if (response.status === 200) {
    console.log('[TEST] ✅ Add Communication - OK');
    return true;
  } else {
    console.log('[TEST] ❌ Add Communication - FAILED');
    return false;
  }
}

async function testUpdateScore() {
  console.log('\n[TEST] Test Update Score...');
  
  const response = await request(app)
    .put(`/api/clients/${testClientId}/score`)
    .set('Authorization', `Bearer ${authToken}`);
  
  console.log('[TEST] Status:', response.status);
  console.log('[TEST] Response:', JSON.stringify(response.body, null, 2));
  
  if (response.status === 200) {
    console.log('[TEST] ✅ Update Score - OK');
    return true;
  } else {
    console.log('[TEST] ❌ Update Score - FAILED');
    return false;
  }
}

async function cleanupTestData() {
  try {
    console.log('\n[TEST] Nettoyage des données de test...');
    
    // Supprimer les données de test
    if (testClientId) {
      await Client.findByIdAndDelete(testClientId);
      console.log('[TEST] Client de test supprimé');
    }
    
    if (testUserId) {
      await User.findByIdAndDelete(testUserId);
      await Invoice.deleteMany({ user: testUserId });
      console.log('[TEST] Utilisateur et factures de test supprimés');
    }
    
  } catch (error) {
    console.error('[TEST] Erreur nettoyage:', error);
  }
}

async function runAllTests() {
  const results = [];
  
  try {
    console.log('🚀 [TEST] Début des tests API clients et créances\n');
    
    await setupTestData();
    
    // Exécuter tous les tests
    results.push(await testDashboardMetrics());
    results.push(await testTopClients());
    results.push(await testCreancesAnalysis());
    results.push(await testClientStats());
    results.push(await testOverdueClients());
    results.push(await testClientEvolution());
    results.push(await testAddCommunication());
    results.push(await testUpdateScore());
    
    // Afficher le résumé
    const passed = results.filter(r => r).length;
    const total = results.length;
    
    console.log('\n📊 [TEST] RÉSUMÉ:');
    console.log(`[TEST] Tests réussis: ${passed}/${total}`);
    console.log(`[TEST] Taux de réussite: ${((passed/total)*100).toFixed(1)}%`);
    
    if (passed === total) {
      console.log('[TEST] 🎉 TOUS LES TESTS SONT PASSÉS!');
    } else {
      console.log('[TEST] ⚠️  Certains tests ont échoué');
    }
    
  } catch (error) {
    console.error('[TEST] Erreur générale:', error);
  } finally {
    await cleanupTestData();
    await mongoose.connection.close();
    console.log('[TEST] Tests terminés et connexion fermée');
  }
}

// Lancer les tests
runAllTests();