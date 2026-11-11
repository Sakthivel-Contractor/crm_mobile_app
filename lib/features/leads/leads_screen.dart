import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/app_error.dart';
import '../../l10n/app_localizations.dart';
import '../auth/sign_out.dart';
import 'lead_detail_screen.dart';
import 'lead_model.dart';
import 'lead_repository.dart';
import 'leads_controller.dart';
import 'widgets/lead_card.dart';
import 'widgets/status_filter_bar.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key, this.controller});

  /// Injectable for tests; created internally otherwise.
  final LeadsController? controller;

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  late final LeadsController _controller =
      widget.controller ?? LeadsController();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searching = false;

  /// Start loading the next page this many pixels before the end.
  static const double _loadMoreThreshold = 400;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _controller.addListener(_syncSearchBox);
    _controller.init();
  }

  /// A filter applied from elsewhere (dashboard) clears the search.
  void _syncSearchBox() {
    if (_controller.search.isEmpty &&
        _searching &&
        _searchController.text.isNotEmpty &&
        !_searchFocus.hasFocus) {
      _searchController.clear();
      setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncSearchBox);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      _controller.loadMore();
    }
  }

  void _openSearch() {
    setState(() => _searching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchController.clear();
    _controller.setSearch('');
    setState(() => _searching = false);
  }

  void _openLead(CrmLead lead) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeadDetailScreen(
          lead: lead,
          onLeadChanged: () => _controller.refresh(keepItems: true),
        ),
      ),
    );
  }

  void _showComingSoon() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  Future<void> _loginAgain() => signOutToLogin(context);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: _showComingSoon,
        tooltip: l10n.newLead,
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = centeredContentPadding(constraints.maxWidth);
          return ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => Column(
              children: [
                StatusFilterBar(
                  statuses: _controller.statuses,
                  selected: _controller.status,
                  onSelected: _controller.setStatus,
                  padding: padding,
                  leading: [
                    if (_controller.source != null)
                      AppChip(
                        label: l10n.filterSourceChip(_controller.source!),
                        selected: true,
                        trailingIcon: Icons.close,
                        onTap: _controller.clearSource,
                      ),
                    if (_controller.district != null)
                      AppChip(
                        label: l10n.filterDistrictChip(_controller.district!),
                        selected: true,
                        trailingIcon: Icons.close,
                        onTap: _controller.clearDistrict,
                      ),
                  ],
                ),
                Expanded(child: _buildBody(l10n, padding)),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    if (!_searching) {
      return AppBar(
        title: Text(l10n.leadsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.search,
            onPressed: _openSearch,
          ),
        ],
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        inputFormatters: [
          LengthLimitingTextInputFormatter(LeadRepository.maxSearchLength),
        ],
        onChanged: _controller.setSearch,
        textInputAction: TextInputAction.search,
        cursorColor: Colors.white,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: Colors.white),
        decoration: InputDecoration(
          hintText: l10n.searchLeadsHint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.14),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          constraints: const BoxConstraints(maxHeight: 44),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            borderSide: const BorderSide(color: Colors.white70),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.closeSearch,
          onPressed: _closeSearch,
        ),
      ],
    );
  }

  Widget _buildBody(AppLocalizations l10n, EdgeInsets padding) {
    final c = _controller;
    final listPadding = padding.copyWith(top: 0, bottom: 96); // clear the FAB

    if (c.isLoading && c.items.isEmpty) {
      return LeadSkeletonList(padding: listPadding);
    }

    if (c.items.isEmpty) {
      final error = c.error;
      final Widget message = error == null
          ? StateMessage(
              icon: Icons.person_search_outlined,
              title: l10n.noLeads,
              message: l10n.noLeadsHint,
            )
          : StateMessage(
              icon: error == AppError.network
                  ? Icons.wifi_off_rounded
                  : Icons.cloud_off_outlined,
              title: appErrorMessage(l10n, error),
              actionLabel: error == AppError.unauthorized
                  ? l10n.loginAgain
                  : l10n.retry,
              onAction: error == AppError.unauthorized ? _loginAgain : c.retry,
            );

      // Scrollable so pull-to-refresh works on the empty/error state too.
      return RefreshIndicator(
        onRefresh: () => c.refresh(keepItems: true),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: message),
            ),
          ),
        ),
      );
    }

    // Header: refresh error while old items are still shown.
    final hasHeader = c.error != null;
    final footer = _buildFooter(l10n);
    final count =
        c.items.length + (hasHeader ? 1 : 0) + (footer == null ? 0 : 1);

    return RefreshIndicator(
      onRefresh: () => c.refresh(keepItems: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: listPadding,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (hasHeader) {
            if (index == 0) {
              return _InlineError(
                message: appErrorMessage(l10n, c.error!),
                actionLabel: l10n.retry,
                onAction: c.retry,
              );
            }
            index--;
          }
          if (index >= c.items.length) return footer!;
          final lead = c.items[index];
          return LeadCard(
            lead: lead,
            status: c.statusNamed(lead.status),
            onTap: () => _openLead(lead),
          );
        },
      ),
    );
  }

  /// Loader, load-more error, or nothing.
  Widget? _buildFooter(AppLocalizations l10n) {
    final c = _controller;
    if (c.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (c.loadMoreError != null) {
      return _InlineError(
        message: l10n.loadMoreFailed,
        actionLabel: l10n.retry,
        onAction: c.retryLoadMore,
      );
    }
    return null;
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    const errorText = Color(0xFFB42318);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEA),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: errorText, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: errorText),
              ),
            ),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: errorText),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
