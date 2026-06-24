import 'package:flutter/material.dart';

import '../../app/app_config.dart';
import '../../core/api/api_result.dart';
import '../../core/api/edge_function_client.dart';
import '../../design_system/ui_components.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  late final EdgeFunctionClient _api;
  final _symbolController = TextEditingController(text: 'BBCA');
  final _nameController = TextEditingController(
    text: 'BBCA risk warning watch',
  );
  var _alertType = 'risk_warning';
  var _metric = 'risk_score';
  var _operator = 'lt';
  final _valueController = TextEditingController(text: '55');
  var _isLoading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _api = EdgeFunctionClient(config: AppConfig.fromEnvironment());
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _createAlert() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final value = num.tryParse(_valueController.text.trim());
      await _api.post(
        'create-alert',
        body: {
          'symbol_code': _symbolController.text.trim().toUpperCase(),
          'name': _nameController.text.trim(),
          'alert_type': _alertType,
          'conditions': [
            {'metric': _metric, 'operator': _operator, 'value_numeric': value},
          ],
        },
      );
      setState(() => _success = 'Smart alert berhasil dibuat.');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const AppSectionHeader(
          title: 'Smart Alert',
          subtitle:
              'Buat alert berbasis risk warning, technical setup, score, dan invalidation level.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _symbolController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Symbol'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Alert name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _alertType,
                  decoration: const InputDecoration(labelText: 'Alert type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'risk_warning',
                      child: Text('risk warning'),
                    ),
                    DropdownMenuItem(
                      value: 'technical_setup',
                      child: Text('technical setup'),
                    ),
                    DropdownMenuItem(value: 'score', child: Text('score')),
                    DropdownMenuItem(
                      value: 'invalidation',
                      child: Text('Invalidation'),
                    ),
                    DropdownMenuItem(value: 'volume', child: Text('volume')),
                  ],
                  onChanged: (value) =>
                      setState(() => _alertType = value ?? _alertType),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _metric,
                        decoration: const InputDecoration(labelText: 'Metric'),
                        items: const [
                          DropdownMenuItem(
                            value: 'risk_score',
                            child: Text('Risk'),
                          ),
                          DropdownMenuItem(
                            value: 'technical_score',
                            child: Text('Technical'),
                          ),
                          DropdownMenuItem(
                            value: 'final_score',
                            child: Text('Final'),
                          ),
                          DropdownMenuItem(
                            value: 'volume_ratio',
                            child: Text('Volume Ratio'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _metric = value ?? _metric),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 130,
                      child: DropdownButtonFormField<String>(
                        initialValue: _operator,
                        decoration: const InputDecoration(
                          labelText: 'Operator',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'lt', child: Text('<')),
                          DropdownMenuItem(value: 'lte', child: Text('<=')),
                          DropdownMenuItem(value: 'gt', child: Text('>')),
                          DropdownMenuItem(value: 'gte', child: Text('>=')),
                          DropdownMenuItem(value: 'eq', child: Text('=')),
                        ],
                        onChanged: (value) =>
                            setState(() => _operator = value ?? _operator),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _valueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Value'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _createAlert,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Create Smart Alert'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          AsyncStateView(title: 'Alert gagal dibuat', message: _error),
        ],
        if (_success != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_success!),
            ),
          ),
        ],
      ],
    );
  }
}
