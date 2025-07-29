// Utilitaire simple pour convertir un nombre en lettres (français, version courte)
// Pour les montants de facture (ex: 1300 => 'mille trois cents francs CFA')

String numberToWordsFr(int number) {
  // Pour une version complète, utiliser un package ou une librairie dédiée.
  // Ici, version simplifiée pour les montants courants (0 à 999999)
  final units = [
    '',
    'un',
    'deux',
    'trois',
    'quatre',
    'cinq',
    'six',
    'sept',
    'huit',
    'neuf',
    'dix',
    'onze',
    'douze',
    'treize',
    'quatorze',
    'quinze',
    'seize',
    'dix-sept',
    'dix-huit',
    'dix-neuf',
  ];
  final tens = [
    '',
    '',
    'vingt',
    'trente',
    'quarante',
    'cinquante',
    'soixante',
    'soixante',
    'quatre-vingt',
    'quatre-vingt',
  ];

  if (number == 0) return 'zéro franc CFA';

  String convert999(int n) {
    if (n == 0) return '';
    if (n < 20) return units[n];
    if (n < 100) {
      var t = tens[n ~/ 10];
      var u = n % 10;
      if (n < 70 || (n >= 80 && n < 90)) {
        return t +
            (u > 0 ? (u == 1 && (n ~/ 10) != 8 ? '-et-' : '-') + units[u] : '');
      } else if (n < 80) {
        // 70-79 : soixante-dix, soixante-onze...
        return 'soixante-' + units[n - 60];
      } else {
        // 90-99 : quatre-vingt-dix...
        return 'quatre-vingt-' + units[n - 80];
      }
    }
    var h = n ~/ 100;
    var r = n % 100;
    var cent = h > 1 ? units[h] + ' cent' : 'cent';
    if (r == 0) return cent + (h > 1 ? 's' : '');
    return cent + ' ' + convert999(r);
  }

  String result = '';
  if (number >= 1000000) {
    result += convert999(number ~/ 1000000) + ' million';
    if ((number ~/ 1000000) > 1) result += 's';
    number %= 1000000;
    if (number > 0) result += ' ';
  }
  if (number >= 1000) {
    if ((number ~/ 1000) == 1) {
      result += 'mille';
    } else {
      result += convert999(number ~/ 1000) + ' mille';
    }
    number %= 1000;
    if (number > 0) result += ' ';
  }
  if (number > 0) {
    result += convert999(number);
  }
  result = result.trim();
  result = result[0].toUpperCase() + result.substring(1);
  return '$result franc${number > 1 ? 's' : ''} CFA';
}
