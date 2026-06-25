import 'package:flutter/material.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.title,
    this.message,
    this.action,
  });

  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message!, textAlign: TextAlign.center),
              ],
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class ScorePill extends StatelessWidget {
  const ScorePill({super.key, required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text('$label ${_displayValue(value)}'),
      backgroundColor: scheme.surfaceContainerHighest,
      visualDensity: VisualDensity.compact,
    );
  }

  static String _displayValue(Object? value) {
    if (value == null) return 'Menunggu data';
    final text = value.toString().trim();
    if (text.isEmpty || text == '-') return 'Menunggu data';
    return humanizeUiText(text);
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          humanizeUiText(label),
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.helper,
  });

  final String label;
  final Object? value;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(
              _displayValue(value),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (helper != null) ...[
              const SizedBox(height: 4),
              Text(helper!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  static String _displayValue(Object? value) {
    if (value == null) return 'Menunggu data';
    final text = value.toString().trim();
    if (text.isEmpty || text == '-') return 'Menunggu data';
    return humanizeUiText(text);
  }
}

class RiskWarningBox extends StatelessWidget {
  const RiskWarningBox({super.key, required this.message, this.level});

  final String message;
  final String? level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final severity = _riskSeverityColors(scheme, level);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: severity.container,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severity.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: severity.icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level == null
                        ? 'risk warning'
                        : 'risk warning - ${humanizeUiText(level!)}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: severity.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    humanizeUiText(message),
                    style: TextStyle(color: severity.foreground),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactRiskWarningList extends StatelessWidget {
  const CompactRiskWarningList({super.key, required this.items});

  final List<CompactRiskWarningItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final severity = _riskSeverityColors(scheme, _highestRiskSeverity(items));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: severity.container,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severity.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'risk warning',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: severity.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) {
                        final itemSeverity = _riskSeverityColors(
                          scheme,
                          item.level,
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: itemSeverity.icon.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            humanizeUiText(item.level),
                            // Level labels are intentionally compact, but still
                            // humanized so backend enum names do not leak.
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: itemSeverity.foreground),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        humanizeUiText(item.message),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: severity.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String humanizeUiText(Object? value) {
  if (value == null) return 'Menunggu data';
  final text = value.toString().trim();
  if (text.isEmpty || text == '-') return 'Menunggu data';
  final timestamp = formatWibTimestamp(text);
  if (timestamp != text) return timestamp;
  final normalized = text.toLowerCase();
  const exact = {
    'needs_more_data': 'Data belum cukup',
    'p0_dummy_scoring_v1': 'Rule scoring awal',
    'sample_provider': 'Fallback sample provider',
    'mixed_live_providers': 'Multi-provider live data',
    'provider_chain_resolved': 'Provider live tersambung',
    'alpha_vantage': 'Alpha Vantage',
    'twelve_data': 'Twelve Data',
    'eodhd': 'EODHD',
    'delayed': 'Delayed provider-backed data',
    'delayed live data': 'Delayed provider-backed data',
    'live': 'Provider-backed data',
    'live provider': 'Provider-backed delayed',
    'stale': 'Stale',
    'sample': 'Sample data',
    'provider_backed_context': 'Provider-backed context',
    'p2_provider_indicator_contract_v1': 'Rule indikator provider P2',
    'p2_sample_indicator_v1': 'Rule indikator sample P2',
  };
  final mapped = exact[normalized];
  if (mapped != null) return mapped;
  return text.replaceAll('_', ' ');
}

String formatWibTimestamp(Object? value) {
  if (value == null) return 'Menunggu data';
  final text = value.toString().trim();
  if (text.isEmpty || text == '-') return 'Menunggu data';
  final looksLikeTimestamp =
      text.contains('T') ||
      RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}').hasMatch(text);
  if (!looksLikeTimestamp) return text;

  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  final wib = parsed.toUtc().add(const Duration(hours: 7));
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final hour = wib.hour.toString().padLeft(2, '0');
  final minute = wib.minute.toString().padLeft(2, '0');
  return '${wib.day} ${months[wib.month - 1]} ${wib.year}, $hour:$minute WIB';
}

String riskSeverityBand(Object? level) {
  final text = level?.toString().toLowerCase().trim() ?? '';
  if (text.contains('high') ||
      text.contains('tinggi') ||
      text.contains('critical') ||
      text.contains('error') ||
      text.contains('gagal')) {
    return 'high';
  }
  if (text.contains('low') ||
      text.contains('rendah') ||
      text.contains('info') ||
      text.contains('success') ||
      text.contains('delayed') ||
      text.contains('education') ||
      text.contains('preview')) {
    return 'low';
  }
  return 'medium';
}

String _highestRiskSeverity(List<CompactRiskWarningItem> items) {
  var highest = 'low';
  for (final item in items) {
    final severity = riskSeverityBand(item.level);
    if (severity == 'high') return 'high';
    if (severity == 'medium') highest = 'medium';
  }
  return highest;
}

_RiskSeverityColors _riskSeverityColors(ColorScheme scheme, Object? level) {
  switch (riskSeverityBand(level)) {
    case 'high':
      return _RiskSeverityColors(
        container: scheme.errorContainer.withValues(alpha: 0.62),
        border: scheme.error.withValues(alpha: 0.45),
        foreground: scheme.onErrorContainer,
        icon: scheme.error,
      );
    case 'medium':
      return _RiskSeverityColors(
        container: Color.alphaBlend(
          Colors.amber.withValues(alpha: 0.20),
          scheme.surface,
        ),
        border: Colors.orange.withValues(alpha: 0.42),
        foreground: scheme.onSurface,
        icon: Colors.orange.shade700,
      );
    default:
      return _RiskSeverityColors(
        container: Color.alphaBlend(
          scheme.tertiary.withValues(alpha: 0.12),
          scheme.surface,
        ),
        border: scheme.tertiary.withValues(alpha: 0.32),
        foreground: scheme.onSurface,
        icon: scheme.tertiary,
      );
  }
}

class _RiskSeverityColors {
  const _RiskSeverityColors({
    required this.container,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color container;
  final Color border;
  final Color foreground;
  final Color icon;
}

class CompactRiskWarningItem {
  const CompactRiskWarningItem({required this.level, required this.message});

  final String level;
  final String message;
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minWidth = 180,
  });

  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minWidth).floor().clamp(1, 4);
        return GridView.count(
          crossAxisCount: columns,
          mainAxisExtent: 148,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}
