import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import '../../services/printer_service.dart';

class PrinterSelector extends StatefulWidget {
  final PrinterService printerService;
  final String type; // 'usb' or 'bluetooth'

  const PrinterSelector({
    Key? key,
    required this.printerService,
    required this.type,
  }) : super(key: key);

  @override
  _PrinterSelectorState createState() => _PrinterSelectorState();
}

class _PrinterSelectorState extends State<PrinterSelector> {
  Stream<List<PrinterDevice>>? _scanResult;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _scanResult = widget.printerService.scanPrinters(widget.type);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la recherche des imprimantes';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sélectionner une imprimante ${widget.type.toUpperCase()}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _startScan,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  Text(_error!),
                  TextButton(
                    onPressed: _startScan,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: StreamBuilder<List<PrinterDevice>>(
                stream: _scanResult,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erreur: ${snapshot.error}'),
                    );
                  }

                  final devices = snapshot.data ?? [];

                  if (devices.isEmpty) {
                    return const Center(
                      child: Text('Aucune imprimante trouvée'),
                    );
                  }

                  return ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      // Nettoyer le nom de l'imprimante
                      final deviceName = (device.name ?? 'Imprimante sans nom')
                          .replaceAll(RegExp(r'\(Copy \d+\)'), '')
                          .replaceAll('(Default)', '')
                          .trim();
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                        child: ListTile(
                          leading: Icon(
                            widget.type == 'usb' 
                                ? Icons.usb 
                                : Icons.bluetooth,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(
                            deviceName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          onTap: () => Navigator.of(context).pop(device),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
