import 'dart:async';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modèle pour stocker les informations de l'imprimante
class PrinterInfo {
  final String address;
  final String name;
  final String type;
  final String? productId;
  final String? vendorId;

  PrinterInfo({
    required this.address,
    required this.name,
    required this.type,
    this.productId,
    this.vendorId,
  });

  factory PrinterInfo.fromJson(Map<String, dynamic> json) {
    return PrinterInfo(
      address: json['address']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Imprimante inconnue',
      type: json['type']?.toString() ?? 'bluetooth',
      productId: json['productId']?.toString(),
      vendorId: json['vendorId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'name': name,
      'type': type,
      if (productId != null) 'productId': productId,
      if (vendorId != null) 'vendorId': vendorId,
    };
  }
}

class PrinterService {
  final PrinterManager _printerManager = PrinterManager.instance;
  static const String _lastPrinterKey = 'last_used_printer';
  PrinterType? _currentPrinterType;

  // Scanner les imprimantes disponibles
  Stream<List<PrinterDevice>> scanPrinters(String type) async* {
    final printerType = type.toLowerCase() == 'bluetooth' 
        ? PrinterType.bluetooth 
        : PrinterType.usb;
    
    _currentPrinterType = printerType;
    final devices = <PrinterDevice>[];
    final uniqueDeviceIds = <String>{}; // Pour éviter les doublons

    print('=== RECHERCHE D\'IMPRIMANTES ($type) ===');
    print('Type de scan: $printerType');
    
    try {
      await for (final device in _printerManager.discovery(type: printerType, isBle: false)) {
        print('Imprimante détectée:');
        print('- Nom: ${device.name}');
        print('- Adresse: ${device.address}');
        print('---');
        
        // Utiliser l'adresse ou le nom comme identifiant unique
        final deviceId = '${device.address ?? ''}:${device.name ?? ''}';
        
        if (!uniqueDeviceIds.contains(deviceId)) {
          uniqueDeviceIds.add(deviceId);
          devices.add(device);
          // Émettre une nouvelle liste à chaque ajout
          yield List.from(devices);
        }
      }
    } catch (e) {
      print('Erreur lors du scan: $e');
      rethrow; // Propager l'erreur pour qu'elle soit gérée par le widget
    } finally {
      print('=== FIN DU SCAN ===');
      print('Imprimantes trouvées: ${devices.length}');
    }
    
    // Émettre la liste finale
    if (devices.isNotEmpty) {
      yield List.from(devices);
    }
  }

  // Se connecter et imprimer
  Future<bool> connectAndPrint({
    required PrinterDevice device,
    required String type,
    required List<int> ticketBytes,
  }) async {
    print('=== TENTATIVE D\'IMPRESSION ===');
    print('Type: $type');
    print('Nom de l\'imprimante: ${device.name}');
    print('Adresse: ${device.address}');
    print('Taille des données: ${ticketBytes.length} bytes');
    
    try {
      final printerType = type.toLowerCase() == 'bluetooth' 
          ? PrinterType.bluetooth 
          : PrinterType.usb;
      
      _currentPrinterType = printerType;
      bool isConnected = false;

      if (printerType == PrinterType.bluetooth) {
        // Pour Bluetooth
        final deviceName = device.name;
        final deviceAddress = device.address;
        
        if (deviceAddress == null || deviceAddress.isEmpty) {
          print('ERREUR: Adresse Bluetooth manquante');
          return false;
        }
        
        print('Connexion à l\'imprimante Bluetooth: $deviceName ($deviceAddress)');
        
        isConnected = await _printerManager.connect(
          type: printerType,
          model: BluetoothPrinterInput(
            name: deviceName.isNotEmpty ? deviceName : 'Imprimante Bluetooth',
            address: deviceAddress,
            isBle: false,
            autoConnect: true,
          ),
        );
      } else {
        // Pour les imprimantes USB
        final deviceName = device.name;
        print('Connexion à l\'imprimante USB: $deviceName');
        
        // Pour les imprimantes USB, nous avons besoin de l'adresse comme identifiant
        // Le format est généralement quelque chose comme 'USB\VID_0483&PID_5740\6&2E7E3F4F&0&2'
        final deviceAddress = device.address ?? '';
        
        // Extraire le VID et le PID de l'adresse USB si possible
        String? vendorId;
        String? productId;
        
        if (deviceAddress.isNotEmpty) {
          final vidMatch = RegExp(r'VID_([0-9A-F]{4})', caseSensitive: false).firstMatch(deviceAddress);
          final pidMatch = RegExp(r'PID_([0-9A-F]{4})', caseSensitive: false).firstMatch(deviceAddress);
          
          vendorId = vidMatch?.group(1)?.padLeft(4, '0') ?? '0483'; // Valeur par défaut
          productId = pidMatch?.group(1)?.padLeft(4, '0') ?? '5740'; // Valeur par défaut
          
          print('Informations USB extraites - VID: $vendorId, PID: $productId');
        } else {
          print('ATTENTION: Aucune adresse USB trouvée, utilisation des valeurs par défaut');
          vendorId = '0483'; // Valeur par défaut
          productId = '5740'; // Valeur par défaut
        }
        
        try {
          isConnected = await _printerManager.connect(
            type: printerType,
            model: UsbPrinterInput(
              name: deviceName.isNotEmpty ? deviceName : 'Imprimante USB',
              productId: productId,
              vendorId: vendorId,
            ),
          );
        } catch (e) {
          print('Erreur lors de la connexion USB: $e');
          rethrow;
        }
      }

      print('Résultat de la connexion: $isConnected');
      
      if (isConnected) {
        print('Envoi des données d\'impression...');
        await _printerManager.send(type: printerType, bytes: ticketBytes);
        print('Données envoyées avec succès');
        await _saveLastPrinter(device, type);
        return true;
      }
    } catch (e) {
      print('Erreur d\'impression: $e');
    } finally {
      final currentType = _currentPrinterType;
      if (currentType != null) {
        await _printerManager.disconnect(type: currentType);
      }
    }
    return false;
  }

  // Sauvegarder la dernière imprimante utilisée
  Future<void> _saveLastPrinter(PrinterDevice device, String type) async {
    final prefs = await SharedPreferences.getInstance();
    String? productId;
    String? vendorId;
    
    if (device is UsbPrinterInput) {
      productId = device.productId?.toString();
      vendorId = device.vendorId?.toString();
    }
    
    final printerInfo = PrinterInfo(
      address: device.address ?? '',
      name: device.name ?? 'Imprimante inconnue',
      type: type,
      productId: productId,
      vendorId: vendorId,
    );
    
    await prefs.setString(_lastPrinterKey, printerInfo.toJson().toString());
  }

  // Récupérer la dernière imprimante utilisée
  Future<PrinterInfo?> getLastPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPrinter = prefs.getString(_lastPrinterKey);
      
      if (lastPrinter == null) return null;
      
      try {
        // Essayer de parser comme JSON
        final json = Map<String, dynamic>.from(
          Map<String, dynamic>.from({'_json': lastPrinter})['_json'] as Map
        );
        return PrinterInfo.fromJson(json);
      } catch (e) {
        // Si le parsing JSON échoue, essayer l'ancien format
        final parts = lastPrinter.split('|');
        if (parts.length == 2) {
          return PrinterInfo(
            address: parts[0],
            name: 'Imprimante',
            type: parts[1],
          );
        }
        return null;
      }
    } catch (e) {
      print('Erreur lors de la récupération de la dernière imprimante: $e');
      return null;
    }
  }
}
