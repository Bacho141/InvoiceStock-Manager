import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/auth_controller.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final AuthController _authController = AuthController();
  bool _loading = false;

  Future<void> _handleStart(BuildContext context) async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null && token.isNotEmpty) {
      final result = await _authController.verifySession();
      if (result['valid'] == true) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
        setState(() => _loading = false);
        return;
      }
    }
    setState(() => _loading = false);
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
          options: ParticleOptions(
            baseColor: const Color(0xFF7717E8),
            spawnMinSpeed: 20,
            spawnMaxSpeed: 70,
            particleCount: 60,
            minOpacity: 0.1,
            maxOpacity: 0.3,
            spawnMinRadius: 1.0,
            spawnMaxRadius: 5.0,
          ),
        ),
        vsync: this,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Section logo (à remplacer par Image.asset ou NetworkImage)
                  Container(
                    width: isDesktop ? 120 : 80,
                    height: isDesktop ? 120 : 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7717E8).withOpacity(0.1),
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
                  const SizedBox(height: 24),
                  // Nom d'entreprise
                  Text(
                    'ETS SADISSOU & FILS',
                    style: TextStyle(
                      fontSize: isDesktop ? 32 : 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7717E8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Nom de l'application
                  Text(
                    'InvoiceStock Manager',
                    style: TextStyle(
                      fontSize: isDesktop ? 22 : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Animation Lottie (entrepôt/facturation)
                  SizedBox(
                    width: isDesktop ? 400 : 250,
                    height: isDesktop ? 300 : 180,
                    child: Lottie.asset(
                      'assets/lottie/warehouse.json',
                      repeat: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Bouton Commencer
                  SizedBox(
                    width: isDesktop ? 220 : double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7717E8),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loading ? null : () => _handleStart(context),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Commencer',
                              style: TextStyle(
                                fontSize: isDesktop ? 20 : 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
