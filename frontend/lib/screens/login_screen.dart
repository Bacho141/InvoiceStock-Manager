import 'package:flutter/material.dart';

import 'package:lottie/lottie.dart';

import 'package:app/controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  final AuthController _authController = AuthController();

  Future<void> _login() async {
    debugPrint('[SCREEN][LoginScreen] Bouton SE CONNECTER cliqué');
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    debugPrint('[SCREEN][LoginScreen] Tentative de login pour $username');
    try {
      final result = await _authController.login(username, password);
      if (result['success'] == true) {
        debugPrint(
          '[SCREEN][LoginScreen] Connexion réussie, rôle: \\${result['role']}',
        );
        debugPrint('[SCREEN][LoginScreen] Navigation vers /dashboard');
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        debugPrint('[SCREEN][LoginScreen] Erreur: \\${result['message']}');
        setState(() {
          _errorMessage = result['message'] ?? 'Identifiants invalides';
        });
      }
    } catch (e) {
      debugPrint('[SCREEN][LoginScreen] Exception: \\${e.toString()}');
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildForm(BuildContext context, {bool isDesktop = false}) {
    final logo = Column(
      children: [
        Container(
          width: isDesktop ? 100 : 80,
          height: isDesktop ? 100 : 80,
          decoration: BoxDecoration(
            color: const Color(0xFF7717E8).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.store_mall_directory,
              size: 48,
              color: Color(0xFF7717E8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'InvoiceStock Manager',
          style: TextStyle(
            fontSize: isDesktop ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7717E8),
          ),
        ),
      ],
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        logo,
        const SizedBox(height: 24),
        Text(
          'Connexion à votre espace',
          style: TextStyle(
            fontSize: isDesktop ? 20 : 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Nom d\'utilisateur',
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  prefixIcon: const Icon(
                    Icons.person,
                    color: Color(0xFF7717E8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF7717E8),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF7717E8),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  hintText: 'Entrez votre nom d\'utilisateur',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ obligatoire' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF7717E8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF7717E8),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF7717E8),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  hintText: 'Entrez votre mot de passe',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color(0xFF7717E8),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ obligatoire' : null,
                onFieldSubmitted: (_) => _login(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7717E8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'SE CONNECTER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              debugPrint('[LOGIN] Mot de passe oublié cliqué');
              // TODO: Afficher une popup ou naviguer vers la page de récupération
            },
            child: const Text('Mot de passe oublié ?'),
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 8),
        // Sélecteur de langue (structure prête, à brancher sur easy_localization)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // context.setLocale(Locale('fr'));
              },
              child: const Text('Français'),
            ),
            const Text('|'),
            TextButton(
              onPressed: () {
                // context.setLocale(Locale('ha'));
              },
              child: const Text('Haoussa'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final form = _buildForm(context, isDesktop: isDesktop);
    // Gestion du clavier sur mobile : décalage automatique
    final formWithKeyboard = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: isDesktop ? 64 : 24,
            right: isDesktop ? 64 : 24,
            top: isDesktop ? 64 : 32,
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                (isDesktop ? 64 : 32),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 500),
              child: form,
            ),
          ),
        );
      },
    );
    if (!isDesktop) {
      // Version mobile : formulaire centré, logo, etc.
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: formWithKeyboard),
      );
    } else {
      // Version desktop : deux colonnes, à droite animation Lottie
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            // Colonne formulaire
            Expanded(flex: 1, child: SafeArea(child: formWithKeyboard)),
            // Colonne animation
            Expanded(
              flex: 1,
              child: Container(
                color: const Color(0xFFF5F3FF),
                child: Center(
                  child: Lottie.asset(
                    'assets/lottie/sideAnimation.json',
                    repeat: true,
                    width: 500,
                    height: 500,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
