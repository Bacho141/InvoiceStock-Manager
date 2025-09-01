import 'package:flutter/material.dart';
import '../../../models/client.dart';
import 'client_card_widget.dart';

class ClientListWidget extends StatelessWidget {
  final List<Client> clients;
  final bool isLoading;
  final Function(Client) onClientTap;
  final Function(Client) onEditClient;
  final Function(Client) onDeleteClient;

  const ClientListWidget({
    Key? key,
    required this.clients,
    required this.isLoading,
    required this.onClientTap,
    required this.onEditClient,
    required this.onDeleteClient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (clients.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucun client trouvé',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajustez vos filtres ou créez un nouveau client',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: clients.map((client) => ClientCardWidget(
        client: client,
        onTap: () => onClientTap(client),
        onEdit: () => onEditClient(client),
        onDelete: () => onDeleteClient(client),
      )).toList(),
    );
  }
}