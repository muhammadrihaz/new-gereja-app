import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../core/date_format.dart';
import '../core/models.dart';
import '../core/session_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/skeleton_list.dart';

/// Modern events list with:
/// - Infinite scroll pagination via `eventsPaginated`.
/// - Search (server-side).
/// - Skeleton loader, error state, empty state, pull-to-refresh.
/// - Admin-only "Arsip" tab; jemaat sees only upcoming/ongoing.
class JemaatEventsPage extends StatefulWidget {
  const JemaatEventsPage({super.key, required this.session});

  final SessionController session;

  @override
  State<JemaatEventsPage> createState() => _JemaatEventsPageState();
}

class _JemaatEventsPageState extends State<JemaatEventsPage>
    with SingleTickerProviderStateMixin {
  static const int _perPage = 15;

  late final ApiClient _api;
  late final TabController _tabController;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  ApiError? _error;
  String _searchQuery = '';
  int _searchToken = 0;

  bool get _isAdmin => widget.session.role == UserRole.admin;
  String get _statusFilter {
    if (!_isAdmin) return 'active';
    return _tabController.index == 0 ? 'active' : 'archived';
  }

  @override
  void initState() {
    super.initState();
    _api = widget.session.apiClient;
    _tabController = TabController(length: _isAdmin ? 2 : 1, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _refresh(reset: true);
    });
    _scroll.addListener(_onScroll);
    _refresh(reset: true);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore &&
        !_loading) {
      _loadMore();
    }
  }

  Future<void> _refresh({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items.clear();
        _page = 1;
        _hasMore = true;
      });
    }
    final token = widget.session.token ?? '';
    if (token.isEmpty) {
      setState(() {
        _loading = false;
        _error = const ApiError(
          message: 'Sesi Anda telah berakhir. Silakan login ulang.',
          statusCode: 401,
        );
      });
      return;
    }

    try {
      final result = await _api.eventsPaginated(
        token: token,
        page: 1,
        perPage: _perPage,
        status: _statusFilter,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(result.items);
        _page = 1;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiError(message: 'Gagal memuat event: $e');
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final token = widget.session.token ?? '';
    if (token.isEmpty) return;

    setState(() {
      _loadingMore = true;
    });
    try {
      final nextPage = _page + 1;
      final result = await _api.eventsPaginated(
        token: token,
        page: nextPage,
        perPage: _perPage,
        status: _statusFilter,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _page = nextPage;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _hasMore = false; // stop retrying automatically; user can pull-to-refresh
      });
    }
  }

  void _onSearchChanged(String value) {
    final normalized = value.trim();
    _searchQuery = normalized;
    final token = ++_searchToken;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || token != _searchToken) return;
      _refresh(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _searchCtrl,
                  hintText: 'Cari event...',
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.search),
                  ),
                  trailing: _searchQuery.isEmpty
                      ? const []
                      : [
                          IconButton(
                            tooltip: 'Hapus',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          ),
                        ],
                  onChanged: _onSearchChanged,
                ),
              ),
            ],
          ),
        ),
        if (_isAdmin)
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Aktif'),
              Tab(text: 'Arsip'),
            ],
          ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const SkeletonList(itemHeight: 96);
    }
    if (_error != null && _items.isEmpty) {
      return ErrorStateView(
        error: _error,
        onRetry: () => _refresh(reset: true),
      );
    }
    if (_items.isEmpty) {
      return EmptyStateView(
        icon: _statusFilter == 'archived'
            ? Icons.archive_outlined
            : Icons.event_available_outlined,
        title: _statusFilter == 'archived'
            ? 'Belum ada arsip'
            : 'Belum ada event',
        description: _searchQuery.isEmpty
            ? 'Event akan tampil di sini saat dijadwalkan pengurus.'
            : 'Coba kata kunci lain.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(reset: true),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _EventCard(event: _items[index]);
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = (event['title'] as String?) ?? 'Tanpa Judul';
    final description = (event['description'] as String?) ?? '';
    final startAtStr = (event['start_at'] as String?) ?? (event['date'] as String?);
    final endAtStr = event['end_at'] as String?;
    final isArchived = event['is_archived'] == true;
    final isExpired = event['is_expired'] == true;
    final category = (event['category'] as String?) ?? '';
    final location = event['location'];
    String locationAddress = '';
    if (location is Map<String, dynamic>) {
      locationAddress = (location['address'] as String?) ?? '';
    } else if (location is String) {
      locationAddress = location;
    }

    final startAt = _parseDate(startAtStr);
    final endAt = _parseDate(endAtStr);
    final dateLine = _formatDateRange(startAt, endAt);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EventDateBadge(startAt: startAt),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isArchived)
                          _Chip(
                            label: 'Arsip',
                            icon: Icons.archive_outlined,
                            color: scheme.secondary,
                          )
                        else if (isExpired)
                          _Chip(
                            label: 'Selesai',
                            icon: Icons.check_circle_outline,
                            color: scheme.tertiary,
                          ),
                      ],
                    ),
                    if (dateLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dateLine,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (locationAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _Chip(label: _formatCategory(category), color: scheme.primary),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  static String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return '';
    final startStr = formatTanggalString(start.toIso8601String(), includeTime: true);
    if (end == null) return startStr;
    // Same day: show time only for end
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      final endTime = DateFormat.Hm().format(end);
      return '$startStr – $endTime';
    }
    return '$startStr → ${formatTanggalString(end.toIso8601String(), includeTime: true)}';
  }

  static String _formatCategory(String c) {
    if (c.isEmpty) return c;
    return c.split('_').map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1))).join(' ');
  }
}

class _EventDateBadge extends StatelessWidget {
  const _EventDateBadge({required this.startAt});
  final DateTime? startAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (startAt == null) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.event, color: scheme.onSurfaceVariant),
      );
    }
    final day = DateFormat.d().format(startAt!);
    final month = DateFormat.MMM('id_ID').format(startAt!).toUpperCase();
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          Text(
            month,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon, required this.color});
  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Ensure the CachedImage widget stays available for future thumbnails; the
// jemaat events list intentionally uses a text-first layout for density.
