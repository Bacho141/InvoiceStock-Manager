import 'package:flutter/material.dart';

class AddClientMobile extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSave;
  const AddClientMobile({Key? key, required this.onBack, required this.onSave})
    : super(key: key);

  @override
  State<AddClientMobile> createState() => _AddClientMobileState();
}

class _AddClientMobileState extends State<AddClientMobile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Material(
              elevation: 3,
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.only(
                  left: 4,
                  right: 12,
                  top: 2,
                  bottom: 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF7717E8),
                            size: 22,
                          ),
                          onPressed: widget.onBack,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.person_add_alt_1,
                          color: Color(0xFF7717E8),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ajouter un client',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const SizedBox(width: 54),
                        Container(
                          height: 3,
                          width: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7717E8),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF7717E8,
                                ).withOpacity(0.18),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 420,
              maxHeight: 520,
              maxWidth: 420,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF7F7FA),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Prénom requis'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF7F7FA),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nom requis' : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF7F7FA),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Téléphone requis'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onBack,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7717E8),
                              side: const BorderSide(
                                color: Color(0xFF7717E8),
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                widget.onSave();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7717E8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Enregistrer',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 12,
                    ), // Pour éviter que le clavier masque le bouton
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
