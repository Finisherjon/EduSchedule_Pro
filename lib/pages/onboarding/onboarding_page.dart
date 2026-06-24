import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../setup/class_setup_page.dart';

// ── Data ──────────────────────────────────────────────────────────────────────

class _SlideData {
  final Color bgTop;
  final Color bgBottom;
  final String title;
  final String subtitle;
  final Widget Function(Animation<double> anim) illustrationBuilder;

  const _SlideData({
    required this.bgTop,
    required this.bgBottom,
    required this.title,
    required this.subtitle,
    required this.illustrationBuilder,
  });
}

final _slides = <_SlideData>[
  _SlideData(
    bgTop: const Color(0xFF1565C0),
    bgBottom: const Color(0xFF42A5F5),
    title: "Xush kelibsiz!",
    subtitle:
        "Maktab dars jadvalini tez, aniq va qulay tarzda yarating. Bir necha daqiqada tayyor.",
    illustrationBuilder: (anim) => _CalendarIllustration(animation: anim),
  ),
  _SlideData(
    bgTop: const Color(0xFF00695C),
    bgBottom: const Color(0xFF26A69A),
    title: "Sinflar va fanlar",
    subtitle:
        "Har bir sinf uchun fanlar, haftalik soatlar va qiyinlik darajasini belgilang.",
    illustrationBuilder: (anim) => _ClassesIllustration(animation: anim),
  ),
  _SlideData(
    bgTop: const Color(0xFF6A1B9A),
    bgBottom: const Color(0xFFAB47BC),
    title: "Aqlli jadval",
    subtitle:
        "Algoritm avtomatik ravishda qiyin fanlarni ertalabga, yengil fanlarni keyinga joylashtiradi.",
    illustrationBuilder: (anim) => _AutoIllustration(animation: anim),
  ),
  _SlideData(
    bgTop: const Color(0xFFE65100),
    bgBottom: const Color(0xFFFF7043),
    title: "Boshlaylik!",
    subtitle:
        "Birinchi sinfingizni qo'shib, avtomatik jadval yaratasiz. Oddiy va tez!",
    illustrationBuilder: (anim) => _RocketIllustration(animation: anim),
  ),
];

