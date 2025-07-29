import 'package:flutter/material.dart';

/// Bouton personnalisé réutilisable
///
/// Ce widget gère :
/// - Styles cohérents dans toute l'application
/// - États de chargement et désactivé
/// - Animations et effets visuels
/// - Responsive design
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.icon,
    this.width,
    this.height = 48,
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? const Color(0xFF7717E8);

    return SizedBox(
      width: width,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: buttonColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: _buildButtonContent(buttonColor),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                elevation: 2,
                shadowColor: buttonColor.withOpacity(0.3),
              ),
              child: _buildButtonContent(Colors.white),
            ),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}

/// Bouton de déconnexion spécialisé
class LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  final bool isLoading;

  const LogoutButton({Key? key, required this.onLogout, this.isLoading = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: 'Se déconnecter',
      onPressed: onLogout,
      isLoading: isLoading,
      isOutlined: true,
      icon: Icons.logout,
      color: Colors.red[600],
    );
  }
}

/// Bouton de confirmation
class ConfirmButton extends StatelessWidget {
  final String text;
  final VoidCallback onConfirm;
  final bool isLoading;

  const ConfirmButton({
    Key? key,
    required this.text,
    required this.onConfirm,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onConfirm,
      isLoading: isLoading,
      icon: Icons.check,
    );
  }
}
