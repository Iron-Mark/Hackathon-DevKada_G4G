import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kudlit_ph/app/constants.dart';
import 'package:kudlit_ph/features/learning/domain/entities/lesson_progress.dart';
import 'package:kudlit_ph/features/learning/presentation/providers/lesson_progress_provider.dart';

const List<String> _lessonOrder = <String>[
  'vowels-01',
  'consonants-01',
  'consonants-02',
  'consonants-03',
  'consonants-04',
  'kudlit-01',
];

const Map<String, String> _lessonNames = <String, String>{
  'vowels-01': 'Baybayin Vowels',
  'consonants-01': 'Consonants — Part 1',
  'consonants-02': 'Consonants — Part 2',
  'consonants-03': 'Consonants — Part 3',
  'consonants-04': 'Consonants — Part 4',
  'kudlit-01': 'Kudlit Marks',
};

class LearningProgressScreen extends ConsumerWidget {
  const LearningProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, LessonProgress> progressMap =
        ref.watch(lessonProgressNotifierProvider).value ??
        <String, LessonProgress>{};

    final int completed = progressMap.values
        .where((LessonProgress p) => p.completed)
        .length;
    final int total = _lessonOrder.length;

    // Find the next lesson to work on
    final String? nextLessonId =
        _lessonOrder
            .firstWhere(
              (String id) => progressMap[id]?.status != LessonStatus.completed,
              orElse: () => '',
            )
            .isEmpty
        ? null
        : _lessonOrder.firstWhere(
            (String id) => progressMap[id]?.status != LessonStatus.completed,
          );

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          _HeroAppBar(completed: completed, total: total),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                _OverallRingCard(completed: completed, total: total),
                const SizedBox(height: 20),
                ..._lessonOrder.asMap().entries.map(
                  (MapEntry<int, String> e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child:
                        _LessonTile(
                              index: e.key,
                              lessonId: e.value,
                              lessonName: _lessonNames[e.value] ?? e.value,
                              progress: progressMap[e.value],
                            )
                            .animate(delay: (e.key * 60).ms)
                            .fadeIn(duration: 280.ms)
                            .slideX(
                              begin: 0.08,
                              end: 0,
                              duration: 280.ms,
                              curve: Curves.easeOutCubic,
                            ),
                  ),
                ),
                if (nextLessonId != null) ...<Widget>[
                  const SizedBox(height: 8),
                  _ButtyCtaCard(lessonId: nextLessonId)
                      .animate(delay: 420.ms)
                      .fadeIn(duration: 320.ms)
                      .slideY(begin: 0.12, end: 0, duration: 320.ms),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Sliver App Bar (ocean theme) ───────────────────────────────────────

// Shared ocean palette — same as SettingsHeader so the two heroes read as one
// design family. Deep teal → mid teal → cyan, with foam accents.
const Color _oceanDeep = Color(0xFF0A4D68);
const Color _oceanTeal = Color(0xFF088395);
const Color _oceanCyan = Color(0xFF05BFDB);
const Color _oceanFoam = Color(0xFFBBE1FA);

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.completed, required this.total});

  final int completed;
  final int total;

  String get _message {
    if (completed == 0) {
      return 'Simulan na natin!\nStart your Baybayin journey.';
    }
    if (completed == total) return 'Magaling ka!\nAll lessons complete!';
    if (completed / total >= 0.5) {
      return 'Halos tapos na!\nAlmost there, keep going!';
    }
    return 'Magpatuloy lang!\nYou\'re making great progress.';
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        color: Colors.white,
        onPressed: () => context.pop(),
      ),
      backgroundColor: _oceanDeep,
      title: const Text('Learning Progress'),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: _HeroBanner(message: _message),
        collapseMode: CollapseMode.pin,
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _OceanWaveClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_oceanDeep, _oceanTeal, _oceanCyan],
            stops: <double>[0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: <Widget>[
              // Watery decorative bubbles drifting up.
              Positioned(
                top: 64,
                left: 32,
                child: _Bubble(size: 7, color: _oceanFoam.withAlpha(120)),
              ),
              Positioned(
                top: 28,
                left: 110,
                child: _Bubble(size: 5, color: _oceanFoam.withAlpha(160)),
              ),
              Positioned(
                top: 92,
                right: 168,
                child: _Bubble(size: 9, color: _oceanFoam.withAlpha(100)),
              ),
              Positioned(
                bottom: 36,
                left: 58,
                child: _Bubble(size: 6, color: _oceanFoam.withAlpha(140)),
              ),
              // Watery halo behind Butty so the mascot reads as if standing
              // in shallow water with a glowing reflection.
              Positioned(
                right: 12,
                bottom: 8,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        _oceanFoam.withAlpha(110),
                        _oceanFoam.withAlpha(0),
                      ],
                      stops: const <double>[0.0, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -8,
                bottom: -4,
                child:
                    Image.asset(
                          'assets/brand/ButtyRead.webp',
                          height: 140,
                          fit: BoxFit.fitHeight,
                        )
                        .animate(delay: 100.ms)
                        .slideX(
                          begin: 0.2,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeIn(duration: 300.ms),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 140, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _oceanFoam.withAlpha(120)),
                      ),
                      child: Text(
                        'Butty says',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _oceanFoam,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                          message,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        )
                        .animate(delay: 80.ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0, duration: 300.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        )
        .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -8, duration: 2000.ms, curve: Curves.easeInOut);
  }
}

/// Soft wave on the bottom edge of the hero — matches `SettingsHeader` so the
/// two screens share the same shoreline silhouette.
class _OceanWaveClipper extends CustomClipper<Path> {
  const _OceanWaveClipper();

