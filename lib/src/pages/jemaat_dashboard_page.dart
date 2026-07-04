import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_colors.dart';
import '../core/api_client.dart';
import '../core/date_format.dart';
import '../core/file_download.dart';
import '../core/models.dart';
import '../core/notification_badge_controller.dart';
import '../core/pwa_install_controller.dart';
import '../core/session_controller.dart';
import '../widgets/church_logo.dart';
import 'jemaat_berita_page.dart';
import 'jemaat_events_page.dart';

class JemaatDashboardPage extends StatefulWidget {
  const JemaatDashboardPage({
    super.key,
    required this.session,
    required this.onThemeChanged,
    required this.darkMode,
    this.notificationBadge,
  });

  final SessionController session;
  final ValueChanged<bool> onThemeChanged;
  final bool darkMode;
  final NotificationBadgeController? notificationBadge;

  @override
  State<JemaatDashboardPage> createState() => _JemaatDashboardPageState();
}

class _JemaatDashboardPageState extends State<JemaatDashboardPage> {
  late final ApiClient _api;
  late final PwaInstallController _pwaController;

  Map<String, dynamic> _gereja = <String, dynamic>{};
  List<Map<String, dynamic>> _events = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _kategoriLayanan = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _templateLayanan = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _pengajuanLayanan = <Map<String, dynamic>>[];

  bool _loading = true;
  String? _error;
  int _tab = 0;

  String? _kategoriTerpilih;
  final _lampiranController = TextEditingController();
  final _imagePicker = ImagePicker();

  final Map<String, TextEditingController> _textControllers =
      <String, TextEditingController>{};
  final Map<String, bool> _boolValues = <String, bool>{};
  final Map<String, String?> _selectValues = <String, String?>{};
  final Map<String, DateTime?> _dateValues = <String, DateTime?>{};

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _namaController = TextEditingController();
  final _nomorKkController = TextEditingController();
  final _alamatController = TextEditingController();
  final _usiaController = TextEditingController();
  String _jenisKelamin = 'L';
  String? _fotoProfilUrl;
  bool _uploadingFoto = false;

  @override
  void initState() {
    super.initState();
    _api = widget.session.apiClient;
    _pwaController = PwaInstallController();
    _pwaController.addListener(_onPwaChanged);
    _pwaController.initialize();
    _load();
  }

  void _onPwaChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pwaController.removeListener(_onPwaChanged);
    _pwaController.dispose();
    _lampiranController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _usernameController.dispose();
    _emailController.dispose();
    _namaController.dispose();
    _nomorKkController.dispose();
    _alamatController.dispose();
    _usiaController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      final me = await _api.me(token);
      final results = await Future.wait<dynamic>([
        _api.churchProfile(token),
        _api.events(token),
        _api.serviceCategories(token),
        _api.serviceForms(token),
        _api.serviceApplications(token),
      ]);

      _gereja = results[0] as Map<String, dynamic>;
      _events = results[1] as List<Map<String, dynamic>>;
      _kategoriLayanan = results[2] as List<Map<String, dynamic>>;
      _templateLayanan = results[3] as List<Map<String, dynamic>>;
      _pengajuanLayanan = results[4] as List<Map<String, dynamic>>;

      _kategoriTerpilih ??= _kategoriLayanan.isNotEmpty
          ? _kategoriLayanan.first['code']?.toString()
          : null;
      _siapkanStateForm();

