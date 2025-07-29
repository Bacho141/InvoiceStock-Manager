import 'package:flutter/material.dart';

class StockIndicators extends StatelessWidget {
  final Map<String, dynamic> indicators;
  const StockIndicators({Key? key, required this.indicators}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final indicateurs = [
      {
        'label': 'Valeur Totale',
        'value': _formatMontant(indicators['valeurTotale']),
        'icon': Icons.attach_money,
        'gradient': const LinearGradient(
          colors: [Color(0xFF7717E8), Color(0xFFB388FF)],
        ),
      },
      {
        'label': 'Alertes Stock Faible',
        'value': (indicators['nbAlertesSeuil'] ?? indicators['nbAlertes'] ?? 0)
            .toString(),
        'icon': Icons.warning,
        'gradient': const LinearGradient(
          colors: [Color(0xFFF2994A), Color(0xFFFFE0B2)],
        ),
      },
      {
        'label': 'En Rupture',
        'value': (indicators['nbRuptures'] ?? 0).toString(),
        'icon': Icons.error,
        'gradient': const LinearGradient(
          colors: [Color(0xFFEB5757), Color(0xFFFFCDD2)],
        ),
      },
      {
        'label': 'Réf. Actives',
        'value': (indicators['nbActives'] ?? 0).toString(),
        'icon': Icons.check_circle,
        'gradient': const LinearGradient(
          colors: [Color(0xFF27AE60), Color(0xFFC8E6C9)],
        ),
      },
    ];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final double cardWidth = isMobile ? (screenWidth - 56) / 2 : 280;
    final double iconSize = isMobile ? 36 : 60;
    final double valueFont = isMobile ? 15 : 24;
    final double labelFont = isMobile ? 12 : 14;
    final double cardPadding = isMobile ? 10 : 20;
    return Center(
      child: Wrap(
        spacing: isMobile ? 8 : 20,
        runSpacing: isMobile ? 8 : 20,
        children: indicateurs
            .map(
              (ind) => SizedBox(
                width: cardWidth,
                child: _IndicatorCard(
                  label: ind['label'] as String,
                  value: ind['value'] as String,
                  icon: ind['icon'] as IconData,
                  gradient: ind['gradient'] as LinearGradient,
                  iconSize: iconSize,
                  valueFont: valueFont,
                  labelFont: labelFont,
                  cardPadding: cardPadding,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _formatMontant(dynamic montant) {
    if (montant == null) return '-';
    if (montant is num) {
      if (montant >= 1000000) {
        return (montant / 1000000).toStringAsFixed(1) + 'M F';
      } else if (montant >= 1000) {
        return (montant / 1000).toStringAsFixed(1) + 'K F';
      } else {
        return montant.toString() + ' F';
      }
    }
    return montant.toString();
  }
}

class _IndicatorCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final double iconSize;
  final double valueFont;
  final double labelFont;
  final double cardPadding;
  const _IndicatorCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.iconSize,
    required this.valueFont,
    required this.labelFont,
    required this.cardPadding,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.2,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 12,
              top: 12,
              child: Icon(
                icon,
                color: Colors.white.withOpacity(0.13),
                size: iconSize,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: valueFont,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: labelFont,
                        color: Colors.white70,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