// ── Page ─────────────────────────────────────────────────────────────────────

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late final AnimationController _illustrationCtrl;
  late final AnimationController _fadeCtrl;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _illustrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1,
    );
  }

  @override
  void dispose() {
    _illustrationCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _animateToPage(_currentPage + 1);
    } else {
      _goToSetup();
    }
  }

  void _animateToPage(int page) async {
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() => _currentPage = page);
    await _fadeCtrl.forward();
  }

  void _goToSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ClassSetupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [slide.bgTop, slide.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: isLast ? null : _goToSetup,
                      child: Text(
                        "O'tkazib yuborish",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Illustration
              Expanded(
                flex: 5,
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: slide.illustrationBuilder(_illustrationCtrl),
                  ),
                ),
              ),

              // Text + dots + button
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                  child: FadeTransition(
                    opacity: _fadeCtrl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slide.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.55,
                          ),
                        ),
                        const Spacer(),

                        // Dots + next button
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom + 24,
                          ),
                          child: Row(
                            children: [
                              // Dot indicators
                              Row(
                                children: List.generate(
                                  _slides.length,
                                  (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    margin: const EdgeInsets.only(right: 6),
                                    width: i == _currentPage ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: i == _currentPage
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.35,
                                            ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),

                              // Next / Start button
                              GestureDetector(
                                onTap: _next,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isLast ? 28 : 20,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isLast)
                                        Text(
                                          'Boshlash',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: slide.bgTop,
                                          ),
                                        ),
                                      if (isLast) const SizedBox(width: 8),
                                      Icon(
                                        isLast
                                            ? Icons.rocket_launch_rounded
                                            : Icons.arrow_forward_rounded,
                                        color: slide.bgTop,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
}

// ── Illustrations ────────────────────────────────────────────────────────────

// Slide 1: Animatsiyali kalendar
class _CalendarIllustration extends StatelessWidget {
  final Animation<double> animation;

  const _CalendarIllustration({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final t = animation.value; // 0→1→0
        return Center(
          child: SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Orqa aylana
                Transform.scale(
                  scale: 0.92 + 0.08 * t,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                // Kalendar kartochkasi
                Transform.translate(
                  offset: Offset(0, -6 * t),
                  child: Container(
                    width: 170,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1565C0),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Dushanba',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Rows
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                _CalRow(
                                  color: const Color(0xFF1565C0),
                                  label: 'Matematika',
                                  delay: 0,
                                  t: t,
                                ),
                                const SizedBox(height: 8),
                                _CalRow(
                                  color: const Color(0xFF388E3C),
                                  label: 'Fizika',
                                  delay: 0.1,
                                  t: t,
                                ),
                                const SizedBox(height: 8),
                                _CalRow(
                                  color: const Color(0xFF7B1FA2),
                                  label: 'Kimyo',
                                  delay: 0.2,
                                  t: t,
                                ),
                                const SizedBox(height: 8),
                                _CalRow(
                                  color: const Color(0xFFF57C00),
                                  label: 'Tarix',
                                  delay: 0.3,
                                  t: t,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tepada chiqib turgan badge
                Positioned(
                  top: 12,
                  right: 22,
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * math.sin(t * math.pi),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF388E3C),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CalRow extends StatelessWidget {
  final Color color;
  final String label;
  final double delay;
  final double t;

  const _CalRow({
    required this.color,
    required this.label,
    required this.delay,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = (0.6 + 0.4 * math.sin((t - delay) * math.pi)).clamp(
      0.5,
      1.0,
    );
    return Opacity(
      opacity: opacity,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// Slide 2: Sinflar va fanlar
class _ClassesIllustration extends StatelessWidget {
  final Animation<double> animation;

  const _ClassesIllustration({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final t = animation.value;
        return Center(
          child: SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Orqa doira
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                // Karta stack
                ...[
                  _classCard(
                    offset: Offset(0, 8 + 4 * t),
                    color: const Color(0xFF00695C),
                    label: '9-A sinf',
                    subjects: '12 ta fan',
                    icon: Icons.groups_rounded,
                  ),
                  _classCard(
                    offset: Offset(0, -30 + 4 * (1 - t)),
                    color: const Color(0xFF00897B),
                    label: '10-B sinf',
                    subjects: '14 ta fan',
                    icon: Icons.school_rounded,
                  ),
                  _classCard(
                    offset: Offset(0, -68 - 2 * t),
                    color: const Color(0xFF26A69A),
                    label: '11-V sinf',
                    subjects: '13 ta fan',
                    icon: Icons.class_rounded,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _classCard({
    required Offset offset,
    required Color color,
    required String label,
    required String subjects,
    required IconData icon,
  }) {
    return Transform.translate(
      offset: offset,
      child: Container(
        width: 200,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  subjects,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Slide 3: Aqlli algoritm
class _AutoIllustration extends StatelessWidget {
  final Animation<double> animation;

  const _AutoIllustration({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final t = animation.value;
        final rotation = t * 2 * math.pi;

        return Center(
          child: SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Aylanuvchi tashqi halqa
                Transform.rotate(
                  angle: rotation * 0.3,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Orbit nuqtalar
                ..._orbitDots(t),
                // Markaziy karta
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: rotation * 0.5,
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF6A1B9A),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Auto',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6A1B9A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _orbitDots(double t) {
    const items = [
      (
        icon: Icons.wb_sunny_rounded,
        color: Color(0xFFF57C00),
        label: 'Qiyin → Ertalab',
      ),
      (
        icon: Icons.balance_rounded,
        color: Color(0xFF1565C0),
        label: 'Teng taqsimlash',
      ),
      (
        icon: Icons.weekend_rounded,
        color: Color(0xFF388E3C),
        label: 'Shanba yengil',
      ),
    ];
    return List.generate(items.length, (i) {
      final angle = (t * math.pi * 2) + (i * 2 * math.pi / items.length);
      const r = 95.0;
      final dx = math.cos(angle) * r;
      final dy = math.sin(angle) * r;
      final item = items[i];
      return Transform.translate(
        offset: Offset(dx, dy),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(item.icon, color: Colors.white, size: 18),
            ),
          ],
        ),
      );
    });
  }
}

// Slide 4: Boshlaylik
class _RocketIllustration extends StatelessWidget {
  final Animation<double> animation;

  const _RocketIllustration({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final t = animation.value;
        return Center(
          child: SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsating circles
                ...List.generate(3, (i) {
                  final scale = 0.5 + (i * 0.2) + (t * 0.1);
                  final opacity = (0.15 - i * 0.04) * (1 - t * 0.3);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: opacity.clamp(0, 0.2),
                        ),
                      ),
                    ),
                  );
                }),

                // Stars (floating particles)
                ..._stars(t),

                // Rocket card
                Transform.translate(
                  offset: Offset(0, -8 * t),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🚀', style: TextStyle(fontSize: 48 + 4 * t)),
                        const SizedBox(height: 6),
                        Text(
                          'Tayyor!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE65100),
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
      },
    );
  }

  List<Widget> _stars(double t) {
    const positions = [
      Offset(-80, -70),
      Offset(85, -60),
      Offset(-90, 30),
      Offset(88, 40),
      Offset(-30, 90),
      Offset(40, 85),
    ];
    return positions.asMap().entries.map((e) {
      final i = e.key;
      final pos = e.value;
      final phase = (t + i * 0.17) % 1.0;
      final opacity = (0.4 + 0.6 * math.sin(phase * math.pi)).clamp(0.0, 1.0);
      final scale = 0.6 + 0.4 * math.sin(phase * math.pi);
      return Transform.translate(
        offset: pos,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      );
    }).toList();
  }
}
