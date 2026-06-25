import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_config.dart';
import '../../core/api/api_result.dart';
import '../../core/api/edge_function_client.dart';
import '../../core/models/market_data_models.dart';
import '../../design_system/ui_components.dart';

class ChartLabScreen extends StatefulWidget {
  const ChartLabScreen({
    super.key,
    this.initialChartData,
    this.api,
    this.autoLoad = true,
  });

  final StockChartDataResponse? initialChartData;
  final EdgeFunctionClient? api;
  final bool autoLoad;

  @override
  State<ChartLabScreen> createState() => _ChartLabScreenState();
}

class _ChartLabScreenState extends State<ChartLabScreen> {
  static const _symbols = ['BBCA', 'BBRI', 'ASII', 'TLKM', 'UNVR'];
  static const _overlays = [
    'EMA',
    'support/resistance',
    'candlestick pattern',
    'harmonic watch',
    'volume-price analysis',
    'SMC confluence',
  ];

  late final EdgeFunctionClient _api;
  StockChartDataResponse? _chartData;
  String _symbolCode = 'BBCA';
  var _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api =
        widget.api ?? EdgeFunctionClient(config: AppConfig.fromEnvironment());
    _chartData = widget.initialChartData;
    _symbolCode = widget.initialChartData?.symbolCode ?? _symbolCode;
    if (widget.autoLoad && _chartData == null && _canAutoLoad()) {
      _loadChartData();
    }
  }

  bool _canAutoLoad() {
    try {
      return AppConfig.fromEnvironment().isConfigured &&
          Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _api.getStockChartData(symbolCode: _symbolCode);
      setState(() => _chartData = result);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chart = _chartData;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppSectionHeader(
          title: 'Chart Lab',
          subtitle:
              'Provider-backed delayed OHLCV data digunakan sebagai konteks edukatif watchlist candidate.',
          trailing: FilledButton.icon(
            onPressed: _isLoading ? null : _loadChartData,
            icon: _isLoading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Load OHLCV'),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Chart Controls',
          subtitle:
              'Data bersifat delayed provider-backed, bukan real-time trading data.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _symbolCode,
                  decoration: const InputDecoration(labelText: 'Symbol'),
                  items: _symbols
                      .map(
                        (symbol) => DropdownMenuItem(
                          value: symbol,
                          child: Text(symbol),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() => _symbolCode = value ?? _symbolCode);
                          if (_canAutoLoad()) _loadChartData();
                        },
                ),
              ),
              const StatusBadge(label: 'Delayed provider-backed data'),
              if (chart != null && chart.hasBars)
                StatusBadge(label: '${chart.barCount} OHLCV bars')
              else
                const StatusBadge(label: 'OHLCV cache pending'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_error != null)
          RiskWarningBox(level: 'medium', message: _error!)
        else if (chart != null && chart.hasBars)
          _ProviderBackedChart(chart: chart)
        else
          const _EmptyOhlcvPreview(),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Strategy Overlay',
          subtitle:
              'Overlay masih edukatif. Rule engine dan indikator lanjutan tetap berada di backend.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final overlay in _overlays) StatusBadge(label: overlay),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CompactRiskWarningList(
          items:
              chart?.riskWarnings
                  .map(
                    (warning) => CompactRiskWarningItem(
                      level: warning.level,
                      message: warning.message,
                    ),
                  )
                  .toList() ??
              const [
                CompactRiskWarningItem(
                  level: 'medium',
                  message:
                      'OHLCV cache belum dimuat. Jalankan Load OHLCV untuk membaca cache provider-backed.',
                ),
              ],
        ),
      ],
    );
  }
}

class _ProviderBackedChart extends StatelessWidget {
  const _ProviderBackedChart({required this.chart});

  final StockChartDataResponse chart;

  @override
  Widget build(BuildContext context) {
    final latest = chart.bars.last;
    return SectionCard(
      title: '${chart.symbolCode} OHLCV',
      subtitle:
          '${humanizeUiText(chart.dataQuality)} - ${humanizeUiText(chart.providerName)} - ${formatWibTimestamp(latest.observedAt)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: _OhlcvChartPainter(
                  bars: chart.bars,
                  upColor: Theme.of(context).colorScheme.tertiary,
                  downColor: Theme.of(context).colorScheme.error,
                  gridColor: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            children: [
              MetricTile(label: 'Open', value: latest.open),
              MetricTile(label: 'High', value: latest.high),
              MetricTile(label: 'Low', value: latest.low),
              MetricTile(label: 'Close', value: latest.close),
              MetricTile(label: 'Volume', value: latest.volume),
              MetricTile(label: 'Timeframe', value: chart.timeframe),
            ],
          ),
          const SizedBox(height: 12),
          Text(chart.disclaimer),
        ],
      ),
    );
  }
}

class _EmptyOhlcvPreview extends StatelessWidget {
  const _EmptyOhlcvPreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
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
                    'OHLCV cache belum tersedia untuk chart interaktif. Jalankan sync market data lalu Load OHLCV.',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OhlcvChartPainter extends CustomPainter {
  const _OhlcvChartPainter({
    required this.bars,
    required this.upColor,
    required this.downColor,
    required this.gridColor,
  });

  final List<OhlcvBar> bars;
  final Color upColor;
  final Color downColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final visibleBars = bars.length > 40
        ? bars.sublist(bars.length - 40)
        : bars;
    if (visibleBars.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final highest = visibleBars.map((bar) => bar.high).reduce(math.max);
    final lowest = visibleBars.map((bar) => bar.low).reduce(math.min);
    final range = (highest - lowest).abs() == 0 ? 1 : highest - lowest;
    final slot = size.width / visibleBars.length;
    final candleWidth = math.max(3.0, slot * 0.46);

    double yFor(num price) {
      return size.height - ((price - lowest) / range * size.height);
    }

    for (var i = 0; i < visibleBars.length; i++) {
      final bar = visibleBars[i];
      final x = slot * i + slot / 2;
      final isUp = bar.close >= bar.open;
      final paint = Paint()
        ..color = isUp ? upColor : downColor
        ..strokeWidth = 1.4;
      final highY = yFor(bar.high);
      final lowY = yFor(bar.low);
      final openY = yFor(bar.open);
      final closeY = yFor(bar.close);
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), paint);
      final top = math.min(openY, closeY);
      final bottom = math.max(openY, closeY);
      final body = Rect.fromLTRB(
        x - candleWidth / 2,
        top,
        x + candleWidth / 2,
        math.max(bottom, top + 2),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OhlcvChartPainter oldDelegate) {
    return oldDelegate.bars != bars;
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
