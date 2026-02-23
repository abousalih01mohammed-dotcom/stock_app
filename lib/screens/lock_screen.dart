import 'package:flutter/material.dart';
import 'package:stock_app/screens/home_screen.dart';
import 'package:stock_app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LockScreen extends StatefulWidget {
  final bool firebaseInitialized;

  const LockScreen({super.key, required this.firebaseInitialized});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _errorMessage = '';

  // Mot de passe correct
  final String _correctPassword = 'lakriraastock2026';

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Simuler un délai pour l'effet de chargement
      Future.delayed(const Duration(milliseconds: 800), () {
        if (_passwordController.text == _correctPassword) {
          // Mot de passe correct - accès autorisé
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  HomeScreen(firebaseInitialized: widget.firebaseInitialized),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    var fade = Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
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
        } else {
          // Mot de passe incorrect
          setState(() {
            _isLoading = false;
            _errorMessage = '❌ Mot de passe incorrect';
          });
          _animationController.forward().then((_) {
            _animationController.reset();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // Fond animé
          Positioned.fill(child: CustomPaint(painter: LockScreenPainter())),

          // Particules (réutilisées)
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
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
                  ).animate().scale(
                    duration: 1.seconds,
                    curve: Curves.elasticOut,
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                  ),

                  const SizedBox(height: 30),

                  // Titre
                  Text(
                    'ACCÈS SÉCURISÉ',
                    style: GoogleFonts.orbitron(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(duration: 1.seconds, delay: 500.ms),

                  const SizedBox(height: 10),

                  Text(
                    'Veuillez saisir le mot de passe',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ).animate().fadeIn(duration: 1.seconds, delay: 700.ms),

                  const SizedBox(height: 40),

                  // Formulaire avec animation de secousse
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.glassEffect,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _errorMessage.isEmpty
                              ? AppTheme.primaryPurple.withOpacity(0.3)
                              : AppTheme.errorRed,
                          width: 1,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Champ mot de passe
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_rounded,
                                  color: AppTheme.primaryPurple,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey.shade400,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _errorMessage.isEmpty
                                        ? Colors.grey.shade800
                                        : AppTheme.errorRed,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryPurple,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.errorRed,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez saisir le mot de passe';
                                }
                                return null;
                              },
                            ),

                            if (_errorMessage.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: AppTheme.errorRed,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage,
                                        style: GoogleFonts.inter(
                                          color: AppTheme.errorRed,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Bouton de connexion
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _validatePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryPurple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'DÉVERROUILLER',
                                        style: GoogleFonts.orbitron(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Indice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.glassEffect,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade500,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Contactez l\'administrateur pour le mot de passe',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 1.seconds, delay: 900.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// PAINTER POUR FOND DE L'ÉCRAN DE VERROUILLAGE
class LockScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryPurple.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Dessiner des verrous stylisés
    for (int i = 0; i < 5; i++) {
      final x = size.width * (i / 5) + 20;
      final y = size.height * 0.5;

      // Corps du verrou
      final rect = Rect.fromLTWH(x, y - 10, 20, 20);
      canvas.drawRect(rect, paint);

      // Anneau du verrou
      canvas.drawCircle(Offset(x + 10, y - 15), 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
