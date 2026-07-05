import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session_controller.dart';
import 'admin_jemaat_form_page.dart';

class AdminJemaatPage extends StatefulWidget {
  const AdminJemaatPage({super.key, required this.session});

  final SessionController session;

  @override
  State<AdminJemaatPage> createState() => _AdminJemaatPageState();
}

class _AdminJemaatPageState extends State<AdminJemaatPage> {
  late final ApiClient _api;

  List<Map<String, dynamic>> _jemaat = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;
  int _totalJemaat = 0;
  final int _page = 1;
  final int _perPage = 1000;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _kkFilter = '';

  @override
  void initState() {
    super.initState();
    _api = widget.session.apiClient;
    _loadJemaat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJemaat() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      final payload = await _api.usersPaginated(
        token,
        role: 'jemaat',
        perPage: _perPage,
        page: _page,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      
      _jemaat = (payload['data'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          [];
          
      _totalJemaat = (payload['meta']?['pagination']?['total'] as num?)?.toInt() ?? _jemaat.length;
    } on ApiError catch (error) {
      _error =
          '${error.message}${error.traceId != null ? ' (trace: ${error.traceId})' : ''}';
    } catch (_) {
      _error = 'Gagal memuat data jemaat';
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredJemaat {
    var filtered = _jemaat;

    if (_statusFilter != 'all') {
      filtered = filtered
          .where((j) => (j['status'] as String?) == _statusFilter)
          .toList();
    }

    if (_kkFilter.isNotEmpty) {
      filtered = filtered
          .where(
            (j) =>
                (j['nomor_kk'] as String?)?.contains(_kkFilter).toString() ==
                'true',
          )
          .toList();
    }

    return filtered;
  }

  void _showAddJemaatDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminJemaatFormPage(
          session: widget.session,
          onSuccess: () {
            _loadJemaat();
          },
        ),
      ),
    );
  }

  void _editJemaat(Map<String, dynamic> jemaat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminJemaatFormPage(
          session: widget.session,
          jemaat: jemaat,
          onSuccess: () {
            _loadJemaat();
          },
        ),
      ),
    );
  }

  Future<void> _deleteJemaat(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jemaat'),
        content: const Text('Apakah Anda yakin ingin menghapus anggota ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      await _api.deleteJemaat(token, userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jemaat berhasil dihapus')),
        );
        _loadJemaat();
      }
    } on ApiError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menghapus jemaat')));
      }
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'jemaat':
        return 'Jemaat';
      case 'simpatisan':
        return 'Simpatisan';
      default:
        return status ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Jemaat'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Tambah Jemaat',
              child: IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: _showAddJemaatDialog,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddJemaatDialog,
        tooltip: 'Tambah Jemaat Baru',
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SearchBar(
                  controller: _searchController,
                  hintText: 'Cari nama/email...',
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Semua Status'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Aktif'),
                          ),
                          DropdownMenuItem(
                            value: 'jemaat',
                            child: Text('Jemaat'),
                          ),
                          DropdownMenuItem(
                            value: 'simpatisan',
                            child: Text('Simpatisan'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value ?? 'all';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Filter KK',
                          isDense: true,
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _kkFilter = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (!_loading && _error == null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Total Data Jemaat: $_totalJemaat',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_error != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredJemaat.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada jemaat',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredJemaat.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final jemaat = _filteredJemaat[index];
                      final name = jemaat['name'] as String?;
                      final email = jemaat['email'] as String?;
                      final nomorKk = jemaat['nomor_kk'] as String?;
                      final status = jemaat['status'] as String?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            child: Text(
                              (name?.substring(0, 1) ?? '?').toUpperCase(),
                            ),
                          ),
                          title: Text(name ?? '-'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(email ?? '-'),
                              if (nomorKk != null)
                                Text(
                                  'KK: $nomorKk',
                                  style: theme.textTheme.bodySmall,
                                ),
                              Text(
                                'Status: ${_statusLabel(status)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editJemaat(jemaat);
                              } else if (value == 'delete') {
                                _deleteJemaat(
                                  (jemaat['id'] as num?)?.toInt() ?? 0,
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
