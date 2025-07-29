import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal pour révéler et modifier le mot de passe d'un utilisateur
///
/// Ce widget affiche :
/// - Champ de confirmation du mot de passe admin
/// - Option pour modifier le mot de passe
/// - Affichage du mot de passe révélé
class PasswordRevealModal extends StatefulWidget {
  final String username;
  final Function(String adminPassword, {String? newPassword}) onConfirm;
  final VoidCallback onCancel;

  const PasswordRevealModal({
    Key? key,
    required this.username,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<PasswordRevealModal> createState() => _PasswordRevealModalState();
}

class _PasswordRevealModalState extends State<PasswordRevealModal> {
  final _formKey = GlobalKey<FormState>();
  final _adminPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showNewPasswordField = false;
  bool _showRevealedPassword = false;
  String? _revealedPassword;
  String? _errorMessage;

  @override
  void dispose() {
    _adminPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.onConfirm(
        _adminPasswordController.text,
        newPassword:
            _showNewPasswordField && _newPasswordController.text.isNotEmpty
            ? _newPasswordController.text
            : null,
      );

      if (result['success']) {
        setState(() {
          _revealedPassword = result['tempPassword'];
          _showRevealedPassword = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 500
            ? 450
            : MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Icon(
                    Icons.security,
                    color: const Color(0xFF7717E8),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Accès sécurisé',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Mot de passe de ${widget.username}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Message d'erreur
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Affichage du mot de passe révélé
              if (_showRevealedPassword && _revealedPassword != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mot de passe récupéré',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _revealedPassword!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy, size: 18),
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: _revealedPassword!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Mot de passe copié'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Copier',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Formulaire de confirmation
              if (!_showRevealedPassword) ...[
                // Champ mot de passe admin
                Text(
                  'Votre mot de passe administrateur',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _adminPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Mot de passe admin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF7717E8),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le mot de passe est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Option pour modifier le mot de passe
                Row(
                  children: [
                    Checkbox(
                      value: _showNewPasswordField,
                      onChanged: (value) {
                        setState(() {
                          _showNewPasswordField = value ?? false;
                          if (!_showNewPasswordField) {
                            _newPasswordController.clear();
                          }
                        });
                      },
                      activeColor: const Color(0xFF7717E8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Modifier le mot de passe',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),

                // Champ nouveau mot de passe (conditionnel)
                if (_showNewPasswordField) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Nouveau mot de passe',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Laissez vide pour générer automatiquement',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF7717E8),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_showRevealedPassword) ...[
                    TextButton(
                      onPressed: _isLoading ? null : widget.onCancel,
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7717E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Confirmer',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7717E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Fermer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
