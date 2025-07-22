import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../utils/app_constants.dart';

class ListeningAnimation extends StatefulWidget {
  final bool isListening;
  final double confidence;

  const ListeningAnimation({
    Key? key,
    required this.isListening,
    this.confidence = 0.0,
  }) : super(key: key);

  @override
  State<ListeningAnimation> createState() => _ListeningAnimationState();
}

class _ListeningAnimationState extends State<ListeningAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _rotationController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    if (widget.isListening) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(ListeningAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _startAnimations();
    } else if (!widget.isListening && oldWidget.isListening) {
      _stopAnimations();
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    _rotationController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _waveController.stop();
    _rotationController.stop();
    _pulseController.reset();
    _waveController.reset();
    _rotationController.reset();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200.w,
      height: 200.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercles d'onde en arrière-plan
          if (widget.isListening) _buildWaveCircles(),
          
          // Cercle principal avec microphone
          _buildMainCircle(),
          
          // Indicateur de confiance
          if (widget.confidence > 0) _buildConfidenceIndicator(),
          
          // Particules flottantes
          if (widget.isListening) _buildFloatingParticles(),
        ],
      ),
    );
  }

  Widget _buildWaveCircles() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final animationValue = (_waveAnimation.value - delay) % 1.0;
            final opacity = (1.0 - animationValue).clamp(0.0, 1.0);
            final scale = 0.5 + (animationValue * 1.5);
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(opacity * 0.3),
                    width: 2,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMainCircle() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isListening ? _pulseAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.isListening ? _rotationAnimation.value : 0.0,
            child: Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.isListening 
                        ? AppConstants.primaryColor.withOpacity(0.8)
                        : AppConstants.primaryColor.withOpacity(0.3),
                    widget.isListening 
                        ? AppConstants.accentColor.withOpacity(0.9)
                        : AppConstants.accentColor.withOpacity(0.5),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.4),
                    blurRadius: widget.isListening ? 20 : 10,
                    spreadRadius: widget.isListening ? 5 : 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.isListening ? Icons.mic : Icons.mic_none,
                  size: 48.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfidenceIndicator() {
    final confidenceColor = widget.confidence > 0.7
        ? AppConstants.successColor
        : widget.confidence > 0.4
            ? AppConstants.warningColor
            : AppConstants.errorColor;

    return Positioned(
      bottom: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: confidenceColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: confidenceColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.signal_cellular_alt,
              size: 14.sp,
              color: Colors.white,
            ),
            SizedBox(width: 4.w),
            Text(
              '${(widget.confidence * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(8, (index) {
            final angle = (index * math.pi * 2 / 8) + _waveAnimation.value;
            final radius = 80.w + (math.sin(_waveAnimation.value * 2) * 20.w);
            final x = math.cos(angle) * radius;
            final y = math.sin(angle) * radius;
            
            return Transform.translate(
              offset: Offset(x, y),
              child: Container(
                width: 4.w,
                height: 4.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.secondaryColor.withOpacity(0.6),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.secondaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double animationValue;
  final List<double> waveData;
  final Color color;

  WaveformPainter({
    required this.animationValue,
    required this.waveData,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerY = size.height / 2;
    final stepWidth = size.width / (waveData.length - 1);

    for (int i = 0; i < waveData.length; i++) {
      final x = i * stepWidth;
      final y = centerY + (waveData[i] * centerY * animationValue);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AudioWaveform extends StatelessWidget {
  final bool isActive;
  final double amplitude;

  const AudioWaveform({
    Key? key,
    required this.isActive,
    this.amplitude = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200.w,
      height: 60.h,
      child: CustomPaint(
        painter: WaveformPainter(
          animationValue: isActive ? amplitude : 0.0,
          waveData: _generateWaveData(),
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  List<double> _generateWaveData() {
    final random = math.Random();
    return List.generate(50, (index) {
      return (random.nextDouble() - 0.5) * 2;
    });
  }
}
