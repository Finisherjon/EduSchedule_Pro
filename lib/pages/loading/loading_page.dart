import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../home/main_shell.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _progressCtrl;

  int _completedSteps = 0;

  static const _stepLabels = [
    'Fanlar tahlil qilindi',
    'Ustuvorliklar tekshirildi',
    'Optimal tartib hisoblanmoqda...',
    'Jadval shakllantirilmoqda',
  ];

  // Step completion timestamps (ms)
  static const _stepTimes = [700, 1500, 2400];

  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..forward();

    for (int i = 0; i < _stepTimes.length; i++) {
      Future.delayed(Duration(milliseconds: _stepTimes[i]), () {
        if (mounted) setState(() => _completedSteps = i + 1);
      });
    }

    Future.delayed(const Duration(milliseconds: 3600), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (_) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const Spacer(),
              _SpinningLogo(spinCtrl: _spinCtrl),
              const SizedBox(height: 32),
              _TitleSection(),
              const SizedBox(height: 28),
              _StepsCard(
                completedSteps: _completedSteps,
                labels: _stepLabels,
                pulseCtrl: _pulseCtrl,
                spinCtrl: _spinCtrl,
              ),
              const Spacer(),
              _ProgressSection(progressCtrl: _progressCtrl),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Spinning logo ring ─────────────────────────────────────────────────────────

class _SpinningLogo extends StatelessWidget {
  final AnimationController spinCtrl;

  const _SpinningLogo({required this.spinCtrl});

  @override
  Widget build(BuildContext context) {
    const ringSize = 128.0;
    const innerSize = 80.0;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background faint ring
          CustomPaint(
            size: const Size(ringSize, ringSize),
            painter: _ArcPainter(
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
              fraction: 1.0,
              strokeWidth: 4,
            ),
          ),
          // Spinning arc
          RotationTransition(
            turns: spinCtrl,
            child: CustomPaint(
              size: const Size(ringSize, ringSize),
              painter: _ArcPainter(
                color: AppColors.primaryContainer,
                fraction: 0.75,
                strokeWidth: 4,
              ),
            ),
          ),
          // Inner white circle with logo
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double fraction;
  final double strokeWidth;

  const _ArcPainter({
    required this.color,
    required this.fraction,
    this.strokeWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(inset, inset, size.width - strokeWidth,
        size.height - strokeWidth);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.color != color || old.fraction != fraction;
}

// ── Title section ──────────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Jadval tuzilmoqda...',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryContainer,
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Iltimos kuting, tizim ma'lumotlarni tahlil qilmoqda",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Steps card ─────────────────────────────────────────────────────────────────

class _StepsCard extends StatelessWidget {
  final int completedSteps;
  final List<String> labels;
  final AnimationController pulseCtrl;
  final AnimationController spinCtrl;

  const _StepsCard({
    required this.completedSteps,
    required this.labels,
    required this.pulseCtrl,
    required this.spinCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: List.generate(labels.length, (i) {
          final isDone = i < completedSteps;
          final isActive = i == completedSteps;
          final isPending = i > completedSteps;

          return Padding(
            padding: EdgeInsets.only(
              bottom: i < labels.length - 1 ? 14 : 0,
            ),
            child: _StepRow(
              label: labels[i],
              isDone: isDone,
              isActive: isActive,
              isPending: isPending,
              pulseCtrl: pulseCtrl,
              spinCtrl: spinCtrl,
            ),
          );
        }),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isActive;
  final bool isPending;
  final AnimationController pulseCtrl;
  final AnimationController spinCtrl;

  const _StepRow({
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.isPending,
    required this.pulseCtrl,
    required this.spinCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepIcon(
          isDone: isDone,
          isActive: isActive,
          spinCtrl: spinCtrl,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: isActive
              ? AnimatedBuilder(
                  animation: pulseCtrl,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.5 + 0.5 * pulseCtrl.value,
                      child: child,
                    );
                  },
                  child: _StepLabel(
                    label: label,
                    color: AppColors.onSurface,
                    isBold: true,
                  ),
                )
              : _StepLabel(
                  label: label,
                  color: isDone
                      ? AppColors.primaryContainer
                      : AppColors.outline,
                  isBold: isDone,
                ),
        ),
      ],
    );
  }
}

class _StepIcon extends StatelessWidget {
  final bool isDone;
  final bool isActive;
  final AnimationController spinCtrl;

  const _StepIcon({
    required this.isDone,
    required this.isActive,
    required this.spinCtrl,
  });

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return const Icon(
        Icons.check_circle_rounded,
        size: 22,
        color: AppColors.primaryContainer,
      );
    }
    if (isActive) {
      return RotationTransition(
        turns: spinCtrl,
        child: const Icon(
          Icons.autorenew_rounded,
          size: 22,
          color: AppColors.onSurface,
        ),
      );
    }
    return const Icon(
      Icons.radio_button_unchecked_rounded,
      size: 22,
      color: AppColors.outline,
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String label;
  final Color color;
  final bool isBold;

  const _StepLabel({
    required this.label,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
        color: color,
      ),
    );
  }
}

// ── Progress bar section ───────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final AnimationController progressCtrl;

  const _ProgressSection({required this.progressCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progressCtrl,
      builder: (context, child) {
        final remaining =
            ((1 - progressCtrl.value) * 3.6).ceil().clamp(0, 99);
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tayyor bo'lish vaqti",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Taxminan $remaining soniya...',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Container(color: AppColors.surfaceContainer),
                    FractionallySizedBox(
                      widthFactor: progressCtrl.value,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryContainer,
                              AppColors.secondaryContainer,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
