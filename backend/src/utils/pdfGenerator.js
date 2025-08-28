// Fonction utilitaire pour générer le HTML de la facture avec historique de paiement
function generateInvoiceHTML(invoice) {
  const client = invoice.client || {};
  const store = invoice.store || {};
  const user = invoice.user || {};
  const lines = invoice.lines || [];
  
  const clientNom = `${client.firstName || ''} ${client.lastName || ''}`.trim() || 'Client inconnu';
  const clientAdresse = client.address || '';
  const clientPhone = client.phone || '';
  
  const storeNom = store.name || 'ETS SADISSOU ET FILS';
  const storeNif = store.nif || '122524/R';
  const storeRccm = store.rccm || 'ABCDE125-45';
  const storeAdresse = store.address || '17 Porte';
  const storePhone = store.phone || '96521292/96970680';
  
  const caissier = user.username || 'Admin';
  const total = invoice.total || 0;
  const totalInWords = invoice.totalInWords || '';
  const number = invoice.number || '';
  const montantPaye = invoice.montantPaye || 0;
  const resteAPayer = total - montantPaye;
  const modePaiement = invoice.modePaiement || 'Espèces';
  
  // Formatage de la date
  const date = invoice.date ? new Date(invoice.date) : new Date();
  const formattedDate = `${date.getDate().toString().padStart(2, '0')}/${(date.getMonth() + 1).toString().padStart(2, '0')}/${date.getFullYear()} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  
  // Génération de l'historique des paiements
  const paymentHistory = invoice.paymentHistory || [];
  let paymentHistoryHTML = '';
  
  if (paymentHistory.length > 0) {
    paymentHistoryHTML = paymentHistory.map(payment => {
      const paymentDate = new Date(payment.date);
      const formattedPaymentDate = `${paymentDate.getDate().toString().padStart(2, '0')}/${(paymentDate.getMonth() + 1).toString().padStart(2, '0')}/${paymentDate.getFullYear()}`;
      const icon = getPaymentIcon(payment.method);
      return `
        <div class="payment-item">
          <div class="payment-method">
            <span class="payment-icon">${icon}</span>
            <span>${payment.method}</span>
          </div>
          <div class="payment-amount">
            <div class="payment-amount-value">${payment.amount.toFixed(0)} F</div>
            <div class="payment-date">${formattedPaymentDate}</div>
          </div>
        </div>`;
    }).join('');
  } else {
    paymentHistoryHTML = `
      <div class="no-payments">
        <div class="no-payments-icon">💳</div>
        <div>Aucun paiement enregistré</div>
      </div>`;
  }
  
  // Génération des lignes de produits
  const linesHTML = lines.map(line => `
    <tr class="product-row">
      <td style="text-align: left;">${line.productName || ''}</td>
      <td style="text-align: center;">${line.quantity || 0}</td>
      <td style="text-align: right;">${(line.unitPrice || 0).toFixed(0)} F</td>
      <td style="text-align: right; font-weight: bold; color: #7717E8;">${(line.totalLine || 0).toFixed(0)} F</td>
    </tr>
  `).join('');

  return `
    <!DOCTYPE html>
    <html lang="fr">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Facture ${number}</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          margin: 0;
          padding: 20px;
          background-color: #f5f5f5;
          line-height: 1.4;
        }
        .invoice-container {
          width: 595px;
          margin: 0 auto;
          background: white;
          padding: 32px;
          border-radius: 18px;
          box-shadow: 0 4px 16px rgba(0,0,0,0.08);
        }
        .header {
          display: flex;
          align-items: flex-start;
          margin-bottom: 24px;
        }
        .logo {
          width: 100px;
          height: 100px;
          background: #f3f0fa;
          border-radius: 12px;
          border: 2px solid rgba(119, 23, 232, 0.2);
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          margin-right: 20px;
        }
        .store-info {
          flex: 1;
        }
        .store-name {
          font-size: 20px;
          font-weight: bold;
          color: #7717E8;
          margin-bottom: 8px;
        }
        .store-detail {
          font-size: 13px;
          color: #666;
          margin-bottom: 4px;
        }
        .separator {
          height: 1px;
          background: #ddd;
          margin: 20px 0;
        }
        .bill-to-section {
          display: flex;
          justify-content: space-between;
          margin-bottom: 24px;
        }
        .bill-to {
          flex: 3;
        }
        .invoice-details {
          flex: 2;
          text-align: right;
        }
        .bill-to-title {
          font-size: 14px;
          font-weight: bold;
          color: #333;
          margin-bottom: 8px;
        }
        .client-name {
          font-size: 15px;
          font-weight: 600;
          margin-bottom: 4px;
        }
        .client-detail {
          font-size: 13px;
          color: #666;
          margin-bottom: 4px;
        }
        .products-table {
          width: 100%;
          border-collapse: collapse;
          margin-bottom: 18px;
          border: 1px solid rgba(119, 23, 232, 0.3);
          border-radius: 8px;
          overflow: hidden;
        }
        .table-header {
          background: #7717E8;
          color: white;
        }
        .table-header th {
          padding: 12px 8px;
          font-weight: bold;
          font-size: 15px;
          text-align: center;
        }
        .product-row {
          border-bottom: 1px solid #f3f0fa;
        }
        .product-row:nth-child(even) {
          background-color: #f8f9fa;
        }
        .product-row td {
          padding: 10px 8px;
          font-size: 14px;
        }
        .totals-section {
          text-align: right;
          margin-bottom: 12px;
        }
        .total-main {
          font-size: 18px;
          font-weight: bold;
          color: #7717E8;
          margin-bottom: 12px;
        }
        .payment-summary {
          display: flex;
          justify-content: space-between;
          margin-bottom: 12px;
        }
        .amount-left {
          font-weight: bold;
          color: #dc3545;
          font-size: 14px;
        }
        .amount-paid {
          font-weight: bold;
          color: #28a745;
          font-size: 14px;
        }
        .total-words {
          font-style: italic;
          font-size: 13px;
          margin-bottom: 16px;
        }
        .payment-history {
          margin: 24px 0;
          padding: 20px;
          border: 2px solid #7717E8;
          border-radius: 12px;
          background: linear-gradient(135deg, #f8f7ff 0%, #ffffff 100%);
        }
        .payment-history-title {
          font-size: 16px;
          font-weight: bold;
          color: #7717E8;
          margin-bottom: 16px;
          text-align: center;
          text-transform: uppercase;
          letter-spacing: 1px;
        }
        .payment-summary-box {
          background: white;
          padding: 16px;
          border-radius: 8px;
          border: 1px solid #e0e0e0;
        }
        .payment-item {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 12px 0;
          border-bottom: 1px solid #f0f0f0;
        }
        .payment-item:last-child {
          border-bottom: none;
        }
        .payment-method {
          display: flex;
          align-items: center;
          font-weight: 500;
        }
        .payment-icon {
          margin-right: 8px;
          font-size: 16px;
        }
        .payment-amount {
          text-align: right;
        }
        .payment-amount-value {
          font-weight: bold;
          font-size: 16px;
          color: #28a745;
        }
        .payment-date {
          color: #666;
          font-size: 12px;
        }
        .payment-total {
          margin-top: 16px;
          padding-top: 16px;
          border-top: 2px solid #7717E8;
          display: flex;
          justify-content: space-between;
          font-weight: bold;
        }
        .footer-info {
          display: flex;
          justify-content: space-between;
          margin-bottom: 8px;
          font-size: 13px;
        }
        .terms {
          font-size: 12px;
          color: #666;
          margin-bottom: 4px;
        }
        .thanks {
          font-size: 13px;
          font-weight: 500;
          color: #7717E8;
        }
        .no-payments {
          text-align: center;
          padding: 30px;
          color: #666;
        }
        .no-payments-icon {
          font-size: 48px;
          margin-bottom: 16px;
          opacity: 0.5;
        }
        @media print {
          body { 
            margin: 0; 
            padding: 0; 
            background: white; 
          }
          .invoice-container { 
            box-shadow: none; 
            margin: 0; 
            border-radius: 0;
          }
          .payment-history {
            border: 2px solid #7717E8;
            break-inside: avoid;
          }
        }
        @page {
          size: A4;
          margin: 20mm;
        }

      </style>
    </head>
    <body>
      <div class="invoice-container">
        <!-- EN-TÊTE -->
        <div class="header">
          <div class="logo">
            <div style="font-size: 32px; color: #7717E8;">🏢</div>
            <div style="font-size: 10px; font-weight: bold; color: #7717E8;">LOGO</div>
            <div style="font-size: 10px; color: #7717E8;">MAGASIN</div>
          </div>
          <div class="store-info">
            <div class="store-name">${storeNom}</div>
            <div class="store-detail">NIF : ${storeNif}</div>
            <div class="store-detail">RCCM : ${storeRccm}</div>
            <div class="store-detail">ADRESSE : ${storeAdresse}</div>
            <div class="store-detail">Tel : ${storePhone}</div>
          </div>
        </div>
        
        <div class="separator"></div>
        
        <!-- SECTION FACTURÉ À + NUMÉRO/DATE -->
        <div class="bill-to-section">
          <div class="bill-to">
            <div class="bill-to-title">FACTURÉ À :</div>
            <div class="client-name">${clientNom}</div>
            ${clientAdresse ? `<div class="client-detail">${clientAdresse}</div>` : ''}
            ${clientPhone ? `<div class="client-detail">Tél: ${clientPhone}</div>` : ''}
          </div>
          <div class="invoice-details">
            <div style="font-size: 14px; font-weight: bold; margin-bottom: 6px;">Facture N° : ${number}</div>
            <div style="font-size: 13px; color: #666;">Date : ${formattedDate}</div>
          </div>
        </div>
        
        <div class="separator"></div>
        
        <!-- TABLEAU PRODUITS -->
        <table class="products-table">
          <thead class="table-header">
            <tr>
              <th>Désignation</th>
              <th>Qté</th>
              <th>P.U.</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            ${linesHTML}
          </tbody>
        </table>
        
        <div class="separator"></div>
        
        <!-- TOTAUX -->
        <div class="totals-section">
          <div class="total-main">TOTAL : ${total.toFixed(0)} F</div>
        </div>
        
        <div class="payment-summary">
          <div class="amount-left">Reste à payer : ${resteAPayer.toFixed(0)} F</div>
          <div class="amount-paid">Montant Payé : ${montantPaye.toFixed(0)} F</div>
        </div>
        
        <div class="total-words">Total en lettres : ${totalInWords}</div>
        
        <div class="separator"></div>
        
        <!-- HISTORIQUE DES PAIEMENTS -->
        <div class="payment-history">
          <div class="payment-history-title">📄 HISTORIQUE DES PAIEMENTS</div>
          <div class="payment-summary-box">
            ${paymentHistoryHTML}
            ${paymentHistory.length > 0 ? `
              <div class="payment-total">
                <span>Total payé : ${montantPaye.toFixed(0)} F</span>
                <span style="color: ${resteAPayer > 0 ? '#dc3545' : '#28a745'};">Reste à payer : ${resteAPayer.toFixed(0)} F</span>
              </div>` : ''}
          </div>
        </div>
        
        <div class="separator"></div>
        
        <!-- FOOTER -->
        <div class="footer-info">
          <div>Caissier : ${caissier}</div>
          <div>Mode de paiement : ${modePaiement}</div>
        </div>
        
        <div class="terms">Termes de paiement : Payable immédiatement.</div>
        <div class="thanks">Merci de votre confiance !</div>
      </div>
    </body>
    </html>
  `;
}

// Fonction utilitaire pour obtenir l'icône du mode de paiement
function getPaymentIcon(method) {
  const methodLower = method.toLowerCase();
  switch (methodLower) {
    case 'especes':
    case 'espèces':
      return '💰';
    case 'carte':
    case 'cb':
      return '💳';
    case 'cheque':
    case 'chèque':
      return '📃';
    case 'virement':
      return '🏦';
    default:
      return '💳';
  }
}

export { generateInvoiceHTML, getPaymentIcon, generateSimpleTestHTML };

// Fonction de test avec HTML simple pour diagnostiquer les problèmes PDF
function generateSimpleTestHTML(invoice) {
  return `
    <!DOCTYPE html>
    <html lang="fr">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Test PDF - Facture ${invoice.number || 'TEST'}</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          margin: 20px;
          line-height: 1.4;
        }
        .header {
          text-align: center;
          margin-bottom: 30px;
          color: #7717E8;
        }
        .content {
          margin: 20px 0;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>FACTURE TEST</h1>
        <h2>Numéro: ${invoice.number || 'TEST-001'}</h2>
      </div>
      
      <div class="content">
        <p><strong>Client:</strong> ${invoice.client?.firstName || 'Test'} ${invoice.client?.lastName || 'Client'}</p>
        <p><strong>Date:</strong> ${new Date().toLocaleDateString('fr-FR')}</p>
        <p><strong>Total:</strong> ${invoice.total || 0} F</p>
      </div>
      
      <div class="content">
        <h3>Produits:</h3>
        <table border="1" style="width: 100%; border-collapse: collapse;">
          <tr>
            <th>Produit</th>
            <th>Quantité</th>
            <th>Prix</th>
          </tr>
          ${(invoice.lines || []).map(line => `
            <tr>
              <td>${line.productName || 'Produit test'}</td>
              <td>${line.quantity || 1}</td>
              <td>${(line.totalLine || 0).toFixed(0)} F</td>
            </tr>
          `).join('')}
        </table>
      </div>
      
      <p style="margin-top: 40px; text-align: center; color: #666;">
        PDF généré le ${new Date().toLocaleString('fr-FR')}
      </p>
    </body>
    </html>
  `;
}