import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../alerts/alert_screen.dart';
import '../chart_lab/chart_lab_screen.dart';
import '../market_context/market_context_screen.dart';
import '../screener/screener_screen.dart';
import '../watchlist/watchlist_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  var _index = 0;

  final _screens = const [
    WatchlistScreen(),
    ScreenerScreen(),
    MarketContextScreen(),
    ChartLabScreen(),
    AlertScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = const [
      NavigationDestination(
        icon: Icon(Icons.bookmark_border),
        selectedIcon: Icon(Icons.bookmark),
        label: 'Watchlist',
      ),
      NavigationDestination(
        icon: Icon(Icons.filter_alt_outlined),
        selectedIcon: Icon(Icons.filter_alt),
        label: 'Screener',
      ),
      NavigationDestination(
        icon: Icon(Icons.public_outlined),
        selectedIcon: Icon(Icons.public),
        label: 'Market',
      ),
      NavigationDestination(
        icon: Icon(Icons.show_chart),
        selectedIcon: Icon(Icons.candlestick_chart),
        label: 'Chart Lab',
      ),
      NavigationDestination(
        icon: Icon(Icons.notifications_none),
        selectedIcon: Icon(Icons.notifications),
        label: 'Alerts',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: const Text('stock-ai-advisor'),
            actions: [
              IconButton(
                tooltip: 'Logout',
                onPressed: () => Supabase.instance.client.auth.signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: (value) =>
                          setState(() => _index = value),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.bookmark_border),
                          selectedIcon: Icon(Icons.bookmark),
                          label: Text('Watchlist'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.filter_alt_outlined),
                          selectedIcon: Icon(Icons.filter_alt),
                          label: Text('Screener'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.public_outlined),
                          selectedIcon: Icon(Icons.public),
                          label: Text('Market'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.show_chart),
                          selectedIcon: Icon(Icons.candlestick_chart),
                          label: Text('Chart Lab'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.notifications_none),
                          selectedIcon: Icon(Icons.notifications),
                          label: Text('Alerts'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: _screens[_index]),
                  ],
                )
              : _screens[_index],
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  destinations: destinations,
                ),
        );
      },
    );
  }
}
