import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/class_group_provider.dart';
import '../home/main_shell.dart';
import '../onboarding/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Dot offsets matching CSS: delay -0.32s, -0.16s, 0s  → phase offset 0.32/1.4, 0.16/1.4, 0
  static const _offsets = [0.2286, 0.1143, 0.0];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final hasData =
          context.read<ClassGroupProvider>().groups.isNotEmpty;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              hasData ? const MainShell() : const OnboardingPage(),
        ),
      );
    });
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // top spacer — flex-1
              const Spacer(),

              // center content
              _CenterContent(),

              // footer — flex-1, content pinned to bottom
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PulseDots(controller: _controller, offsets: _offsets),
                        const SizedBox(height: 32),
                        _VersionLabel(),
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
}

// ── Center logo + text ────────────────────────────────────────────────────────

class _CenterContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LogoBox(),
          const SizedBox(height: 24), // space-y-stack-xl
          _TextBlock(),
        ],
      ),
    );
  }
}

class _LogoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/icon/app_icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'EduSchedule Pro',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.32,
            // -0.01em
            color: Colors.white,
            height: 40 / 32,
          ),
        ),
        const SizedBox(height: 4), // space-y-stack-sm
        Text(
          'Maktab jadvalini tez va oson  Yarating va Boshqaring',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: Colors.white.withValues(alpha: 0.9),
            height: 20 / 14,
          ),
        ),
      ],
    );
  }
}

// ── Pulse dots ────────────────────────────────────────────────────────────────

class _PulseDots extends StatelessWidget {
  final AnimationController controller;
  final List<double> offsets;

  const _PulseDots({required this.controller, required this.offsets});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(offsets.length, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final phase = (controller.value + offsets[i]) % 1.0;
              final (scale, opacity) = _computePhase(phase);
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  // Matches CSS keyframes: 0%,80%,100% → scale 0, opacity 0.3 / 40% → scale 1, opacity 1
  static (double scale, double opacity) _computePhase(double p) {
    if (p < 0.4) {
      final t = p / 0.4;
      return (t, 0.3 + 0.7 * t);
    } else if (p < 0.8) {
      final t = (p - 0.4) / 0.4;
      return (1.0 - t, 1.0 - 0.7 * t);
    } else {
      return (0.0, 0.3);
    }
  }
}

// ── Version label ─────────────────────────────────────────────────────────────

class _VersionLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'v1.0 | Yoriqulov Miraziz',
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.5),
        letterSpacing: 1.2,
        height: 16 / 11,
      ),
    );
  }
}
