import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/push_service.dart';

import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_screen.dart';
import '../leads/lead_detail_screen.dart';
import '../leads/lead_model.dart';
import '../leads/leads_controller.dart';
import '../leads/leads_screen.dart';
import '../profile/profile_screen.dart';
import '../today/today_controller.dart';
import '../today/today_screen.dart';
import '../visits/visits_screen.dart';

/// Signed-in home: bottom navigation with Today, Leads, Visits, Dashboard
/// and Profile.
/// Tabs live in an IndexedStack so each keeps its state.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.fullName,
    this.startOffline = false,
    this.todayController,
  });

  final String fullName;

  /// The start-up session check could not reach the server; the user stays
  /// signed in and a small offline banner is shown until data loads.
  final bool startOffline;

  /// Injectable for tests; created internally otherwise.
  final TodayController? todayController;

  static const int todayTab = 0;
  static const int leadsTab = 1;
  static const int dashboardTab = 3;
  static const int initialTab = todayTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = AppShell.initialTab;
  late bool _offline = widget.startOffline;

  /// Shared by the Today tab and its bottom-nav badge.
  late final TodayController _today =
      widget.todayController ?? TodayController();

  /// Owned here so a dashboard bar can open Leads with a filter applied.
  final LeadsController _leads = LeadsController();
  final DashboardController _dashboard = DashboardController();

  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () {
      if (_index == AppShell.todayTab) _today.refresh();
      // The user may have changed notification permission in settings.
      PushService.instance.refreshPermissionStatus();
      // A device registration that failed (e.g. offline) is retried once.
      PushService.instance.retryRegistrationIfNeeded();
    },
  );

  late final List<Widget> _tabs = [
    TodayScreen(controller: _today),
    LeadsScreen(controller: _leads),
    const VisitsScreen(),
    DashboardScreen(controller: _dashboard, onOpenLeads: _openLeads),
    ProfileScreen(fullName: widget.fullName),
  ];

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
    _today.addListener(_onTodayChanged);
    _today.load();

    // Signed in (fresh login or restored session): register this device.
    PushService.instance.registerDevice();
    _newLeads = PushService.instance.newLeads.listen((_) => _refreshLists());
    PushService.instance.leadToOpen.addListener(_openPendingLead);
    // A notification tapped while the app was closed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingLead());
  }

  StreamSubscription<String>? _newLeads;

  /// A new lead arrived while the app is open.
  void _refreshLists() {
    _leads.refresh(keepItems: true);
    _today.refresh();
  }

  /// Opens the lead from a tapped notification (only ever while signed in,
  /// because the shell only exists then).
  void _openPendingLead() {
    final name = PushService.instance.leadToOpen.value;
    if (name == null || !mounted) return;
    PushService.instance.leadToOpen.value = null;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeadDetailScreen(
          lead: CrmLead(name: name),
          onLeadChanged: _refreshLists,
        ),
      ),
    );
  }

  /// Hide the offline banner once the server answers again.
  void _onTodayChanged() {
    if (_offline && _today.hasLoaded && _today.error == null) {
      setState(() => _offline = false);
    }
  }

  @override
  void dispose() {
    _newLeads?.cancel();
    PushService.instance.leadToOpen.removeListener(_openPendingLead);
    _today.removeListener(_onTodayChanged);
    _lifecycle.dispose();
    if (widget.todayController == null) _today.dispose();
    _leads.dispose();
    _dashboard.dispose();
    super.dispose();
  }

  void _select(int index) {
    // Coming back to Today: refresh it.
    if (index == AppShell.todayTab && _index != AppShell.todayTab) {
      _today.refresh();
    }
    // The dashboard loads on first visit, not at start-up.
    if (index == AppShell.dashboardTab && !_dashboard.hasLoaded) {
      _dashboard.load();
    }
    setState(() => _index = index);
  }

  void _openLeads({String? status, String? source, String? district}) {
    _leads.applyFilter(status: status, source: source, district: district);
    setState(() => _index = AppShell.leadsTab);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: ListenableBuilder(
        listenable: _today,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_offline) _OfflineBanner(message: l10n.offlineBanner),
            NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                NavigationDestination(
                  icon: _TodayBadge(
                    count: _today.pendingCalls,
                    child: const Icon(Icons.today_outlined),
                  ),
                  selectedIcon: _TodayBadge(
                    count: _today.pendingCalls,
                    child: const Icon(Icons.today),
                  ),
                  label: l10n.tabToday,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.people_alt_outlined),
                  selectedIcon: const Icon(Icons.people_alt),
                  label: l10n.tabLeads,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.place_outlined),
                  selectedIcon: const Icon(Icons.place),
                  label: l10n.tabVisits,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.insights_outlined),
                  selectedIcon: const Icon(Icons.insights),
                  label: l10n.tabDashboard,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: l10n.tabProfile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const foreground = Color(0xFF7A4100); // 7:1 on the background
    return Semantics(
      liveRegion: true,
      child: Material(
        color: const Color(0xFFFFF4E5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_outlined, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small red count on the Today icon; hidden at zero.
class _TodayBadge extends StatelessWidget {
  const _TodayBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: count > 0
          ? AppLocalizations.of(context)!.todayPendingCount(count)
          : null,
      child: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        backgroundColor: const Color(0xFFB42318),
        textColor: Colors.white,
        child: child,
      ),
    );
  }
}
