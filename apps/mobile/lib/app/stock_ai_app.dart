import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design_system/huashu_theme.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_shell.dart';
import 'app_config.dart';

class StockAiApp extends StatefulWidget {
  const StockAiApp({super.key, required this.config, this.initError});

  final AppConfig config;
  final String? initError;

  @override
  State<StockAiApp> createState() => _StockAiAppState();
}

class _StockAiAppState extends State<StockAiApp> {
  Session? _session;

  @override
  void initState() {
    super.initState();
    if (widget.config.isConfigured && widget.initError == null) {
      final auth = Supabase.instance.client.auth;
      _session = auth.currentSession;
      auth.onAuthStateChange.listen((event) {
        if (mounted) setState(() => _session = event.session);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'stock-ai-advisor',
      debugShowCheckedModeBanner: false,
      theme: HuashuTheme.light(),
      darkTheme: HuashuTheme.dark(),
      themeMode: ThemeMode.dark,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!widget.config.isConfigured) {
      return const _SetupErrorScreen(
        title: 'Supabase env belum diisi',
        message:
            'Jalankan Flutter dengan SUPABASE_URL dan SUPABASE_ANON_KEY. Service role key tidak boleh dipakai di Flutter.',
      );
    }

    if (widget.initError != null) {
      return _SetupErrorScreen(
        title: 'Supabase gagal diinisialisasi',
        message:
            'Periksa SUPABASE_URL, SUPABASE_ANON_KEY, dan koneksi project Supabase.',
        details: widget.initError,
      );
    }

    return _session == null ? const LoginScreen() : const DashboardShell();
  }
}

class _SetupErrorScreen extends StatelessWidget {
  const _SetupErrorScreen({
    required this.title,
    required this.message,
    this.details,
  });

  final String title;
  final String message;
  final String? details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(message),
                  const SizedBox(height: 16),
                  const SelectableText(
                    'flutter run -d chrome '
                    '--dart-define=SUPABASE_URL=https://PROJECT.supabase.co '
                    '--dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY',
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Detail error',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(details!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
