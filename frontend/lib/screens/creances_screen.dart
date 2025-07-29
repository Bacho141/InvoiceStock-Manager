import 'package:flutter/material.dart';

class CreancesScreen extends StatelessWidget {
  const CreancesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des créances (test)')),
      body: const Center(
        child: Text('Interface de test - Gestion des créances'),
      ),
    );
  }
}
