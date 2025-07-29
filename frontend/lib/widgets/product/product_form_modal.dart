import 'package:flutter/material.dart';
import '../custom_button.dart';

class ProductFormModal extends StatefulWidget {
  final Map<String, dynamic>? product;
  final Function(Map<String, dynamic>) onSave;

  const ProductFormModal({super.key, this.product, required this.onSave});

  @override
  State<ProductFormModal> createState() => _ProductFormModalState();
}

class _ProductFormModalState extends State<ProductFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();

  String _selectedCategory = 'Boissons';
  String _selectedUnit = 'Pièce';
  bool _isActive = true;
  String? _selectedImage;

  final List<String> _categories = [
    'Boissons',
    'Snacks',
    'Alimentation',
    'Hygiène',
    'Entretien',
    'Divers',
  ];

  final List<String> _units = [
    'Pièce',
    'kg',
    'g',
    'litre',
    'ml',
    'm',
    'cm',
    'm²',
    'm³',
    'paquet',
    'carton',
    'bouteille',
    'sachet',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.product != null) {
      _referenceController.text = widget.product!['reference'] ?? '';
      _nameController.text = widget.product!['name'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _barcodeController.text = widget.product!['barcode'] ?? '';
      _purchasePriceController.text = (widget.product!['purchasePrice'] ?? 0)
          .toString();
      _sellingPriceController.text = (widget.product!['sellingPrice'] ?? 0)
          .toString();
      _minStockController.text =
          (widget.product!['minStock'] ?? widget.product!['minStockLevel'] ?? 0)
              .toString();
      _maxStockController.text =
          (widget.product!['maxStock'] ?? widget.product!['maxStockLevel'] ?? 0)
              .toString();
      _selectedCategory = widget.product!['category'] ?? 'Boissons';
      _selectedUnit = widget.product!['unit'] ?? 'Pièce';
      _isActive = widget.product!['isActive'] ?? true;
      _selectedImage = widget.product!['image'];
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    super.dispose();
  }

  double _calculateMargin() {
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;

    if (purchasePrice > 0) {
      return ((sellingPrice - purchasePrice) / purchasePrice) * 100;
    }
    return 0;
  }

  double _calculateMarginValue() {
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;
    return sellingPrice - purchasePrice;
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      debugPrint(
        '[WIDGET][ProductFormModal] Sauvegarde du produit: \\${_nameController.text}',
      );
      final productData = {
        'id': widget.product?['id'],
        'reference': _referenceController.text.trim(),
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'purchasePrice': double.parse(_purchasePriceController.text),
        'sellingPrice': double.parse(_sellingPriceController.text),
        'margin': _calculateMargin(),
        'marginValue': _calculateMarginValue(),
        'minStock': int.parse(_minStockController.text),
        'maxStock': int.parse(_maxStockController.text),
        'unit': _selectedUnit,
        'barcode': _barcodeController.text.trim(),
        'isActive': _isActive,
        'image': _selectedImage,
        'createdAt': (widget.product?['createdAt'] ?? DateTime.now())
            .toIso8601String(),
      };
      widget.onSave(productData);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final margin = _calculateMargin();
    final marginValue = _calculateMarginValue();
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final dialogWidth = isMobile ? width * 0.95 : 800.0;
    final dialogMaxWidth = isMobile ? 500.0 : double.infinity;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 40,
        vertical: isMobile ? 16 : 24,
      ),
      alignment: Alignment.center,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxWidth: dialogMaxWidth),
        height: isMobile ? null : 600,
        padding: EdgeInsets.all(isMobile ? 8 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  isEditing ? Icons.edit : Icons.add,
                  color: const Color(0xFF7717E8),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Modification' : 'Création',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7717E8),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 24),
            // Formulaire
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMobile) ...[
                        // Tous les champs empilés (1 par ligne)
                        _buildField(
                          'Référence Produit *',
                          _referenceController,
                          hint: 'REF-001',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La référence est obligatoire';
                            }
                            return null;
                          },
                          inputPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildField(
                          'Code-barres',
                          _barcodeController,
                          hint: '1234567890123',
                          inputPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildField(
                          'Prix d\'Achat H.T. *',
                          _purchasePriceController,
                          hint: '1000',
                          suffix: 'F',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le prix d\'achat est obligatoire';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                          inputPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildField(
                          'Prix de Vente H.T. *',
                          _sellingPriceController,
                          hint: '1500',
                          suffix: 'F',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le prix de vente est obligatoire';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                          inputPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildField(
                          'Nom du produit *',
                          _nameController,
                          hint: 'Nom du produit',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La description est obligatoire';
                            }
                            return null;
                          },
                          inputPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildDropdown(
                          'Unité de vente *',
                          _selectedUnit,
                          _units,
                          (value) => setState(() => _selectedUnit = value!),
                          inputPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildDropdown(
                          'Catégorie *',
                          _selectedCategory,
                          _categories,
                          (value) => setState(() => _selectedCategory = value!),
                          inputPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildImagePicker(),
                        const SizedBox(height: 10),
                        _buildField(
                          'Seuil d\'Alerte Min *',
                          _minStockController,
                          hint: '10',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le seuil minimum est obligatoire';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                          inputPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildField(
                          'Seuil d\'Alerte Max *',
                          _maxStockController,
                          hint: '100',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le seuil maximum est obligatoire';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                          inputPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Checkbox + label sur 2 lignes
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _isActive,
                                  onChanged: (value) {
                                    setState(() {
                                      _isActive = value ?? true;
                                    });
                                  },
                                  activeColor: const Color(0xFF7717E8),
                                ),
                                const Text(
                                  'Produit actif',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 40),
                              child: Text(
                                '(visible dans le catalogue)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildMarginPreview(margin, marginValue),
                      ] else ...[
                        // Version desktop/tablette : structure actuelle (Rows)
                        // Première ligne
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Référence Produit *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _referenceController,
                                    decoration: InputDecoration(
                                      hintText: 'REF-001',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'La référence est obligatoire';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Code-barres',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _barcodeController,
                                    decoration: InputDecoration(
                                      hintText: '1234567890123',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Deuxième ligne
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Prix d\'Achat H.T. *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _purchasePriceController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '1000',
                                      suffixText: 'F',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Le prix d\'achat est obligatoire';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Veuillez entrer un nombre valide';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Prix de Vente H.T. *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _sellingPriceController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '1500',
                                      suffixText: 'F',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Le prix de vente est obligatoire';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Veuillez entrer un nombre valide';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Troisième ligne
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Description *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      hintText: 'Nom du produit',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'La description est obligatoire';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Unité de vente *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedUnit,
                                    items: _units
                                        .map(
                                          (unit) => DropdownMenuItem(
                                            value: unit,
                                            child: Text(unit),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedUnit = value!;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Quatrième ligne
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Catégorie *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    items: _categories
                                        .map(
                                          (category) => DropdownMenuItem(
                                            value: category,
                                            child: Text(category),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategory = value!;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Image du produit',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () {
                                      // TODO: Implémenter la sélection d'image
                                      debugPrint(
                                        '[WIDGET][ProductFormModal] Sélection d\'image',
                                      );
                                    },
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[50],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.photo_camera,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Choisir image...',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Cinquième ligne
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Seuil d\'Alerte Min *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _minStockController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '10',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Le seuil minimum est obligatoire';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Veuillez entrer un nombre valide';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Seuil d\'Alerte Max *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _maxStockController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '100',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Le seuil maximum est obligatoire';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Veuillez entrer un nombre valide';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Statut du produit
                        Row(
                          children: [
                            Checkbox(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value ?? true;
                                });
                              },
                              activeColor: const Color(0xFF7717E8),
                            ),
                            const Text(
                              'Produit actif (visible dans le catalogue)',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Aperçu de la marge
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calculate, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Marge calculée : ${margin.toStringAsFixed(1)}% (${marginValue.toStringAsFixed(0)} F)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    Text(
                                      'Prix d\'achat: ${_purchasePriceController.text} F → Prix de vente: ${_sellingPriceController.text} F',
                                      style: TextStyle(
                                        color: Colors.blue[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Boutons d'action
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 12),
                if (isMobile)
                  IconButton(
                    onPressed: _saveProduct,
                    icon: const Icon(Icons.save, color: Color(0xFF7717E8)),
                    tooltip: 'Enregistrer',
                  )
                else
                  CustomButton(
                    onPressed: _saveProduct,
                    text: isEditing ? 'Modifier' : 'Enregistrer',
                    icon: isEditing ? Icons.save : Icons.add,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    String? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    EdgeInsetsGeometry? inputPadding,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: isMobile
                ? const EdgeInsets.symmetric(vertical: 8, horizontal: 12)
                : (inputPadding ??
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16)),
          ),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    EdgeInsetsGeometry? inputPadding,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: isMobile
                ? const EdgeInsets.symmetric(vertical: 8, horizontal: 12)
                : (inputPadding ??
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Image du produit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            // TODO: Implémenter la sélection d'image
            debugPrint('[WIDGET][ProductFormModal] Sélection d\'image');
          },
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Choisir image...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarginPreview(double margin, double marginValue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marge calculée : ${margin.toStringAsFixed(1)}% (${marginValue.toStringAsFixed(0)} F)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  'Prix d\'achat: ${_purchasePriceController.text} F → Prix de vente: ${_sellingPriceController.text} F',
                  style: TextStyle(color: Colors.blue[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
