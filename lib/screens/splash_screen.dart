import 'package:flutter/material.dart';
import 'package:stock_app/screens/lock_screen.dart'; // IMPORT AJOUTÉ
import 'package:stock_app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  final bool firebaseInitialized;

  const SplashScreen({super.key, required this.firebaseInitialized});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    // Rediriger vers LockScreen après 3.5 secondes
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => LockScreen(
              firebaseInitialized: widget.firebaseInitialized,
            ), // ← REDIRECTION VERS LOCKSCREEN
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  var fade = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  );
                  var scale = Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.elasticOut,
                    ),
                  );
                  return FadeTransition(
                    opacity: fade,
                    child: ScaleTransition(scale: scale, child: child),
                  );
                },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // ANIMATION DE FOND
          Positioned.fill(child: CustomPaint(painter: NeuralNetworkPainter())),

          // PARTICULES
          ...List.generate(
            20,
            (index) => Positioned(
              left: (index * 37) % MediaQuery.of(context).size.width,
              top: (index * 73) % MediaQuery.of(context).size.height,
              child:
                  Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 2.seconds, delay: (index * 100).ms)
                      .then()
                      .shimmer(
                        duration: 2.seconds,
                        color: AppTheme.electricBlue,
                      )
                      .then()
                      .move(
                        begin: const Offset(0, 0),
                        end: const Offset(0, -100),
                        duration: 4.seconds,
                        curve: Curves.linear,
                      ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO AVEC ANIMATIONS SPECTACULAIRES
                Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.cyberGradient,
                        boxShadow: AppTheme.neonShadow,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/lakriraastock.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                    .animate()
                    .scale(
                      duration: 2.seconds,
                      curve: Curves.elasticOut,
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                    )
                    .then()
                    .rotate(duration: 20.seconds, begin: 0, end: 1)
                    .then()
                    .shimmer(duration: 2.seconds, color: Colors.white),

                const SizedBox(height: 40),

                // TITRE
                Text(
                      'LAKRIRAA STOCK',
                      style: GoogleFonts.orbitron(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 2
                          ..color = AppTheme.primaryPurple,
                        shadows: [
                          Shadow(
                            color: AppTheme.primaryPurple,
                            blurRadius: 20,
                            offset: const Offset(0, 0),
                          ),
                          Shadow(
                            color: AppTheme.electricBlue,
                            blurRadius: 40,
                            offset: const Offset(5, 5),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 1.seconds, delay: 500.ms)
                    .then()
                    .shimmer(duration: 200.ms, color: AppTheme.electricBlue),

                const SizedBox(height: 20),

                // SOUS-TITRE
                Text(
                      'GESTION INTELLIGENTE',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 4,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 1.seconds, delay: 1000.ms)
                    .then()
                    .moveY(
                      begin: 20,
                      end: 0,
                      duration: 1.seconds,
                      curve: Curves.elasticOut,
                    ),

                // INDICATEUR DE CHARGEMENT (optionnel)
                const SizedBox(height: 40),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryPurple,
                    ),
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// PAINTER POUR EFFET NEURAL NETWORK
class NeuralNetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryPurple.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final points = <Offset>[];
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        points.add(Offset(size.width * (i / 10), size.height * (j / 10)));
      }
    }

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        if ((points[i] - points[j]).distance < 100) {
          canvas.drawLine(points[i], points[j], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
