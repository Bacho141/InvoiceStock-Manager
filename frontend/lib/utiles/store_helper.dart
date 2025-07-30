import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Helper pour récupérer le storeId sélectionné depuis SharedPreferences
Future<String?> getSelectedStoreId({BuildContext? context, bool showError = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final storeId = prefs.getString('selected_store_id');
  if (storeId == null || storeId == 'default' || storeId.isEmpty) {
    if (showError && context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun magasin sélectionné. Veuillez sélectionner un magasin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }
  return storeId;
}
