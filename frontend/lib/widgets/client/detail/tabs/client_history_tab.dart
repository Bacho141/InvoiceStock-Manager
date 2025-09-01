// lib/widgets/client/detail/tabs/client_history_tab.dart
import 'package:flutter/material.dart';
import '../../../../models/client.dart';

class ClientHistoryTab extends StatelessWidget {
  final Client client;

  const ClientHistoryTab({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (client.communicationHistory.isNotEmpty) ...[
            Text(
              'Historique des communications (${client.communicationHistory.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: client.communicationHistory.length,
              itemBuilder: (context, index) {
                final comm = client.communicationHistory[index];
                return Card(
                  child: ListTile(
                    leading: Icon(_getCommunicationIcon(comm.type)),
                    title: Text(comm.subject ?? 'Sans sujet'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comm.content ?? 'Aucun contenu'),
                        const SizedBox(height: 4),
                        Text(
                          'Le ${comm.date.day}/${comm.date.month}/${comm.date.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(comm.typeDisplay),
                      backgroundColor: _getCommunicationColor(comm.type),
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            const Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune communication enregistrée'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getCommunicationIcon(String type) {
    switch (type) {
      case 'call':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'meeting':
        return Icons.people;
      case 'letter':
        return Icons.mail;
      default:
        return Icons.message;
    }
  }

  Color _getCommunicationColor(String type) {
    switch (type) {
      case 'call':
        return Colors.blue;
      case 'email':
        return Colors.green;
      case 'meeting':
        return Colors.purple;
      case 'letter':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}