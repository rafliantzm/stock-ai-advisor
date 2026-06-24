import 'package:flutter/material.dart';

import '../../../design_system/ui_components.dart';

class RiskCalculatorCard extends StatefulWidget {
  const RiskCalculatorCard({super.key, required this.defaultInvalidationLevel});

  final Object? defaultInvalidationLevel;

  @override
  State<RiskCalculatorCard> createState() => _RiskCalculatorCardState();
}

class _RiskCalculatorCardState extends State<RiskCalculatorCard> {
  final _capitalController = TextEditingController(text: '10000000');
  final _riskPercentController = TextEditingController(text: '1');
  final _observationPriceController = TextEditingController(text: '1000');
  late final TextEditingController _invalidationPriceController;

  @override
  void initState() {
    super.initState();
    final fallback = widget.defaultInvalidationLevel is num
        ? widget.defaultInvalidationLevel.toString()
        : '950';
    _invalidationPriceController = TextEditingController(text: fallback);
  }

  @override
  void dispose() {
    _capitalController.dispose();
    _riskPercentController.dispose();
    _observationPriceController.dispose();
    _invalidationPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capital = num.tryParse(_capitalController.text) ?? 0;
    final riskPercent = num.tryParse(_riskPercentController.text) ?? 0;
    final observationPrice =
        num.tryParse(_observationPriceController.text) ?? 0;
    final invalidationPrice =
        num.tryParse(_invalidationPriceController.text) ?? 0;
    final riskAmount = capital * riskPercent / 100;
    final riskPerUnit = (observationPrice - invalidationPrice).abs();
    final estimatedSize = riskPerUnit == 0 ? 0 : riskAmount / riskPerUnit;

    return SectionCard(
      title: 'Calculator Edukatif',
      subtitle: 'Simulasi edukatif, bukan instruksi transaksi.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _NumberField(
                label: 'Modal observasi',
                controller: _capitalController,
                onChanged: () => setState(() {}),
              ),
              _NumberField(
                label: 'risk_percent',
                controller: _riskPercentController,
                onChanged: () => setState(() {}),
              ),
              _NumberField(
                label: 'observation_price',
                controller: _observationPriceController,
                onChanged: () => setState(() {}),
              ),
              _NumberField(
                label: 'invalidation_price',
                controller: _invalidationPriceController,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ResponsiveGrid(
            children: [
              MetricTile(label: 'risk_amount', value: riskAmount.round()),
              MetricTile(label: 'risk_per_unit', value: riskPerUnit),
              MetricTile(
                label: 'estimated_position_size',
                value: estimatedSize.floor(),
                helper: 'Unit teoritis dari batas risiko',
              ),
            ],
          ),
          const SizedBox(height: 12),
          RiskWarningBox(
            level: 'education',
            message:
                'Simulasi edukatif, bukan instruksi transaksi. Sesuaikan dengan risk profile dan validasi mandiri.',
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
