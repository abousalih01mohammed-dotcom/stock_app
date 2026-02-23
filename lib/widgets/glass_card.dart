import 'package:flutter/material.dart';
import 'package:stock_app/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool withGlow;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.withGlow = true,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Animations.quick,
      curve: Animations.smooth,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.3), // Remplacé : glassWhite
            AppTheme.primaryPurple.withOpacity(0.2), // Remplacé : glassPurple
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.2), // Remplacé : glassWhite
          width: 1,
        ),
        boxShadow: withGlow ? AppTheme.neonShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        ),
      ),
    );
  }
}
