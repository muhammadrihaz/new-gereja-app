import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../core/api_client.dart';
import '../core/date_format.dart';
import '../core/file_download.dart';
import '../core/models.dart';
import '../core/session_controller.dart';
import '../widgets/cached_image.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/skeleton_list.dart';

/// Modern news list page. Uses `newsPaginated` (server-side search + pagination),
/// infinite scroll, cached cover images, skeleton loader, error state, and a
/// dedicated detail page with hero image, gallery and downloadable attachments.
class JemaatBeritaPage extends StatefulWidget {
  const JemaatBeritaPage({super.key, required this.session});

  final SessionController session;

  @override
  State<JemaatBeritaPage> createState() => _JemaatBeritaPageState();
}

class _JemaatBeritaPageState extends State<JemaatBeritaPage> {
  static const int _perPage = 12;

  late final ApiClient _api;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  ApiError? _error;
  String _searchQuery = '';
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _api = widget.session.apiClient;

    // Register Bahasa Indonesia locale for relative time strings (safe to call
    // multiple times; timeago dedupes internally).
    timeago.setLocaleMessages('id', timeago.IdMessages());

    _scroll.addListener(_onScroll);
    _refresh(reset: true);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240 &&
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
      final result = await _api.newsPaginated(
        token: token,
        page: 1,
        perPage: _perPage,
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
        _error = ApiError(message: 'Gagal memuat berita: $e');
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
      final result = await _api.newsPaginated(
        token: token,
        page: nextPage,
        perPage: _perPage,
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
        _hasMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchQuery = value.trim();
    final token = ++_searchToken;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || token != _searchToken) return;
      _refresh(reset: true);
    });
  }

  void _openDetail(Map<String, dynamic> summary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JemaatBeritaDetailPage(
          session: widget.session,
          newsId: (summary['id'] as num).toInt(),
          initialSummary: summary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: SearchBar(
            controller: _searchCtrl,
            hintText: 'Cari berita...',
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
            backgroundColor: WidgetStatePropertyAll(
              theme.colorScheme.surfaceContainerLow,
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const SkeletonList(itemHeight: 220);
    }
    if (_error != null && _items.isEmpty) {
      return ErrorStateView(
        error: _error,
        onRetry: () => _refresh(reset: true),
      );
    }
    if (_items.isEmpty) {
      return EmptyStateView(
        icon: Icons.newspaper_outlined,
        title: _searchQuery.isEmpty
            ? 'Belum ada berita'
            : 'Tidak ada hasil pencarian',
        description: _searchQuery.isEmpty
            ? 'Berita dari pengurus akan tampil di sini.'
            : 'Coba kata kunci lain.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(reset: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Adaptive: single column on mobile, 2-col on tablet, 3-col on desktop.
          final columns = width < 640
              ? 1
              : width < 1024
                  ? 2
                  : 3;

          return GridView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              // Approximate: cover (200) + text (120)
              childAspectRatio: columns == 1 ? 1.6 : 1.05,
            ),
            itemCount: _items.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _items.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return _NewsCard(
                news: _items[index],
                onTap: () => _openDetail(_items[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news, required this.onTap});

  final Map<String, dynamic> news;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = (news['title'] as String?) ?? 'Tanpa Judul';
    final excerpt = (news['excerpt'] as String?) ??
        (news['description'] as String?) ??
        '';
    final publishedAt = news['kegiatan_date'] as String? ?? news['published_at'] as String? ?? news['created_at'] as String?;
    final coverUrl = _coverUrl(news['cover_image']);
    final absolute = formatTanggalString(publishedAt, includeTime: false);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: CachedImage(
                url: coverUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.zero,
              ),
            ),
            // Text Content Footer
            Expanded(
              flex: 4,
              child: Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            absolute,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _coverUrl(dynamic cover) {
    if (cover is Map<String, dynamic>) {
      final url = cover['url'];
      if (url is String && url.isNotEmpty) {
        // Force secure domain mapping for web & mobile
        return url.replaceAll(RegExp(r'http://(localhost|116\.212\.73\.88)(:\d+)?'), 'https://gpiyehuda-bali.my.id');
        return url;
      }
    }
    return null;
  }


}

/// Detailed news article page with hero cover, full content, image gallery
/// (tappable, swipe-able, zoom-able), and a "Unduh Gallery" button.
class JemaatBeritaDetailPage extends StatefulWidget {
  const JemaatBeritaDetailPage({
    super.key,
    required this.session,
    required this.newsId,
    this.initialSummary,
  });

  final SessionController session;
  final int newsId;
  final Map<String, dynamic>? initialSummary;

  @override
  State<JemaatBeritaDetailPage> createState() => _JemaatBeritaDetailPageState();
}

class _JemaatBeritaDetailPageState extends State<JemaatBeritaDetailPage> {
  late final ApiClient _api;
  Map<String, dynamic>? _detail;
  ApiError? _error;
  bool _loading = true;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _api = widget.session.apiClient;
    _detail = widget.initialSummary;
    _load();
  }

  Future<void> _load() async {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.newsDetail(token: token, id: widget.newsId);
      if (!mounted) return;
      setState(() {
        _detail = data;
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
        _error = ApiError(message: 'Gagal memuat detail berita: $e');
        _loading = false;
      });
    }
  }

  Future<void> _downloadGallery() async {
    final token = widget.session.token ?? '';
    if (token.isEmpty) return;
    setState(() {
      _downloading = true;
    });
    try {
      final bytes = await _api.downloadNewsAttachments(
        token: token,
        newsId: widget.newsId,
      );
      if (!mounted) return;
      final path = await saveDownloadedBytes(
        bytes: bytes,
        fileName: 'berita-${widget.newsId}-lampiran.zip',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kIsWeb ? 'Lampiran diunduh: $path' : 'Tersimpan: $path')),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengunduh lampiran')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      body: _loading && detail == null
          ? _buildSkeleton()
          : _error != null && detail == null
              ? Scaffold(
                  appBar: AppBar(),
                  body: ErrorStateView(error: _error, onRetry: _load),
                )
              : _buildContent(detail!),
    );
  }

  Widget _buildSkeleton() {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonList(itemCount: 3, itemHeight: 200),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> d) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = (d['title'] as String?) ?? '';
    final coverUrl = _coverUrl(d['cover_image']);
    final content = (d['content'] as String?) ?? '';
    final publishedAt = d['published_at'] as String?;
    final creator = d['creator_name'] as String? ?? '';
    final attachments = (d['attachments'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        <Map<String, dynamic>>[];
    final images = attachments.where((a) => a['is_image'] == true).toList();
    final otherFiles = attachments.where((a) => a['is_image'] != true).toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: coverUrl != null ? 260 : 0,
          flexibleSpace: coverUrl == null
              ? null
              : FlexibleSpaceBar(
                  background: Hero(
                    tag: 'news-cover-${widget.newsId}',
                    child: CachedImage(
                      url: coverUrl,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      formatTanggalString(publishedAt, includeTime: true),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (creator.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.person_outline, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        creator,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  content,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    'Galeri (${images.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GalleryGrid(images: images),
                ],
                if (otherFiles.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Lampiran',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...otherFiles.map((a) => ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(a['file_name']?.toString() ?? '-'),
                        subtitle: Text(_humanSize((a['file_size'] as num?)?.toInt() ?? 0)),
                        contentPadding: EdgeInsets.zero,
                      )),
                ],
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _downloading ? null : _downloadGallery,
                      icon: _downloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                      label: Text(
                        _downloading
                            ? 'Mengunduh...'
                            : 'Unduh Galeri & Lampiran (${attachments.length} file)',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  static String? _coverUrl(dynamic cover) {
    if (cover is Map<String, dynamic>) {
      final url = cover['url'];
      if (url is String && url.isNotEmpty) {
        // Force secure domain mapping for web & mobile
        return url.replaceAll(RegExp(r'http://(localhost|116\.212\.73\.88)(:\d+)?'), 'https://gpiyehuda-bali.my.id');
        return url;
      }
    }
    return null;
  }
}

class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({required this.images});

  final List<Map<String, dynamic>> images;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth < 500
            ? 3
            : c.maxWidth < 900
                ? 4
                : 5;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final img = images[index];
            var url = img['url']?.toString();
            if (url != null) {
              url = url.replaceAll(RegExp(r'http://(localhost|116\.212\.73\.88)(:\d+)?'), 'https://gpiyehuda-bali.my.id');
            }
            return GestureDetector(
              onTap: () => _openViewer(context, images, index),
              child: Hero(
                tag: 'news-att-${img['id']}',
                child: CachedImage(url: url, fit: BoxFit.cover),
              ),
            );
          },
        );
      },
    );
  }

  void _openViewer(BuildContext context, List<Map<String, dynamic>> imgs, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _GalleryViewer(images: imgs, initialIndex: index),
      fullscreenDialog: true,
    ));
  }
}

/// Full-screen swipe-able, zoom-able gallery viewer.
class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({required this.images, required this.initialIndex});
  final List<Map<String, dynamic>> images;
  final int initialIndex;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, index) {
          final img = widget.images[index];
          final url = img['url']?.toString();
          return Hero(
            tag: 'news-att-${img['id']}',
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: CachedImage(
                  url: url,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
