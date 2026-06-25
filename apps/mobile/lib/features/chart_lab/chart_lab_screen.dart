import 'package:flutter/material.dart';

import '../../design_system/ui_components.dart';

class ChartLabScreen extends StatelessWidget {
  const ChartLabScreen({super.key});

  static const _overlays = [
    'EMA',
    'support/resistance',
    'candlestick pattern',
    'harmonic watch',
    'volume-price analysis',
    'SMC confluence',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const AppSectionHeader(
          title: 'Chart Lab',
          subtitle:
              'Provider P2 sudah aktif sebagai delayed context; chart interaktif OHLCV masih tahap integrasi.',
        ),
        const SizedBox(height: 16),
        Card(
          child: AspectRatio(
            aspectRatio: 16 / 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: _PreviewChartPainter(
                  lineColor: scheme.primary,
                  gridColor: scheme.outlineVariant,
                ),
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Provider-backed OHLCV cache sedang disiapkan untuk Chart Lab',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Strategy Overlay',
          subtitle:
              'Preview edukatif berbasis status provider P2; overlay penuh menyusul saat chart OHLCV aktif.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const StatusBadge(label: 'Delayed Live Data'),
              const StatusBadge(label: 'OHLCV cache pending'),
              for (final overlay in _overlays) StatusBadge(label: overlay),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RiskWarningBox(
          level: 'preview',
          message:
              'Data provider P2 sudah aktif sebagai delayed context. Chart Lab saat ini masih preview edukatif sampai endpoint OHLCV siap.',
        ),
      ],
    );
  }
}

class _PreviewChartPainter extends CustomPainter {
  const _PreviewChartPainter({
    required this.lineColor,
    required this.gridColor,
  });

  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var i = 1; i < 7; i++) {
      final x = size.width * i / 7;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final path = Path()
      ..moveTo(0, size.height * 0.66)
      ..lineTo(size.width * 0.14, size.height * 0.58)
      ..lineTo(size.width * 0.28, size.height * 0.62)
      ..lineTo(size.width * 0.42, size.height * 0.42)
      ..lineTo(size.width * 0.58, size.height * 0.48)
      ..lineTo(size.width * 0.72, size.height * 0.34)
      ..lineTo(size.width * 0.88, size.height * 0.38)
      ..lineTo(size.width, size.height * 0.28);
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
