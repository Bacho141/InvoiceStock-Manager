import 'package:flutter/material.dart';
import '../layout/main_layout.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 80,
              color: const Color(0xFF7717E8).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rapports',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vous êtes sur la page des rapports et statistiques.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7717E8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF7717E8).withOpacity(0.3),
                ),
              ),
              child: const Text(
                'Cette page permettra de consulter les rapports de vente et statistiques.',
                style: TextStyle(fontSize: 14, color: Color(0xFF7717E8)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    return MainLayout(
      currentRoute: '/reports',
      pageTitle: '📊 Rapports',
      child: content,
    );
  }
}
