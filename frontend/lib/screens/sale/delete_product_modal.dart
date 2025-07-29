import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:app/utiles/api_urls.dart';

class DeleteProductModal extends StatefulWidget {
  final Map<String, dynamic> facture;
  final VoidCallback onProductRemoved;

  const DeleteProductModal({
    super.key,
    required this.facture,
    required this.onProductRemoved,
  });

  @override
  State<DeleteProductModal> createState() => _DeleteProductModalState();
}

class _DeleteProductModalState extends State<DeleteProductModal> {
  bool _isDeleting = false;

  Future<void> _deleteLine(String lineId) async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final response = await http.patch(
        Uri.parse(ApiUrls.invoicesRemoveLine(widget.facture['_id'])),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'lineId': lineId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit supprimé avec succès'), backgroundColor: Colors.green),
        );
        widget.onProductRemoved();
      } else {
        final responseBody = json.decode(response.body);
        throw Exception(responseBody['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _confirmDelete(String lineId, String productName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Voulez-vous vraiment supprimer le produit "$productName" ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteLine(lineId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.facture['lines'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Supprimer un produit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_isDeleting) const Center(child: CircularProgressIndicator()),
          if (!_isDeleting && lines.isEmpty)
            const Center(child: Text('Aucun produit dans cette facture.')),
          if (!_isDeleting && lines.isNotEmpty)
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lines.length,
                itemBuilder: (context, index) {
                  final line = lines[index];
                  return ListTile(
                    title: Text(line['productName'] ?? 'Produit inconnu'),
                    subtitle: Text('Quantité: ${line['quantity']} - Total: ${line['totalLine']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(line['_id'], line['productName'] ?? 'ce produit'),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }
}