  @override
  Path getClip(Size size) {
    final Path path = Path()
      ..lineTo(0, size.height - 22)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height,
        size.width * 0.5,
        size.height - 16,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height - 32,
        size.width,
        size.height - 12,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─── Animated overall ring card ───────────────────────────────────────────────

class _OverallRingCard extends StatelessWidget {
  const _OverallRingCard({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              _RingWidget(completed: completed, total: total, cs: cs),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$completed of $total lessons',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'completed',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withAlpha(140),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          end: total == 0 ? 0 : completed / total,
                        ),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (BuildContext context, double v, _) =>
                            LinearProgressIndicator(
                              value: v,
                              minHeight: 7,
                              backgroundColor: cs.surfaceContainerHigh,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                cs.primary,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _RingWidget extends StatelessWidget {
  const _RingWidget({
    required this.completed,
    required this.total,
    required this.cs,
  });

  final int completed;
  final int total;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final double fraction = total == 0 ? 0 : completed / total;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: fraction),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, _) => SizedBox(
        width: 72,
        height: 72,
        child: CustomPaint(
          painter: _RingPainter(
            fraction: value,
            arcColor: completed == total ? const Color(0xFF46B986) : cs.primary,
            trackColor: cs.surfaceContainerHighest,
          ),
          child: Center(
            child: Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.arcColor,
    required this.trackColor,
  });

  final double fraction;
  final Color arcColor;
  final Color trackColor;

  static const double _strokeWidth = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - _strokeWidth) / 2;
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..color = arcColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

// ─── Lesson tile ──────────────────────────────────────────────────────────────

class _LessonTile extends StatefulWidget {
  const _LessonTile({
    required this.index,
    required this.lessonId,
    required this.lessonName,
    required this.progress,
  });

  final int index;
  final String lessonId;
  final String lessonName;
  final LessonProgress? progress;

  @override
  State<_LessonTile> createState() => _LessonTileState();
}

class _LessonTileState extends State<_LessonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final LessonStatus status =
        widget.progress?.status ?? LessonStatus.notStarted;
    final bool tappable = status != LessonStatus.notStarted;

    return GestureDetector(
      onTapDown: tappable ? (_) => _pressCtrl.forward() : null,
      onTapUp: tappable
          ? (_) {
              _pressCtrl.reverse();
              context.push('${AppConstants.routeLesson}/${widget.lessonId}');
            }
          : null,
      onTapCancel: tappable ? () => _pressCtrl.reverse() : null,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (BuildContext context, Widget? child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _borderColor(cs, status),
              width: status == LessonStatus.inProgress ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _TileIcon(status: status, cs: cs),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.lessonName,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: status == LessonStatus.notStarted
                                  ? cs.onSurface.withAlpha(120)
                                  : cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _TileSubtitle(
                            status: status,
                            progress: widget.progress,
                            cs: cs,
                          ),
                        ],
                      ),
                    ),
                    if (tappable) ...<Widget>[
                      const SizedBox(width: 8),
                      _ActionChip(status: status, cs: cs),
                    ],
                  ],
                ),
                if (status == LessonStatus.inProgress &&
                    widget.progress != null) ...<Widget>[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: widget.progress!.progressFraction,
                      minHeight: 4,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFF5A623),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _borderColor(ColorScheme cs, LessonStatus status) {
    switch (status) {
      case LessonStatus.completed:
        return const Color(0xFF46B986).withAlpha(80);
      case LessonStatus.inProgress:
        return const Color(0xFFF5A623).withAlpha(120);
      case LessonStatus.notStarted:
        return cs.outlineVariant;
    }
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.status, required this.cs});

  final LessonStatus status;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LessonStatus.completed:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF46B986).withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF46B986),
            size: 22,
          ),
        );
      case LessonStatus.inProgress:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF5A623).withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_circle_filled_rounded,
            color: Color(0xFFF5A623),
            size: 22,
          ),
        );
      case LessonStatus.notStarted:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_rounded,
            color: cs.onSurface.withAlpha(60),
            size: 18,
          ),
        );
    }
  }
}

class _TileSubtitle extends StatelessWidget {
  const _TileSubtitle({
    required this.status,
    required this.progress,
    required this.cs,
  });

  final LessonStatus status;
  final LessonProgress? progress;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LessonStatus.notStarted:
        return Text(
          'Not started yet',
          style: TextStyle(fontSize: 11.5, color: cs.onSurface.withAlpha(80)),
        );
      case LessonStatus.inProgress:
        final int step = progress?.currentStepIndex ?? 0;
        final int total = progress?.totalSteps ?? 0;
        return Text(
          'Step $step of $total',
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFFF5A623),
            fontWeight: FontWeight.w600,
          ),
        );
      case LessonStatus.completed:
        final int score = progress?.score ?? 0;
        return Text(
          'Score: $score pts',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: score >= 80
                ? const Color(0xFF46B986)
                : cs.onSurface.withAlpha(140),
          ),
        );
    }
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.status, required this.cs});

  final LessonStatus status;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final bool done = status == LessonStatus.completed;
    final Color bg = done
        ? const Color(0xFF46B986).withAlpha(25)
        : cs.primaryContainer;
    final Color fg = done ? const Color(0xFF46B986) : cs.primary;
    final String label = done ? 'Review' : 'Resume';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ─── Butty CTA bottom card ────────────────────────────────────────────────────

class _ButtyCtaCard extends StatelessWidget {
  const _ButtyCtaCard({required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String lessonName = _lessonNames[lessonId] ?? lessonId;
    return GestureDetector(
      onTap: () => context.push('${AppConstants.routeLesson}/$lessonId'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withAlpha(60)),
        ),
        child: Row(
          children: <Widget>[
            ClipOval(
              child: Image.asset(
                'assets/brand/ButtyPencilRun.webp',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Continue learning',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lessonName,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: cs.onPrimary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
