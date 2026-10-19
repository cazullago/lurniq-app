import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Original vector illustrations for Lurniq (CustomPainter — no bitmap
/// assets, no lag). Warm, friendly, youthful. Each illustration resolves
/// its colors from the current theme so it works in day and night mode.
///
/// Usage: `EmptyState(illustration: IllustrationKind.chat, title: ...)`
/// or `GradientHeader(title: ..., subtitle: ...)`.
enum IllustrationKind { sunriseBook, chat, trophy, compass }

class LurniqIllustration extends StatelessWidget {
  const LurniqIllustration({
    super.key,
    required this.kind,
    this.size = 120,
  });

  final IllustrationKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final primary = scheme.primary;
    final secondary = scheme.secondary;
    final tertiary = scheme.tertiary;
    final soft = scheme.surfaceContainerHighest;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IllustrationPainter(
          kind,
          primary: primary,
          secondary: secondary,
          tertiary: tertiary,
          soft: soft,
          brightness: brightness,
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter(
    this.kind, {
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.soft,
    required this.brightness,
  });

  final IllustrationKind kind;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color soft;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Soft wash circle behind the art.
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.46,
      Paint()..color = primary.withValues(alpha: 0.10),
    );
    switch (kind) {
      case IllustrationKind.sunriseBook:
        _sunriseBook(canvas, w, h);
      case IllustrationKind.chat:
        _chat(canvas, w, h);
      case IllustrationKind.trophy:
        _trophy(canvas, w, h);
      case IllustrationKind.compass:
        _compass(canvas, w, h);
    }
  }

  void _sunriseBook(Canvas c, double w, double h) {
    // Sun.
    c.drawCircle(
      Offset(w * 0.5, h * 0.34),
      w * 0.16,
      Paint()..color = tertiary,
    );
    // Rays.
    final ray = Paint()
      ..color = tertiary.withValues(alpha: 0.65)
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = (i / 8) * math.pi * 2;
      final r1 = w * 0.22, r2 = w * 0.29;
      c.drawLine(
        Offset(w * 0.5 + r1 * math.cos(a), h * 0.34 + r1 * math.sin(a)),
        Offset(w * 0.5 + r2 * math.cos(a), h * 0.34 + r2 * math.sin(a)),
        ray,
      );
    }
    // Open book.
    final book = Paint()..color = primary;
    final path = Path()
      ..moveTo(w * 0.18, h * 0.62)
      ..quadraticBezierTo(w * 0.34, h * 0.56, w * 0.5, h * 0.62)
      ..quadraticBezierTo(w * 0.66, h * 0.56, w * 0.82, h * 0.62)
      ..lineTo(w * 0.82, h * 0.78)
      ..quadraticBezierTo(w * 0.66, h * 0.72, w * 0.5, h * 0.78)
      ..quadraticBezierTo(w * 0.34, h * 0.72, w * 0.18, h * 0.78)
      ..close();
    c.drawPath(path, book);
    // Page lines.
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(w * 0.28, h * 0.66), Offset(w * 0.44, h * 0.69), line);
    c.drawLine(Offset(w * 0.56, h * 0.69), Offset(w * 0.72, h * 0.66), line);
  }

  void _chat(Canvas c, double w, double h) {
    // Big bubble.
    _bubble(c, Rect.fromLTWH(w * 0.16, h * 0.22, w * 0.5, h * 0.34),
        primary, tailLeft: true);
    // Small bubble.
    _bubble(c, Rect.fromLTWH(w * 0.52, h * 0.5, w * 0.34, h * 0.24),
        secondary, tailLeft: false);
    // Dots.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (var i = 0; i < 3; i++) {
      c.drawCircle(
          Offset(w * (0.3 + i * 0.1), h * 0.39), w * 0.028, dot);
    }
    final dot2 = Paint()..color = Colors.white.withValues(alpha: 0.9);
    c.drawCircle(Offset(w * 0.62, h * 0.62), w * 0.028, dot2);
    c.drawCircle(Offset(w * 0.7, h * 0.62), w * 0.028, dot2);
  }

  void _bubble(Canvas c, Rect r, Color color, {required bool tailLeft}) {
    final p = Paint()..color = color;
    c.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.18)), p);
    final tail = Path()
      ..moveTo(tailLeft ? r.left + r.width * 0.2 : r.right - r.width * 0.2,
          r.bottom - 2)
      ..lineTo(tailLeft ? r.left + r.width * 0.08 : r.right - r.width * 0.08,
          r.bottom + r.height * 0.22)
      ..lineTo(tailLeft ? r.left + r.width * 0.34 : r.right - r.width * 0.34,
          r.bottom - 2)
      ..close();
    c.drawPath(tail, p);
  }

  void _trophy(Canvas c, double w, double h) {
    final gold = Paint()..color = tertiary;
    // Cup.
    final cup = Path()
      ..moveTo(w * 0.34, h * 0.24)
      ..lineTo(w * 0.66, h * 0.24)
      ..quadraticBezierTo(w * 0.64, h * 0.5, w * 0.5, h * 0.52)
      ..quadraticBezierTo(w * 0.36, h * 0.5, w * 0.34, h * 0.24)
      ..close();
    c.drawPath(cup, gold);
    // Handles.
    final handle = Paint()
      ..color = tertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045;
    c.drawArc(Rect.fromLTWH(w * 0.22, h * 0.26, w * 0.16, h * 0.18),
        math.pi * 0.5, math.pi, false, handle);
    c.drawArc(Rect.fromLTWH(w * 0.62, h * 0.26, w * 0.16, h * 0.18),
        math.pi * 1.5, math.pi, false, handle);
    // Stem + base.
    c.drawRect(Rect.fromLTWH(w * 0.47, h * 0.52, w * 0.06, h * 0.12), gold);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.36, h * 0.64, w * 0.28, h * 0.08),
            const Radius.circular(6)),
        Paint()..color = primary);
    // Star sparkles.
    _sparkle(c, Offset(w * 0.78, h * 0.3), w * 0.05, secondary);
    _sparkle(c, Offset(w * 0.22, h * 0.55), w * 0.04, secondary);
  }

  void _sparkle(Canvas c, Offset o, double r, Color color) {
    final p = Paint()..color = color;
    final path = Path()
      ..moveTo(o.dx, o.dy - r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r);
    c.drawPath(path, p);
  }

  void _compass(Canvas c, double w, double h) {
    // Ring.
    c.drawCircle(
        Offset(w * 0.5, h * 0.5),
        w * 0.3,
        Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.05);
    // Ticks.
    final tick = Paint()
      ..color = primary.withValues(alpha: 0.6)
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = (i / 12) * math.pi * 2;
      c.drawLine(
        Offset(w * 0.5 + w * 0.24 * math.cos(a), h * 0.5 + w * 0.24 * math.sin(a)),
        Offset(w * 0.5 + w * 0.19 * math.cos(a), h * 0.5 + w * 0.19 * math.sin(a)),
        tick,
      );
    }
    // Needle.
    final needle = Path()
      ..moveTo(w * 0.5 + w * 0.16 * math.cos(-0.6), h * 0.5 + w * 0.16 * math.sin(-0.6))
      ..lineTo(w * 0.5 + w * 0.05 * math.cos(2.5), h * 0.5 + w * 0.05 * math.sin(2.5))
      ..lineTo(w * 0.5 + w * 0.16 * math.cos(2.54), h * 0.5 + w * 0.16 * math.sin(2.54))
      ..lineTo(w * 0.5 + w * 0.05 * math.cos(-0.6 + math.pi),
          h * 0.5 + w * 0.05 * math.sin(-0.6 + math.pi))
      ..close();
    c.drawPath(needle, Paint()..color = tertiary);
    c.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.045,
        Paint()..color = secondary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Expressive section header: gradient wash, bold title, optional action.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: AppTheme.washGradient(brightness),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.heroGradient(
                    brightness,
                  ).createShader(bounds),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (subtitle case final sub?) ...[
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing case final t?) t,
        ],
      ),
    );
  }
}

/// Delightful empty state: original illustration + title + body + action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.illustration,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IllustrationKind illustration;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LurniqIllustration(kind: illustration, size: 132),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
