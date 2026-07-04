import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session_controller.dart';

class AdminKkManagementPage extends StatefulWidget {
  const AdminKkManagementPage({super.key, required this.session});

  final SessionController session;

  @override
  State<AdminKkManagementPage> createState() => _AdminKkManagementPageState();
}

class _AdminKkManagementPageState extends State<AdminKkManagementPage> {
  late final ApiClient _api;

  List<Map<String, dynamic>> _kkList = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _api = widget.session.apiClient;
    _loadKkData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKkData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      _kkList = await _api.kkRegistrations(
        token,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
    } on ApiError catch (error) {
      _error =
          '${error.message}${error.traceId != null ? ' (trace: ${error.traceId})' : ''}';
    } catch (_) {
      _error = 'Gagal memuat data KK';
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredKkList {
    if (_searchQuery.isEmpty) {
      return _kkList;
    }
    return _kkList
        .where(
          (item) =>
              (item['nomor_kk'] as String?)
                      ?.contains(_searchQuery)
                      .toString() ==
                  'true' ||
              (item['nama_kepala_keluarga'] as String?)
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase())
                      .toString() ==
                  'true',
        )
        .toList();
  }

  Future<void> _showAddKkDialog() async {
    final formKey = GlobalKey<FormState>();
    final nomorKkController = TextEditingController();
    final namaController = TextEditingController();
    final alamatController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Data KK'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomorKkController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nomor KK (wajib)',
                    prefixIcon: Icon(Icons.credit_card_outlined),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Nomor KK wajib diisi';
                    }
                    if (trimmed.length < 16) {
                      return 'Nomor KK minimal 16 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kepala Keluarga (wajib)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: alamatController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Alamat (opsional)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon (opsional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                final token = widget.session.token;
                if (token == null || token.isEmpty) {
                  throw const ApiError(message: 'Token tidak tersedia');
                }

                await _api.createKkRegistration(
                  token,
                  nomorKk: nomorKkController.text.trim(),
                  namaKepalaKeluarga: namaController.text.trim(),
                  alamat: alamatController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                );

                if (!mounted) return;
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('KK berhasil ditambahkan')),
                );
                _loadKkData();
              } on ApiError catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.message)));
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal menambahkan KK')),
                );
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );

    nomorKkController.dispose();
    namaController.dispose();
    alamatController.dispose();
    phoneController.dispose();
  }

  Future<void> _deleteKk(String kkId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Data KK'),
        content: const Text('Apakah Anda yakin ingin menghapus data KK ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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

      await _api.deleteKkRegistration(token, kkId);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('KK berhasil dihapus')));
      _loadKkData();
    } on ApiError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menghapus KK')));
    }
  }

  Future<void> _showEditKkDialog(Map<String, dynamic> kk) async {
    final formKey = GlobalKey<FormState>();
    final kkId = (kk['id'] as num?)?.toString() ?? '';
    final nomorKkController = TextEditingController(text: kk['nomor_kk'] as String? ?? '');
    final namaController = TextEditingController(text: kk['nama_kepala_keluarga'] as String? ?? '');
    final alamatController = TextEditingController(text: kk['alamat'] as String? ?? '');
    final phoneController = TextEditingController(text: kk['phone_number'] as String? ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Data KK'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomorKkController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nomor KK (wajib)',
                    prefixIcon: Icon(Icons.credit_card_outlined),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return 'Nomor KK wajib diisi';
                    if (trimmed.length < 16) return 'Nomor KK minimal 16 digit';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kepala Keluarga (wajib)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: alamatController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Alamat (opsional)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon (opsional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final token = widget.session.token;
                if (token == null || token.isEmpty) throw const ApiError(message: 'Token tidak tersedia');
                
                await _api.updateKkRegistration(
                  token,
                  kkId,
                  nomorKk: nomorKkController.text.trim(),
                  namaKepalaKeluarga: namaController.text.trim(),
                  alamat: alamatController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                );
                
                if (!mounted) return;
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('KK berhasil diperbarui')),
                );
                _loadKkData();
              } on ApiError catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui KK')));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    nomorKkController.dispose();
    namaController.dispose();
    alamatController.dispose();
    phoneController.dispose();
  }

  void addPostFrameCallback(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Data Kartu Keluarga')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddKkDialog,
        tooltip: 'Tambah KK',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Cari nomor KK atau nama kepala keluarga...',
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
                : _filteredKkList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data KK',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredKkList.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final kk = _filteredKkList[index];
                      final nomorKk = kk['nomor_kk'] as String?;
                      final namaKepala = kk['nama_kepala_keluarga'] as String?;
                      final alamat = kk['alamat'] as String?;
                      final phone = kk['phone_number'] as String?;
                      final memberCount =
                          (kk['member_count'] as num?)?.toInt() ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.credit_card,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(nomorKk ?? '-'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (namaKepala != null)
                                Text(
                                  namaKepala,
                                  style: theme.textTheme.bodySmall,
                                ),
                              if (alamat != null)
                                Text(
                                  alamat,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              if (phone != null)
                                Text(phone, style: theme.textTheme.bodySmall),
                              Text(
                                'Anggota: $memberCount',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteKk((kk['id'] as num?)?.toString() ?? '');
                              } else if (value == 'edit') {
                                _showEditKkDialog(kk);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined),
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