      _usernameController.text = (me['username'] as String?) ?? '';
      _emailController.text = (me['email'] as String?) ?? '';
      _namaController.text = (me['name'] as String?) ?? '';
      _nomorKkController.text = (me['nomor_kk'] as String?) ?? '';
      _alamatController.text = (me['alamat'] as String?) ?? '';
      _usiaController.text = ((me['usia'] as num?)?.toInt().toString()) ?? '';
      _jenisKelamin = (me['jenis_kelamin'] as String?) == 'P' ? 'P' : 'L';
      _fotoProfilUrl = me['profile_photo_url'] as String?;
    } on ApiError catch (error) {
      _error =
          '${error.message}${error.traceId != null ? ' (trace: ${error.traceId})' : ''}';
    } catch (_) {
      _error = 'Gagal memuat dashboard jemaat';
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? _templateAktif() {
    if (_kategoriTerpilih == null) {
      return null;
    }

    for (final template in _templateLayanan) {
      if (template['category']?.toString() == _kategoriTerpilih) {
        return template;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _fieldsAktif() {
    final template = _templateAktif();
    return (template?['fields'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        <Map<String, dynamic>>[];
  }

  void _siapkanStateForm() {
    final fields = _fieldsAktif();
    final activeKeys = <String>{};

    for (final field in fields) {
      final key = field['key']?.toString() ?? '';
      final type = field['type']?.toString() ?? 'string';
      if (key.isEmpty) {
        continue;
      }
      activeKeys.add(key);

      if (type == 'boolean') {
        _boolValues.putIfAbsent(key, () => false);
      } else if (type == 'select') {
        final options = ((field['options'] as List?) ?? <dynamic>[])
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList();
        _selectValues.putIfAbsent(
          key,
          () => options.isEmpty ? null : options.first,
        );
      } else if (type == 'date') {
        _dateValues.putIfAbsent(key, () => null);
      } else {
        _textControllers.putIfAbsent(key, () => TextEditingController());
      }
    }

    final staleTextKeys = _textControllers.keys
        .where((key) => !activeKeys.contains(key))
        .toList();
    for (final key in staleTextKeys) {
      _textControllers.remove(key)?.dispose();
    }

    _boolValues.removeWhere((key, _) => !activeKeys.contains(key));
    _selectValues.removeWhere((key, _) => !activeKeys.contains(key));
    _dateValues.removeWhere((key, _) => !activeKeys.contains(key));
  }

  Future<void> _pilihTanggalField(String key) async {
    final now = DateTime.now();
    final initial = _dateValues[key] ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year + 20),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _dateValues[key] = picked;
    });
  }

  Future<void> _kirimPengajuan() async {
    try {
      final token = widget.session.token;
      final kategori = _kategoriTerpilih;
      if (token == null || token.isEmpty || kategori == null) {
        throw const ApiError(message: 'Kategori layanan belum tersedia');
      }

      final fields = _fieldsAktif();
      if (fields.isEmpty) {
        _snack('Template kategori ini belum tersedia. Hubungi admin.');
        return;
      }

      final formData = <String, dynamic>{};

      for (final field in fields) {
        final key = field['key']?.toString() ?? '';
        final type = field['type']?.toString() ?? 'string';
        final required = field['required'] == true;

        if (key.isEmpty) {
          continue;
        }

        if (type == 'boolean') {
          formData[key] = _boolValues[key] ?? false;
          continue;
        }

        if (type == 'select') {
          final selected = _selectValues[key];
          if (required && (selected == null || selected.isEmpty)) {
            _snack('Field "$key" wajib dipilih');
            return;
          }
          if (selected != null && selected.isNotEmpty) {
            formData[key] = selected;
          }
          continue;
        }

        if (type == 'date') {
          final value = _dateValues[key];
          if (required && value == null) {
            _snack('Field "$key" wajib diisi');
            return;
          }
          if (value != null) {
            formData[key] = _formatDateOnly(value);
          }
          continue;
        }

        final text = _textControllers[key]?.text.trim() ?? '';
        if (required && text.isEmpty) {
          _snack('Field "$key" wajib diisi');
          return;
        }
        if (text.isEmpty) {
          continue;
        }

        if (type == 'number') {
          final numValue = num.tryParse(text);
          if (numValue == null) {
            _snack('Field "$key" harus berupa angka');
            return;
          }
          formData[key] = numValue;
        } else {
          formData[key] = text;
        }
      }

      final lampiran = _lampiranController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();

      await _api.applyService(
        token: token,
        category: kategori,
        formData: formData,
        attachments: lampiran,
      );

      _resetFormLayanan();
      final applications = await _api.serviceApplications(token);
      if (mounted) {
        setState(() {
          _pengajuanLayanan = applications;
        });
      }

      _snack('Pengajuan layanan berhasil dikirim');
    } on ApiError catch (error) {
      _snack(error.message);
    }
  }

  void _resetFormLayanan() {
    _lampiranController.clear();

    for (final controller in _textControllers.values) {
      controller.clear();
    }

    final fields = _fieldsAktif();
    for (final field in fields) {
      final key = field['key']?.toString() ?? '';
      final type = field['type']?.toString() ?? 'string';
      if (key.isEmpty) {
        continue;
      }

      if (type == 'boolean') {
        _boolValues[key] = false;
      } else if (type == 'date') {
        _dateValues[key] = null;
      } else if (type == 'select') {
        final options = ((field['options'] as List?) ?? <dynamic>[])
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList();
        _selectValues[key] = options.isNotEmpty ? options.first : null;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _simpanProfil() async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      await _api.updateMe(token, {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'name': _namaController.text.trim(),
        'nomor_kk': _nomorKkController.text.trim(),
        'alamat': _alamatController.text.trim(),
        'usia': int.tryParse(_usiaController.text.trim()),
        'jenis_kelamin': _jenisKelamin,
      });

      _snack('Profil berhasil diperbarui');
      await _load();
    } on ApiError catch (error) {
      _snack(error.message);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await widget.session.signOut();
        if (mounted) {
          // Close the loading dialog
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          // Close the loading dialog
          Navigator.of(context).pop();
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal logout, coba lagi')),
          );
        }
      }
    }
  }

  Future<void> _downloadSertifikat(Map<String, dynamic> application) async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      final applicationId = (application['id'] as num?)?.toInt();
      if (applicationId == null) {
        _snack('ID pengajuan tidak ditemukan');
        return;
      }

      final bytes = await _api.downloadServiceCertificate(
        token: token,
        applicationId: applicationId,
      );
      final savedPath = await saveDownloadedBytes(
        bytes: bytes,
        fileName: 'sertifikat-pengajuan-$applicationId.pdf',
      );
      _snack(
        kIsWeb
            ? 'Sertifikat berhasil diunduh: $savedPath'
            : 'Sertifikat tersimpan: $savedPath',
      );
    } on ApiError catch (error) {
      _snack(error.message);
    } catch (_) {
      _snack('Gagal memproses unduhan sertifikat.');
    }
  }

  Future<void> _uploadFotoProfil(ImageSource source) async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      setState(() {
        _uploadingFoto = true;
      });

      final targetSource = (kIsWeb && source == ImageSource.camera)
          ? ImageSource.gallery
          : source;

      final file = await _imagePicker.pickImage(
        source: targetSource,
        imageQuality: 82,
        maxWidth: 1280,
      );

      if (file == null) {
        return;
      }

      final payload = await _api.uploadProfilePhoto(
        token: token,
        filePath: file.path,
      );

      if (!mounted) {
        return;
      }

      final oldUrl = _fotoProfilUrl;
      if (oldUrl != null) {
        final provider = NetworkImage(oldUrl);
        await provider.evict();
      }

      setState(() {
        _fotoProfilUrl = payload['profile_photo_url'] as String?;
      });
      _snack('Foto profil berhasil diperbarui');
    } on ApiError catch (error) {
      _snack(error.message);
    } catch (_) {
      _snack(
        'Upload foto belum tersedia pada perangkat/browser ini. Coba gunakan opsi Galeri.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingFoto = false;
        });
      }
    }
  }

  Future<void> _uploadFotoProfilViaFileWeb() async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      setState(() {
        _uploadingFoto = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final lowerName = file.name.toLowerCase();
      final isAllowed =
          lowerName.endsWith('.jpg') ||
          lowerName.endsWith('.jpeg') ||
          lowerName.endsWith('.png') ||
          lowerName.endsWith('.webp');
      if (!isAllowed) {
        _snack('Format foto harus jpg, jpeg, png, atau webp.');
        return;
      }

      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _snack('File tidak dapat dibaca dari browser. Coba file lain.');
        return;
      }

      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        _snack('Ukuran foto maksimal 5MB.');
        return;
      }

      final payload = await _api.uploadProfilePhotoBytes(
        token: token,
        bytes: bytes,
        fileName: file.name,
      );

      if (!mounted) {
        return;
      }

      final oldUrl = _fotoProfilUrl;
      if (oldUrl != null) {
        final provider = NetworkImage(oldUrl);
        await provider.evict();
      }

      setState(() {
        _fotoProfilUrl = payload['profile_photo_url'] as String?;
      });
      _snack('Foto profil berhasil diperbarui');
    } on ApiError catch (error) {
      _snack(error.message);
    } catch (error) {
      if (_isPickerCancellation(error)) {
        return;
      }
      _snack('Gagal upload file foto di web.');
    } finally {
      if (mounted) {
        setState(() {
          _uploadingFoto = false;
        });
      }
    }
  }

  bool _isPickerCancellation(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('cancel') ||
        message.contains('abort') ||
        message.contains('aborted') ||
        message.contains('no file selected');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_judulTab()),
        actions: [
          IconButton(
            tooltip: 'Mode gelap/terang',
            onPressed: () => widget.onThemeChanged(!widget.darkMode),
            icon: Icon(widget.darkMode ? Icons.dark_mode : Icons.light_mode),
          ),
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _kontenTab(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          if (index == 5) {
            if (_pwaController.canInstall) {
              _pwaController.promptInstall();
            } else if (_pwaController.shouldShowIOSGuide) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Install App'),
                  content: const Text(
                    'Untuk menginstall aplikasi:\n\n'
                    '1. Tap ikon Share di Safari\n'
                    '2. Pilih "Add to Home Screen"\n'
                    '3. Tap "Add"',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            }
            return;
          }
          setState(() => _tab = index);
        },
        destinations: [
        ...[
          NavigationDestination(
            icon: _BadgeIcon(
              controller: widget.notificationBadge,
              child: const Icon(Icons.home_outlined),
            ),
            selectedIcon: _BadgeIcon(
              controller: widget.notificationBadge,
              child: const Icon(Icons.home),
            ),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Event',
          ),
          const NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake),
            label: 'Layanan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'Berita',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        if (_pwaController.canInstall ||
            _pwaController.shouldShowIOSGuide)
          const NavigationDestination(
            icon: Icon(Icons.download_for_offline_outlined),
            selectedIcon: Icon(Icons.download_for_offline),
            label: 'Install',
          ),
      ],
      ),
    );
  }

  String _judulTab() {
    switch (_tab) {
      case 1:
        return 'Event Gereja';
      case 2:
        return 'Pengajuan Layanan';
      case 3:
        return 'Berita & Informasi';
      case 4:
        return 'Profil Jemaat';
      default:
        return 'Beranda Jemaat';
    }
  }

  Widget _kontenTab() {
    switch (_tab) {
      case 1:
        return _tabEvent();
      case 2:
        return _tabLayanan();
      case 3:
        return _tabBerita();
      case 4:
        return _tabProfil();
      default:
        return _tabBeranda();
    }
  }

  Widget _tabBerita() {
    return JemaatBeritaPage(session: widget.session);
  }

  Widget _tabBeranda() {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final totalEvent = _events.length;
    final totalPengajuan = _pengajuanLayanan.length;
    final pengajuanPending = _pengajuanLayanan
        .where((item) => (item['status']?.toString() ?? '') == 'pending')
        .length;
    final eventMendatang = _eventMendatang();
    final pengajuanTerbaru = _pengajuanLayanan.take(3).toList();

    return ListView(
      key: const ValueKey('beranda'),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.darkMode
                  ? [
                      theme.colorScheme.surfaceContainerLow,
                      theme.colorScheme.surfaceContainer,
                    ]
                  : [
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
                      theme.colorScheme.surfaceContainerLow,
                    ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChurchLogo(
                logo: _gereja['logo'] as Map<String, dynamic>?,
                isDark: widget.darkMode,
                height: 70,
              ),
              const SizedBox(height: 10),
              Text(
                (_gereja['name'] as String?) ?? 'GPI Yehuda',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text((_gereja['address'] as String?) ?? 'Bali, Indonesia'),
              const SizedBox(height: 8),
              _sosialMediaSection(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ringkasanCard(
              title: 'Total Event',
              value: totalEvent.toString(),
              icon: Icons.event_note_outlined,
              onTap: () => setState(() => _tab = 1),
            ),
            _ringkasanCard(
              title: 'Pengajuan Saya',
              value: totalPengajuan.toString(),
              icon: Icons.assignment_outlined,
              onTap: () => setState(() => _tab = 2),
            ),
            _ringkasanCard(
              title: 'Menunggu Proses',
              value: pengajuanPending.toString(),
              icon: Icons.hourglass_top_outlined,
              onTap: () => setState(() => _tab = 2),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agenda Mendatang',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (eventMendatang.isEmpty)
                  const Text('Tidak ada event mendatang')
                else
                  ...eventMendatang.map((event) {
                    final tanggal = _labelTanggalEvent(event);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_available_outlined),
                      title: Text((event['title'] as String?) ?? '-'),
                      subtitle: Text(tanggal),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Pengajuan Terbaru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (pengajuanTerbaru.isEmpty)
                  const Text('Belum ada pengajuan layanan.')
                else
                  ...pengajuanTerbaru.map((item) {
                    final status = item['status']?.toString() ?? '-';
                    final category = item['category']?.toString() ?? '-';
                    final tanggalLabel = formatTanggalString(
                      item['created_at'] as String?,
                      useLong: true,
                    );
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined),
                      title: Text(category),
                      subtitle: Text('Dibuat: $tanggalLabel'),
                      trailing: Chip(
                        label: Text(status),
                        backgroundColor: _statusBackgroundColor(
                          status,
                          appColors,
                        ),
                        labelStyle: TextStyle(
                          color: _statusTextColor(status, appColors),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sosialMediaSection() {
    final metadata = _gereja['metadata'] as Map<String, dynamic>?;
    if (metadata == null || metadata.isEmpty) {
      return const SizedBox.shrink();
    }

    final platforms = <Map<String, String>>[];
    for (final entry in [
      {'key': 'instagram', 'icon': 'instagram', 'label': 'Instagram'},
      {'key': 'tiktok', 'icon': 'tiktok', 'label': 'TikTok'},
      {'key': 'youtube', 'icon': 'youtube', 'label': 'YouTube'},
      {'key': 'facebook', 'icon': 'facebook', 'label': 'Facebook'},
    ]) {
      final value = metadata[entry['key']] as String?;
      if (value != null && value.trim().isNotEmpty) {
        platforms.add({
          'key': entry['key']!,
          'value': value.trim(),
          'icon': entry['icon']!,
          'label': entry['label']!,
        });
      }
    }

    if (platforms.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sosial Media',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: platforms.map((p) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: Icon(_sosialIcon(p['key']!), size: 18),
                  label: Text(p['label']!, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _openSosialLink(p['key']!, p['value']!),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _sosialIcon(String key) {
    switch (key) {
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'tiktok':
        return Icons.music_note_outlined;
      case 'youtube':
        return Icons.play_circle_outline;
      case 'facebook':
        return Icons.facebook_outlined;
      default:
        return Icons.link;
    }
  }

  void _openSosialLink(String platform, String value) {
    String url = value;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      switch (platform) {
        case 'instagram':
          url = 'https://instagram.com/$value';
          break;
        case 'tiktok':
          url = 'https://tiktok.com/@$value';
          break;
        case 'youtube':
          url = 'https://youtube.com/$value';
          break;
        case 'facebook':
          url = 'https://facebook.com/$value';
          break;
      }
    }
    launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  Widget _ringkasanCard({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _eventMendatang() {
    final now = DateTime.now();
    final events = _events.where((event) {
      final dt = _parseEventDate(event);
      return dt != null && dt.isAfter(now.subtract(const Duration(days: 1)));
    }).toList();

    events.sort((a, b) {
      final aDate = _parseEventDate(a) ?? DateTime(2100);
      final bDate = _parseEventDate(b) ?? DateTime(2100);
      return aDate.compareTo(bDate);
    });

    return events.take(3).toList();
  }

  DateTime? _parseEventDate(Map<String, dynamic> event) {
    final raw =
        (event['start_at'] as String?) ?? (event['date'] as String?) ?? '';
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  String _labelTanggalEvent(Map<String, dynamic> event) {
    final raw =
        (event['start_at'] as String?) ?? (event['date'] as String?) ?? '-';
    return formatTanggalString(raw, includeTime: true);
  }

  String _formatWita24(String raw) {
    return formatTanggalString(raw, includeTime: true);
  }

  Widget _tabEvent() {
    return JemaatEventsPage(session: widget.session);
  }

  // Legacy inline events implementation kept commented for reference only.
  // ignore: unused_element
  Widget _legacyTabEvent() {
    return ListView(
      key: const ValueKey('event'),
      children: [
        const Text(
          'Daftar Event',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (_events.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada event.'),
            ),
          )
        else
          ..._events.map((event) {
            final startAt =
                (event['start_at'] as String?) ??
                (event['date'] as String?) ??
                '-';
            return Card(
              child: ListTile(
                leading: const Icon(Icons.event_available),
                title: Text((event['title'] as String?) ?? '-'),
                subtitle: Text(_formatWita24(startAt)),
              ),
            );
          }),
      ],
    );
  }

  Widget _tabLayanan() {
    final fields = _fieldsAktif();

    return ListView(
      key: const ValueKey('layanan'),
      children: [
        const Text(
          'Ajukan Layanan',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _kategoriTerpilih,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Layanan',
                  ),
                  items: _kategoriLayanan
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item['code']?.toString(),
                          child: Text(
                            item['name']?.toString() ??
                                item['code']?.toString() ??
                                '-',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _kategoriTerpilih = value;
                      _siapkanStateForm();
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (fields.isEmpty)
                  const Text(
                    'Template kategori ini belum tersedia. Hubungi admin.',
                  )
                else
                  ...fields.map((field) => _renderField(field)),
                const SizedBox(height: 8),
                TextField(
                  controller: _lampiranController,
                  decoration: const InputDecoration(
                    labelText: 'URL Lampiran (pisahkan dengan koma)',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _kategoriTerpilih == null ? null : _kirimPengajuan,
                  icon: const Icon(Icons.send),
                  label: const Text('Kirim Pengajuan'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Riwayat Pengajuan Saya',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (_pengajuanLayanan.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada pengajuan layanan.'),
            ),
          )
        else
          ..._pengajuanLayanan.map((item) {
            final category = item['category']?.toString() ?? '-';
            final status = item['status']?.toString() ?? '-';
            final createdAtLabel = formatTanggalString(
              item['created_at'] as String?,
              useLong: true,
            );

            return Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(category),
                subtitle: Text('Status: $status • Tanggal: $createdAtLabel'),
                trailing: TextButton.icon(
                  onPressed: () => _downloadSertifikat(item),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF'),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _renderField(Map<String, dynamic> field) {
    final key = field['key']?.toString() ?? '';
    final label = (field['label']?.toString().trim().isNotEmpty ?? false)
        ? field['label'].toString()
        : key;
    final type = field['type']?.toString() ?? 'string';
    final required = field['required'] == true;

    if (key.isEmpty) {
      return const SizedBox.shrink();
    }

    if (type == 'boolean') {
      return SwitchListTile(
        value: _boolValues[key] ?? false,
        onChanged: (value) => setState(() => _boolValues[key] = value),
        title: Text(required ? '$label *' : label),
      );
    }

    if (type == 'select') {
      final options = ((field['options'] as List?) ?? <dynamic>[])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DropdownButtonFormField<String>(
          initialValue: _selectValues[key],
          decoration: InputDecoration(labelText: required ? '$label *' : label),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectValues[key] = value),
        ),
      );
    }

    if (type == 'date') {
      final value = _dateValues[key];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton.icon(
          onPressed: () => _pilihTanggalField(key),
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(
            value == null
                ? '${required ? '$label *' : label}: pilih tanggal'
                : '${required ? '$label *' : label}: ${value.toIso8601String().split('T').first}',
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _textControllers[key],
        decoration: InputDecoration(labelText: required ? '$label *' : label),
        keyboardType: type == 'number'
            ? TextInputType.number
            : TextInputType.text,
      ),
    );
  }

  Widget _tabProfil() {
    return ListView(
      key: const ValueKey('profil'),
      children: [
        const Text(
          'Update Profil Jemaat',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: (_fotoProfilUrl != null && _fotoProfilUrl!.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                _fotoProfilUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('Profile photo error: $error');
                                  return const CircleAvatar(
                                    radius: 32,
                                    child: Icon(Icons.person, size: 32),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const CircleAvatar(
                                    radius: 32,
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
                              ),
                            )
                          : const CircleAvatar(
                              radius: 32,
                              child: Icon(Icons.person, size: 32),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (kIsWeb)
                            OutlinedButton.icon(
                              onPressed: _uploadingFoto
                                  ? null
                                  : _uploadFotoProfilViaFileWeb,
                              icon: const Icon(Icons.upload_file_outlined),
                              label: const Text('Upload File'),
                            )
                          else ...[
                            OutlinedButton.icon(
                              onPressed: _uploadingFoto
                                  ? null
                                  : () =>
                                        _uploadFotoProfil(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Galeri'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _uploadingFoto
                                  ? null
                                  : () => _uploadFotoProfil(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Selfie'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (_uploadingFoto) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _namaController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nomorKkController,
                  decoration: const InputDecoration(labelText: 'Nomor KK'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _alamatController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _usiaController,
                  decoration: const InputDecoration(labelText: 'Usia'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _jenisKelamin,
                  decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
                  items: const [
                    DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                  ],
                  onChanged: (value) =>
                      setState(() => _jenisKelamin = value ?? 'L'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _simpanProfil,
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Profil'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateOnly(DateTime value) {
    return formatDateLabel(value);
  }

  Color _statusBackgroundColor(String status, AppColors appColors) {
    switch (status.toLowerCase()) {
      case 'approved':
        return appColors.success.withValues(alpha: 0.14);
      case 'rejected':
        return appColors.danger.withValues(alpha: 0.14);
      case 'pending':
        return appColors.warning.withValues(alpha: 0.14);
      default:
        return appColors.secondary.withValues(alpha: 0.14);
    }
  }

  Color _statusTextColor(String status, AppColors appColors) {
    switch (status.toLowerCase()) {
      case 'approved':
        return appColors.success;
      case 'rejected':
        return appColors.danger;
      case 'pending':
        return appColors.warning;
      default:
        return appColors.secondary;
    }
  }

  void _snack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}


/// Wraps any icon widget with a Material 3 [Badge] whose label reflects the
/// unread notification count. When [controller] is null the child is returned
/// unchanged so the widget is safe to use before the controller is wired.
class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.controller, required this.child});

  final NotificationBadgeController? controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) return child;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        if (c.count <= 0) return child;
        final label = c.count > 99 ? '99+' : '${c.count}';
        return Badge(
          label: Text(label),
          child: child,
        );
      },
    );
  }
}
