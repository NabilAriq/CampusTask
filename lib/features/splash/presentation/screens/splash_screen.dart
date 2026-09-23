import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../courses/presentation/controllers/course_controller.dart';
import '../../../courses/presentation/screens/course_list_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  // Interactive tap ripples
  final List<_RippleEffect> _ripples = [];

  String _loadingMessage = 'Menyiapkan sistem...';
  bool _isReady = false;

  @override
  void initState() {
    super.initState();

    // ── Logo entry animation ──
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    // ── Progress animation ──
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ),
    )..addListener(() {
        final val = _progressAnimation.value;
        if (val > 0.8) {
          if (_loadingMessage != 'Selamat datang!') {
            setState(() => _loadingMessage = 'Selamat datang!');
          }
        } else if (val > 0.5) {
          if (_loadingMessage != 'Sinkronisasi data kuliah & tugas...') {
            setState(
                () => _loadingMessage = 'Sinkronisasi data kuliah & tugas...');
          }
        } else if (val > 0.25) {
          if (_loadingMessage != 'Membuka koneksi database...') {
            setState(() => _loadingMessage = 'Membuka koneksi database...');
          }
        }
      });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isReady = true);
        // Small delay before auto-navigation
        Timer(const Duration(milliseconds: 400), _navigateToHome);
      }
    });

    _logoController.forward();
    _progressController.forward();

    // Warm up database provider in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appDatabaseProvider);
    });
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const CourseListScreen(),
        ),
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    setState(() {
      _ripples.add(
        _RippleEffect(
          position: details.localPosition,
          controller: AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          )..forward().then((_) {
              if (mounted) {
                setState(() {
                  _ripples.removeWhere((r) => r.position == details.localPosition);
                });
              }
            }),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    for (final ripple in _ripples) {
      ripple.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTap,
        child: Stack(
          children: [
            // Interactive background ripples
            ..._ripples.map((ripple) => _RippleWidget(ripple: ripple)),

            // Subtle animated background ambient shapes
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentBorder.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Main Content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Logo
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: AppColors.accentBorder
                                  .withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.school_rounded,
                                  size: 52,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // App Title
                    FadeTransition(
                      opacity: _logoFade,
                      child: const Column(
                        children: [
                          Text(
                            'CampusTask',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Kelola Tugas & Jadwal Kuliahmu',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF546E7A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Circular Loading Animation
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, _) {
                        final percent =
                            (_progressAnimation.value * 100).toInt();
                        return Column(
                          children: [
                            SizedBox(
                              width: 68,
                              height: 68,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Subtle outer glow
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryBlue
                                              .withValues(alpha: 0.15),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Background track circle
                                  SizedBox(
                                    width: 58,
                                    height: 58,
                                    child: CircularProgressIndicator(
                                      value: 1.0,
                                      strokeWidth: 4.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        AppColors.accentBorder
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                  ),
                                  // Active animated progress arc
                                  SizedBox(
                                    width: 58,
                                    height: 58,
                                    child: CircularProgressIndicator(
                                      value: _progressAnimation.value
                                          .clamp(0.01, 1.0),
                                      strokeWidth: 4.5,
                                      strokeCap: StrokeCap.round,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                  // Center percentage text
                                  Text(
                                    '$percent%',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Loading status message
                            Text(
                              _loadingMessage,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF546E7A),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Tap hint / Skip CTA
                    AnimatedOpacity(
                      opacity: _isReady ? 1.0 : 0.7,
                      duration: const Duration(milliseconds: 300),
                      child: TextButton.icon(
                        onPressed: _navigateToHome,
                        icon: Icon(
                          _isReady
                              ? Icons.arrow_forward_rounded
                              : Icons.touch_app_outlined,
                          size: 18,
                          color: AppColors.primaryBlue,
                        ),
                        label: Text(
                          _isReady ? 'Masuk Sekarang' : 'Ketuk layar untuk berinteraksi',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ripple Data & Custom Painting ────────────────────────────────────────────

class _RippleEffect {
  _RippleEffect({
    required this.position,
    required this.controller,
  });

  final Offset position;
  final AnimationController controller;
}

class _RippleWidget extends StatelessWidget {
  const _RippleWidget({required this.ripple});

  final _RippleEffect ripple;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ripple.controller,
      builder: (context, _) {
        final progress = ripple.controller.value;
        final radius = 20.0 + (progress * 70.0);
        final opacity = (1.0 - progress).clamp(0.0, 1.0);

        return Positioned(
          left: ripple.position.dx - radius,
          top: ripple.position.dy - radius,
          child: IgnorePointer(
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: opacity * 0.5),
                  width: 2.0 * (1.0 - progress * 0.5),
                ),
                color: AppColors.primaryBlue.withValues(alpha: opacity * 0.1),
              ),
            ),
          ),
        );
      },
    );
  }
}

