import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

class PosTicket {
  final Map<String, dynamic> facture;

  PosTicket({required this.facture});

  // Helper to safely parse numbers
  num _parseNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  Future<List<int>> generateTicket() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Extract data from facture
    final user = facture['user'] as Map<String, dynamic>? ?? {};
    final company = user['company'] as Map<String, dynamic>? ?? {};
    final client = facture['client'] as Map<String, dynamic>? ?? {};

    final clientNom = '${client['firstName'] ?? ''} ${client['lastName'] ?? ''}'
        .trim();
    final caissier = user['username'] ?? 'N/A';
    final lines = List<Map<String, dynamic>>.from(facture['lines'] ?? []);

    final total = _parseNum(facture['total']);
    final montantPaye = _parseNum(facture['montantPaye']);
    final resteAPayer = total - montantPaye;
    final discountTotal = _parseNum(facture['discountTotal']);
    final sousTotal = total + discountTotal;

    final number = facture['number'] ?? '';
    final date = facture['date'] != null
        ? DateTime.tryParse(facture['date'])
        : null;
    final formattedDate = date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(date)
        : '';
    final totalInWords = facture['totalInWords'] ?? '';

    // Header graphique avec séparateurs et titres comme dans le layout Flutter
    bytes += generator.text(
      '===============================================',
      styles: PosStyles(align: PosAlign.center, fontType: PosFontType.fontA, bold: false),
    );
    bytes += generator.text(
      '  ==========================',
      styles: PosStyles(align: PosAlign.center, fontType: PosFontType.fontA, bold: false),
    );
    bytes += generator.text(
      (company['name']?.toUpperCase() ?? 'ETS SADISSOU ET FILS'),
      styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      'NIF : ${company['nif'] ?? '122524/R'}',
      styles: PosStyles(align: PosAlign.center, bold: true, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      'ADRESSE : ${company['address'] ?? '17 Porte'}',
      styles: PosStyles(align: PosAlign.center, bold: true, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      'Tél : ${company['phone'] ?? '96521292/96970680'}',
      styles: PosStyles(align: PosAlign.center, bold: true, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      '  ==========================',
      styles: PosStyles(align: PosAlign.center, fontType: PosFontType.fontA, bold: false),
    );
    bytes += generator.text(
      '===============================================',
      styles: PosStyles(align: PosAlign.center, fontType: PosFontType.fontA, bold: false),
    );
    bytes += generator.feed(1);
    // Ligne infos facture sur une seule ligne (Ticket, Date, Caissier, Client)
    String infoLine = 'Date: $formattedDate  Recu N°: $number';
    bytes += generator.text(
      infoLine,
      styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontA),
    );
    String infoLine2 = 'Client: $clientNom          Caissier: $caissier';
    bytes += generator.text(
      infoLine2,
      styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontA),
    );
    bytes += generator.feed(1);

    // Table Header avec séparateurs verticaux
    bytes += generator.text(
      '| Désignation         |  PU   | Qté  |  Mt    |',
      styles: PosStyles(align: PosAlign.left, bold: true, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      '-----------------------------------------------',
      styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontA),
    );
    // Table Body avec alignement et séparateurs
    for (var line in lines) {
      final name = (line['productName'] ?? '').toString();
      final qte = _parseNum(line['quantity']).toStringAsFixed(0);
      final pu = _parseNum(line['unitPrice']).toStringAsFixed(0);
      final mt = _parseNum(line['totalLine'] ?? line['total']).toStringAsFixed(0);
      // Ajuster la largeur pour chaque colonne (max 80mm, police monospace)
      String row =
        '| ${name.padRight(18).substring(0, 18)}'
        '  | ${pu.toString().padLeft(5).substring(0, 5)}'
        ' |${qte.toString().padLeft(3).substring(0, 3)}'
        '   |${mt.toString().padLeft(6).substring(0, 6)}  |';
      bytes += generator.text(row, styles: PosStyles(fontType: PosFontType.fontA));
    }
    bytes += generator.text(
      '-----------------------------------------------',
      styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontA),
    );

    // Footer avec séparateurs et alignement
    // Alignement titres à gauche, montants à droite (largeur 47 caractères)
    int ticketWidth = 47;
    String formatTotalLine(String label, String value) {
      int space = ticketWidth - label.length - value.length;
      if (space < 1) space = 1;
      return label + ' ' * space + value;
    }
    bytes += generator.text(
      formatTotalLine('SOUS-TOTAL :', '${sousTotal.toStringAsFixed(0)} F'),
      styles: PosStyles(align: PosAlign.left, bold: true, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      formatTotalLine('REMISE :', '${discountTotal.toStringAsFixed(0)} F'),
      styles: PosStyles(align: PosAlign.left, bold: true, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      formatTotalLine('TOTAL :', '${total.toStringAsFixed(0)} F'),
      styles: PosStyles(align: PosAlign.left, bold: true, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      formatTotalLine('MONTANT PAYE :', '${montantPaye.toStringAsFixed(0)} F'),
      styles: PosStyles(align: PosAlign.left, bold: true, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      formatTotalLine('RESTE A PAYER :', '${resteAPayer.toStringAsFixed(0)} F'),
      styles: PosStyles(align: PosAlign.left, bold: true, fontType: PosFontType.fontA),
    );
    bytes += generator.feed(1);
    bytes += generator.text(
      'Arrete la presente facture a la somme de :',
      styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      totalInWords,
      styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      '===============================================',
      styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      'Merci de votre confiance !',
      styles: PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
    );
    bytes += generator.text(
      '===============================================',
      styles: PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }
}
