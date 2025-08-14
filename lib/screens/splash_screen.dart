import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_constants.dart';
import '../utils/performance_utils.dart';
import '../providers/app_providers.dart';
import '../services/prayer_times_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controllers
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animations
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Démarrer l'animation du logo
    _logoController.forward();

    // Attendre un peu puis démarrer l'animation du texte
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    // Initialiser les services en arrière-plan
    _initializeServices();

    // Naviguer vers l'écran principal plus rapidement (2 secondes)
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      context.go('/');
    }
  }

  void _initializeServices() async {
    try {
      // Optimiser les performances avant l'initialisation
      await PerformanceUtils.optimizePerformance();

      // Initialiser les services de manière asynchrone
      final futures = [
        ref.read(sttServiceProvider).initialize(),
        ref.read(ttsServiceProvider).initialize(),
        ref.read(quranAudioServiceProvider).initialize(),
        PrayerTimesService().initialize(),
      ];

      await Future.wait(futures);
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des services: $e');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    PerformanceUtils.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor,
              AppConstants.secondaryColor,
              AppConstants.primaryColor.withOpacity(0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoAnimation.value,
                        child: Container(
                          width: 150.w,
                          height: 150.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _buildLogo(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _textAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),

                        SizedBox(height: 8.h),

                        Text(
                          'القرآن الكريم',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                            fontFamily: 'Amiri',
                          ),
                          textDirection: TextDirection.rtl,
                        ),

                        SizedBox(height: 16.h),

                        Text(
                          'Votre compagnon spirituel',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        SizedBox(height: 40.h),

                        // Indicateur de chargement
                        SizedBox(
                          width: 40.w,
                          height: 40.w,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                            strokeWidth: 3.0,
                          ),
                        ),

                        SizedBox(height: 16.h),

                        Text(
                          'Initialisation...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 100.w,
      height: 100.w,
      child: CustomPaint(
        painter: QuranLogoPainter(),
      ),
    );
  }
}

class QuranLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Couleur principale
    paint.color = AppConstants.primaryColor;

    // Dessiner un croissant de lune stylisé
    final moonPath = Path();
    moonPath.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5,
      3.0,
    );

    final innerPath = Path();
    innerPath.addArc(
      Rect.fromCircle(
        center: Offset(center.dx + radius * 0.3, center.dy),
        radius: radius * 0.8,
      ),
      -0.8,
      3.6,
    );

    final crescentPath = Path.combine(
      PathOperation.difference,
      moonPath,
      innerPath,
    );

    canvas.drawPath(crescentPath, paint);

    // Dessiner une étoile
    paint.color = AppConstants.secondaryColor;
    final starCenter =
        Offset(center.dx + radius * 0.6, center.dy - radius * 0.4);
    _drawStar(canvas, paint, starCenter, radius * 0.15, 5);

    // Ajouter des lignes décoratives (représentant des versets)
    paint.color = AppConstants.primaryColor.withOpacity(0.6);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;

    for (int i = 0; i < 3; i++) {
      final y = center.dy - radius * 0.2 + (i * radius * 0.2);
      canvas.drawLine(
        Offset(center.dx - radius * 0.3, y),
        Offset(center.dx + radius * 0.1, y),
        paint,
      );
    }
  }

  void _drawStar(
      Canvas canvas, Paint paint, Offset center, double radius, int points) {
    final path = Path();
    final angle = (math.pi * 2) / points;

    for (int i = 0; i < points; i++) {
      final x1 = center.dx + radius * math.cos(i * angle - math.pi / 2);
      final y1 = center.dy + radius * math.sin(i * angle - math.pi / 2);

      final x2 = center.dx +
          (radius * 0.5) * math.cos((i + 0.5) * angle - math.pi / 2);
      final y2 = center.dy +
          (radius * 0.5) * math.sin((i + 0.5) * angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      path.lineTo(x2, y2);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
