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
      begin: 0.98,
      end: 1.06,
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
    return SizedBox(
      width: 180.w,
      height: 180.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isListening) _buildWaveCircles(),
          _buildMainCircle(),
          if (widget.confidence > 0) _buildConfidenceIndicator(),
        ],
      ),
    );
  }

  Widget _buildWaveCircles() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        // Une seule onde subtile
        final animationValue = (_waveAnimation.value) % 1.0;
        final opacity = (1.0 - animationValue).clamp(0.0, 1.0);
        final scale = 0.9 + (animationValue * 0.6);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(opacity * 0.2),
                width: 1.5,
              ),
            ),
          ),
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
                        ? AppConstants.primaryColor.withOpacity(0.6)
                        : AppConstants.primaryColor.withOpacity(0.2),
                    widget.isListening 
                        ? AppConstants.accentColor.withOpacity(0.4)
                        : AppConstants.accentColor.withOpacity(0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.15),
                    blurRadius: widget.isListening ? 10 : 6,
                    spreadRadius: widget.isListening ? 2 : 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.isListening ? Icons.mic : Icons.mic_none,
                  size: 40.sp,
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
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: confidenceColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.signal_cellular_alt,
              size: 12.sp,
              color: Colors.white,
            ),
            SizedBox(width: 4.w),
            Text(
              '${(widget.confidence * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
