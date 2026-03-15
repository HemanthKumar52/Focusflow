import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _bottomOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Logo fades in and scales from 0.8 to 1.0 over 0-800ms
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.44, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.44, curve: Curves.easeOut),
      ),
    );

    // "FocusFlow" text fades in at 600ms delay (600-1200ms → 0.33-0.67)
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.33, 0.67, curve: Curves.easeOut),
    );

    // Bottom "HK" fades in at 1000ms delay (1000-1800ms → 0.56-1.0)
    _bottomOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.56, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    // Navigate after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final userName = Hive.box('settings').get('userName');
    if (userName == null) {
      context.go('/onboarding');
    } else {
      context.go('/today');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A1A),
              Color(0xFF1A1A3E),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center: Logo + Title
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with glow
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/icons/app_logo.png',
                        width: 180,
                        height: 180,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // "FocusFlow" text
                FadeTransition(
                  opacity: _titleOpacity,
                  child: const Text(
                    'FocusFlow',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF00D4FF),
                      letterSpacing: 6,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),

            // Bottom: "Powered by" + "HK"
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _bottomOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Powered by',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF4A9FD8),
                          Color(0xFFB8D8E8),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'HK',
                        style: GoogleFonts.orbitron(
                          fontSize: 66,
                          fontWeight: FontWeight.w700,
                          color: Colors.white, // gets masked by shader
                          decoration: TextDecoration.none,
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
