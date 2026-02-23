import 'package:flutter/material.dart';
import 'package:stock_app/theme/app_theme.dart';

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isActive;

  const NeumorphicButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isActive = false,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: Animations.quick,
        curve: Animations.spring,
        transform: _isPressed
            ? (Matrix4.identity()..scale(0.95))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          gradient: widget.isActive
              ? AppTheme.cyberGradient
              : LinearGradient(
                  colors: [
                    AppTheme.glassEffect, // Gardé car défini
                    AppTheme.darkBg.withOpacity(
                      0.8,
                    ), // Remplacé : surfaceDark → darkBg avec opacité
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: widget.isActive
              ? AppTheme.neonShadow
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(5, 5),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(
                      0.1,
                    ), // Remplacé : glassWhite → Colors.white
                    blurRadius: 15,
                    offset: const Offset(-5, -5),
                  ),
                ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
