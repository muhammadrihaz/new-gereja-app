import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_colors.dart';
import '../core/api_client.dart';
import '../core/date_format.dart';
import '../core/file_download.dart';
import '../core/models.dart';
import '../core/session_controller.dart';
import '../core/pwa_install_controller.dart';
import '../widgets/church_logo.dart';
import '../widgets/cached_image.dart';
import 'admin_jemaat_page.dart';
import 'admin_kk_management_page.dart';
import 'admin_profile_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.session,
    required this.onThemeChanged,
    required this.darkMode,
  });

  final SessionController session;
  final ValueChanged<bool> onThemeChanged;
  final bool darkMode;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final ApiClient _api;
  late final PwaInstallController _pwaController;

  Map<String, dynamic> _profilGereja = <String, dynamic>{};
  List<Map<String, dynamic>> _events = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _templates = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _pengajuan = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _kategoriLayanan = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _kategoriEvent = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _jemaat = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _keluarga = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _beritaList = <Map<String, dynamic>>[];

  final _judulBeritaController = TextEditingController();
  final _deskripsiBeritaController = TextEditingController();
  final _kontenBeritaController = TextEditingController();
  final _coverBeritaController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _coverBeritaFile;
  DateTime? _tanggalTerbitBerita;
  final List<_PickedFile> _beritaFiles = <_PickedFile>[];
  final _lampiranBeritaController = TextEditingController();
  bool _uploadingBerita = false;

  final _kodeKategoriController = TextEditingController();
  final _namaKategoriController = TextEditingController();
  int _selectedEditKategoriId = 0;
  bool _kategoriAktifEdit = true;

  bool _loading = true;
  String? _error;
  int _menu = 0;

  final _namaGerejaController = TextEditingController();
  final _alamatGerejaController = TextEditingController();
  final _teleponGerejaController = TextEditingController();
  final _emailGerejaController = TextEditingController();
  final _logoGerejaController = TextEditingController();
  final _instagramController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _facebookController = TextEditingController();

  final _judulEventController = TextEditingController();
  final _deskripsiEventController = TextEditingController();
  final _alamatEventController = TextEditingController();
  DateTime? _waktuMulaiEvent;
  DateTime? _waktuSelesaiEvent;
  String? _kategoriEventTerpilih;
  int? _editingEventId;

  final _namaTemplateController = TextEditingController();
  String? _kategoriTemplateTerpilih;
  final List<_FieldBuilderState> _fieldsBuilder = <_FieldBuilderState>[];

  int? _jemaatTerpilihId;
  String? _kategoriManualTerpilih;
  final _lampiranManualController = TextEditingController();
  final Map<String, TextEditingController> _manualTextControllers =
      <String, TextEditingController>{};
  final Map<String, bool> _manualBoolValues = <String, bool>{};
  final Map<String, String?> _manualSelectValues = <String, String?>{};
  final Map<String, DateTime?> _manualDateValues = <String, DateTime?>{};

  final _judulBroadcastController = TextEditingController(
    text: 'Pengumuman Gereja',
  );
  final _pesanBroadcastController = TextEditingController(
    text: 'Shalom, ini informasi terbaru untuk jemaat.',
  );
  final _roleBroadcastController = TextEditingController(text: 'jemaat');
  String _targetBroadcast = 'all';
  String? _hasilBroadcast;

  // Table pagination & search - Events
  int _eventPage = 1;
  final int _eventPerPage = 10;
  String _eventSearchQuery = '';
  String? _eventCategoryFilter;

  // Table pagination & search - Pengajuan
  int _pengajuanPage = 1;
  final int _pengajuanPerPage = 10;
  String _pengajuanSearchQuery = '';
  String? _pengajuanCategoryFilter;

  // Table pagination & search - Keluarga (KK)
  final int _keluargaPage = 1;
  final int _keluargaPerPage = 10;
  final String _keluargaSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _api = widget.session.apiClient;
    _pwaController = PwaInstallController();
    _pwaController.addListener(_onPwaChanged);
    _pwaController.initialize();
    _fieldsBuilder.add(_FieldBuilderState.standar());
    _load();
  }

  void _onPwaChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pwaController.removeListener(_onPwaChanged);
    _pwaController.dispose();
    _namaGerejaController.dispose();
    _alamatGerejaController.dispose();
    _teleponGerejaController.dispose();
    _emailGerejaController.dispose();
    _logoGerejaController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    _tiktokController.dispose();
    _facebookController.dispose();
    _judulEventController.dispose();
    _deskripsiEventController.dispose();
    _alamatEventController.dispose();
    _namaTemplateController.dispose();
    _lampiranManualController.dispose();
    for (final controller in _manualTextControllers.values) {
      controller.dispose();
    }
    _judulBroadcastController.dispose();
    _pesanBroadcastController.dispose();
    _roleBroadcastController.dispose();
    _judulBeritaController.dispose();
    _deskripsiBeritaController.dispose();
    _kontenBeritaController.dispose();
    _coverBeritaController.dispose();
    _lampiranBeritaController.dispose();
    _kodeKategoriController.dispose();
    _namaKategoriController.dispose();
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

      final results = await Future.wait<dynamic>([
        _api.churchProfile(token),
        _api.events(token),
        _api.serviceForms(token),
        _api.serviceApplications(token),
        _api.serviceCategories(token),
        _api.eventCategories(token),
        _api.users(token, role: 'jemaat', perPage: 100),
        _api.userFamilies(token, perPage: 100),
        _api.news(token, publishedOnly: false),
      ]);

      _profilGereja = results[0] as Map<String, dynamic>;
      _events = results[1] as List<Map<String, dynamic>>;
      _templates = results[2] as List<Map<String, dynamic>>;
      _pengajuan = results[3] as List<Map<String, dynamic>>;
      _kategoriLayanan = results[4] as List<Map<String, dynamic>>;
      _kategoriEvent = results[5] as List<Map<String, dynamic>>;
      _jemaat = results[6] as List<Map<String, dynamic>>;
      final keluargaPayload = results[7] as Map<String, dynamic>;
      _beritaList = results[8] as List<Map<String, dynamic>>;
      _keluarga =
          (keluargaPayload['data'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          <Map<String, dynamic>>[];

      _kategoriTemplateTerpilih ??= _kategoriLayanan.isNotEmpty
          ? _kategoriLayanan.first['code']?.toString()
          : null;
      _kategoriManualTerpilih ??= _kategoriLayanan.isNotEmpty
          ? _kategoriLayanan.first['code']?.toString()
          : null;
      _kategoriEventTerpilih ??= _kategoriEvent.isNotEmpty
          ? _kategoriEvent.first['code']?.toString()
          : null;
      _jemaatTerpilihId ??= (_jemaat.isNotEmpty)
          ? (_jemaat.first['id'] as num?)?.toInt()
          : null;
      _siapkanFormManual();

      _namaGerejaController.text = (_profilGereja['name'] as String?) ?? '';
      _alamatGerejaController.text =
          (_profilGereja['address'] as String?) ?? '';
      _teleponGerejaController.text = (_profilGereja['phone'] as String?) ?? '';
      _emailGerejaController.text = (_profilGereja['email'] as String?) ?? '';
      _logoGerejaController.text =
          ((_profilGereja['logo'] as Map<String, dynamic>?)?['url']
              as String?) ??
          '';

      final metadata = _profilGereja['metadata'] as Map<String, dynamic>?;
      if (metadata != null) {
        _instagramController.text =
            (metadata['instagram'] as String?) ?? '';
        _youtubeController.text = (metadata['youtube'] as String?) ?? '';
        _tiktokController.text = (metadata['tiktok'] as String?) ?? '';
        _facebookController.text = (metadata['facebook'] as String?) ?? '';
      }

      _muatTemplateDariKategori(
        _kategoriTemplateTerpilih,
        setStateAfter: false,
      );
    } on ApiError catch (error) {
      _error =
          '${error.message}${error.traceId != null ? ' (trace: ${error.traceId})' : ''}';
    } catch (_) {
      _error = 'Gagal memuat dashboard admin';
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _muatTemplateDariKategori(
    String? category, {
    bool setStateAfter = true,
  }) {
    if (category == null) {
      return;
    }

    final template = _templates.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['category']?.toString() == category,
      orElse: () => null,
    );

    final nextFields = <_FieldBuilderState>[];
    if (template != null) {
      _namaTemplateController.text = (template['name'] as String?) ?? '';
      final fields =
          (template['fields'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          <Map<String, dynamic>>[];
      for (final field in fields) {
        nextFields.add(
          _FieldBuilderState(
            keyField: field['key']?.toString() ?? '',
            label: field['label']?.toString() ?? '',
            type: field['type']?.toString() ?? 'string',
            requiredField: field['required'] == true,
            optionsText: ((field['options'] as List?) ?? <dynamic>[])
                .map((item) => item.toString())
                .join(', '),
          ),
        );
      }
    } else {
      _namaTemplateController.text = 'Template $category';
      nextFields.add(_FieldBuilderState.standar());
    }

    _fieldsBuilder
      ..clear()
      ..addAll(
        nextFields.isEmpty
            ? <_FieldBuilderState>[_FieldBuilderState.standar()]
            : nextFields,
      );

    if (setStateAfter && mounted) {
      setState(() {});
    }
  }

  Map<String, dynamic>? _templateManualAktif() {
    final kategori = _kategoriManualTerpilih;
    if (kategori == null || kategori.isEmpty) {
      return null;
    }

    for (final item in _templates) {
      if (item['category']?.toString() == kategori) {
        return item;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _fieldsManualAktif() {
    final template = _templateManualAktif();
    return (template?['fields'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        <Map<String, dynamic>>[];
  }

  void _siapkanFormManual() {
    final fields = _fieldsManualAktif();
    final activeKeys = <String>{};

    for (final field in fields) {
      final key = field['key']?.toString() ?? '';
      final type = field['type']?.toString() ?? 'string';
      if (key.isEmpty) {
        continue;
      }
      activeKeys.add(key);

      if (type == 'boolean') {
        _manualBoolValues.putIfAbsent(key, () => false);
      } else if (type == 'select') {
        final options = ((field['options'] as List?) ?? <dynamic>[])
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList();
        _manualSelectValues.putIfAbsent(
          key,
          () => options.isEmpty ? null : options.first,
        );
      } else if (type == 'date') {
        _manualDateValues.putIfAbsent(key, () => null);
      } else {
        _manualTextControllers.putIfAbsent(key, () => TextEditingController());
      }
    }

    final staleTextKeys = _manualTextControllers.keys
        .where((key) => !activeKeys.contains(key))
        .toList();
    for (final key in staleTextKeys) {
      _manualTextControllers.remove(key)?.dispose();
    }

    _manualBoolValues.removeWhere((key, _) => !activeKeys.contains(key));
    _manualSelectValues.removeWhere((key, _) => !activeKeys.contains(key));
    _manualDateValues.removeWhere((key, _) => !activeKeys.contains(key));
  }

  Future<void> _pilihTanggalManual(String key) async {
    final now = DateTime.now();
    final initial = _manualDateValues[key] ?? now;
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
      _manualDateValues[key] = picked;
    });
  }

  Future<void> _pilihWaktuEvent({required bool mulai}) async {
    final now = DateTime.now();
    final base = mulai
        ? (_waktuMulaiEvent ?? now.add(const Duration(days: 1)))
        : (_waktuSelesaiEvent ??
              (_waktuMulaiEvent ?? now).add(const Duration(hours: 2)));

    final tanggal = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (tanggal == null || !mounted) {
      return;
    }

    final jam = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (jam == null || !mounted) {
      return;
    }

    final value = DateTime(
      tanggal.year,
      tanggal.month,
      tanggal.day,
      jam.hour,
      jam.minute,
    );

    setState(() {
      if (mulai) {
        _waktuMulaiEvent = value;
        _waktuSelesaiEvent ??= value.add(const Duration(hours: 2));
      } else {
        _waktuSelesaiEvent = value;
      }
    });
  }

  Future<void> _simpanProfilGereja() async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      final metadata = <String, dynamic>{};
      final instagram = _instagramController.text.trim();
      final youtube = _youtubeController.text.trim();
      final tiktok = _tiktokController.text.trim();
      final facebook = _facebookController.text.trim();

      if (instagram.isNotEmpty) metadata['instagram'] = instagram;
      if (youtube.isNotEmpty) metadata['youtube'] = youtube;
      if (tiktok.isNotEmpty) metadata['tiktok'] = tiktok;
      if (facebook.isNotEmpty) metadata['facebook'] = facebook;

      final payload = {
        'name': _namaGerejaController.text.trim(),
        'address': _alamatGerejaController.text.trim(),
        'phone': _teleponGerejaController.text.trim(),
        'email': _emailGerejaController.text.trim(),
        'logo': {
          'url': _logoGerejaController.text.trim(),
          'disk': 'public',
          'path': _logoGerejaController.text.trim(),
        },
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

      _profilGereja = await _api.upsertChurchProfile(token, payload);
      _snack('Profil gereja berhasil disimpan');
      setState(() {});
    } on ApiError catch (error) {
      _snack(error.message);
    }
  }

  Future<void> _buatEvent() async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }
      if (_kategoriEventTerpilih == null) {
        _snack('Kategori event wajib dipilih');
        return;
      }
      if (_waktuMulaiEvent == null) {
        _snack('Waktu mulai event wajib diisi');
        return;
      }

      final payload = {
        'title': _judulEventController.text.trim(),
        'description': _deskripsiEventController.text.trim(),
        'start_at': _waktuMulaiEvent!.toIso8601String(),
        if (_waktuSelesaiEvent != null)
          'end_at': _waktuSelesaiEvent!.toIso8601String(),
        'category': _kategoriEventTerpilih,
        'location': {
          'address': _alamatEventController.text.trim().isEmpty
              ? 'GPI Yehuda Bali'
              : _alamatEventController.text.trim(),
          'latitude': -8.670458,
          'longitude': 115.212629,
          'name': 'GPI Yehuda',
        },
      };

      if (_editingEventId != null) {
        await _api.updateEvent(token: token, id: _editingEventId!, body: payload);
        _snack('Event berhasil diperbarui');
      } else {
        await _api.createEvent(token: token, body: payload);
        _snack('Event berhasil dibuat');
      }

      _resetFormEvent();
      await _load();
    } on ApiError catch (error) {
      _snack(error.message);
    }
  }

  void _resetFormEvent() {
    _judulEventController.clear();
    _deskripsiEventController.clear();
    _alamatEventController.clear();
    setState(() {
      _waktuMulaiEvent = null;
      _waktuSelesaiEvent = null;
      _editingEventId = null;
    });
  }

  Future<void> _simpanTemplate() async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }
      final kategori = _kategoriTemplateTerpilih;
      if (kategori == null || kategori.isEmpty) {
        _snack('Kategori layanan wajib dipilih');
        return;
      }

      final fields = <Map<String, dynamic>>[];
      for (final item in _fieldsBuilder) {
        final key = item.keyField.trim();
        if (key.isEmpty) {
          _snack('Key field tidak boleh kosong');
          return;
        }

        final map = <String, dynamic>{
          'key': key,
          'label': item.label.trim().isEmpty ? key : item.label.trim(),
          'type': item.type,
          'required': item.requiredField,
        };

        if (item.type == 'select') {
          final options = item.optionsText
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList();
          if (options.isEmpty) {
            _snack('Field select wajib memiliki minimal satu opsi');
            return;
          }
          map['options'] = options;
        }

        fields.add(map);
      }

      final body = {
        'category': kategori,
        'name': _namaTemplateController.text.trim().isEmpty
            ? 'Template $kategori'
            : _namaTemplateController.text.trim(),
        'is_active': true,
        'fields': fields,
      };

      await _api.upsertServiceTemplate(
        token: token,
        categoryPath: kategori,
        body: body,
      );

      _snack('Template layanan berhasil disimpan');
      await _load();
    } on ApiError catch (error) {
      _snack(error.message);
    }
  }

  Future<void> _hapusTemplate(String category) async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      await _api.deleteServiceTemplate(token: token, category: category);
      _snack('Template kategori $category berhasil dihapus');
      await _load();
    } on ApiError catch (error) {
      _snack(error.message);
    }
  }

  Future<void> _buatPengajuanManual() async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }
      if (_jemaatTerpilihId == null) {
        _snack('Pilih jemaat terlebih dahulu');
        return;
      }
      if (_kategoriManualTerpilih == null) {
        _snack('Kategori layanan wajib dipilih');
        return;
      }

      final fields = _fieldsManualAktif();
      if (fields.isEmpty) {
        _snack('Template kategori ini belum tersedia.');
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
          formData[key] = _manualBoolValues[key] ?? false;
          continue;
        }

        if (type == 'select') {
          final selected = _manualSelectValues[key];
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
          final value = _manualDateValues[key];
          if (required && value == null) {
            _snack('Field "$key" wajib diisi');
            return;
          }
          if (value != null) {
            formData[key] = _formatDateOnly(value);
          }
          continue;
        }

        final text = _manualTextControllers[key]?.text.trim() ?? '';
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

      final lampiran = _lampiranManualController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();

      await _api.applyService(
        token: token,
        targetUserId: _jemaatTerpilihId,
        category: _kategoriManualTerpilih!,
        formData: formData,
        attachments: lampiran,
      );

      _lampiranManualController.clear();
      for (final controller in _manualTextControllers.values) {
        controller.clear();
      }
      _manualDateValues.updateAll((key, value) => null);
      _manualBoolValues.updateAll((key, value) => false);
      final activeFields = _fieldsManualAktif();
      for (final field in activeFields) {
        final key = field['key']?.toString() ?? '';
        final type = field['type']?.toString() ?? 'string';
        if (key.isEmpty || type != 'select') {
          continue;
        }
        final options = ((field['options'] as List?) ?? <dynamic>[])
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList();
        _manualSelectValues[key] = options.isEmpty ? null : options.first;
      }

      _snack('Pengajuan layanan manual berhasil dibuat');
      await _load();
    } on ApiError catch (error) {
      _snack(error.message);
    }
  }

  Widget _renderManualField(Map<String, dynamic> field) {
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
        contentPadding: EdgeInsets.zero,
        value: _manualBoolValues[key] ?? false,
        onChanged: (value) => setState(() => _manualBoolValues[key] = value),
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
          initialValue: _manualSelectValues[key],
          decoration: InputDecoration(labelText: required ? '$label *' : label),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: (value) =>
              setState(() => _manualSelectValues[key] = value),
        ),
      );
    }

    if (type == 'date') {
      final value = _manualDateValues[key];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton.icon(
          onPressed: () => _pilihTanggalManual(key),
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
        controller: _manualTextControllers[key],
        decoration: InputDecoration(labelText: required ? '$label *' : label),
        keyboardType: type == 'number'
            ? TextInputType.number
            : TextInputType.text,
      ),
    );
  }

  Future<void> _updateStatusPengajuan(int id, String status) async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      await _api.updateServiceStatus(
        token: token,
        applicationId: id,
        status: status,
        adminNote: 'Diperbarui dari dashboard admin',
      );

      _snack('Status pengajuan berhasil diperbarui');
      await _load();
    } on ApiError catch (error) {
      _snack(error.message);
    }
  }

  Future<void> _kirimBroadcast() async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      final filter = <String, dynamic>{};
      if (_targetBroadcast == 'role') {
        filter['role'] = _roleBroadcastController.text.trim().isEmpty
            ? 'jemaat'
            : _roleBroadcastController.text.trim();
      }

      final result = await _api.broadcastNotification(
        token: token,
        title: _judulBroadcastController.text.trim(),
        message: _pesanBroadcastController.text.trim(),
        targetType: _targetBroadcast,
        targetFilters: filter.isEmpty ? null : filter,
      );

      setState(() {
        _hasilBroadcast = 'Target ${result['target_count'] ?? 0}, berhasil ${result['success_count'] ?? 0}, gagal ${result['failed_count'] ?? 0}';
      });
      final success = (result['success_count'] as num?)?.toInt() ?? 0;
      if (success > 0) {
        _snack('Broadcast terkirim ke $success device');
      } else {
        _snack('Broadcast tersimpan (Menunggu konfigurasi FCM server)');
      }
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
      debugPrint('🔴 Logout: Confirmed, starting logout process');
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        debugPrint('🔴 Logout: Calling session.signOut()');
        await widget.session.signOut();
        debugPrint('🟢 Logout: session.signOut() completed successfully');
        
        if (mounted) {
          // Close the loading dialog
          Navigator.of(context).pop();
          debugPrint('🟢 Logout: Loading dialog closed');
        }
      } catch (e, stackTrace) {
        debugPrint('🔴 Logout ERROR: $e');
        debugPrint('🔴 Logout STACK TRACE: $stackTrace');
        
        if (mounted) {
          // Close the loading dialog
          Navigator.of(context).pop();
          // Show error message with details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal logout: $e'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1100;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin GPI Yehuda'),
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
      floatingActionButton: _menu == 4
          ? FloatingActionButton.extended(
              onPressed: _bukaFormManual,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Manual'),
            )
          : null,
      drawer: desktop ? null : Drawer(child: _sideMenu(closeOnSelect: true)),
      body: Row(
        children: [
          if (desktop)
            Container(
              width: 290,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: _sideMenu(closeOnSelect: false),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _contentByMenu(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideMenu({required bool closeOnSelect}) {
    final items = [
      ('Ringkasan', Icons.space_dashboard_outlined),
      ('Kelola Event', Icons.event_note_outlined),
      ('Kategori Event', Icons.category_outlined),
      ('Form Builder Layanan', Icons.dashboard_customize_outlined),
      ('Pengajuan Layanan', Icons.assignment_outlined),
      // ('Data Kartu Keluarga', Icons.groups_2_outlined), // Disembunyikan sementara
      ('Manajemen Jemaat', Icons.people_outline),
      ('Kelola Berita', Icons.newspaper_outlined),
      ('Broadcast', Icons.campaign_outlined),
      ('Edit Profil', Icons.person_outline),
      ('Profil Gereja', Icons.church_outlined),
    ];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ChurchLogo(
                  logo: _profilGereja['logo'] as Map<String, dynamic>?,
                  isDark: widget.darkMode,
                  height: 42,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Admin GPI Yehuda',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++)
            ListTile(
              leading: Icon(items[i].$2),
              title: Text(items[i].$1),
              selected: _menu == i,
              selectedTileColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 2,
              ),
              onTap: () {
                setState(() => _menu = i);
                if (closeOnSelect) {
                  Navigator.of(context).pop();
                }
              },
            ),
          if (_pwaController.canInstall ||
              _pwaController.shouldShowIOSGuide)
            ListTile(
              leading: const Icon(Icons.download_for_offline_outlined),
              title: const Text('Install App'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 2,
              ),
              onTap: () {
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
                if (closeOnSelect) {
                  Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _contentByMenu() {
    switch (_menu) {
      case 1:
        return _modulEvent();
      case 2:
        return _modulKategoriEvent();
      case 3:
        return _modulBuilderTemplate();
      case 4:
        return _modulPengajuan();
      case 5:
        return _modulManajemenJemaat();
      case 6:
        return _modulBerita();
      case 7:
        return _modulBroadcast();
      case 8:
        return _modulEditProfilAdmin();
      case 9:
        return _modulProfilGereja();
      default:
        return _modulRingkasan();
    }
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    return _events.where((event) {
      final title = (event['title'] as String?) ?? '';
      final category = (event['category'] as String?) ?? '';
      final matchSearch = title.toLowerCase().contains(
        _eventSearchQuery.toLowerCase(),
      );
      final matchCategory =
          _eventCategoryFilter == null || _eventCategoryFilter!.isEmpty
          ? true
          : category == _eventCategoryFilter;
      return matchSearch && matchCategory;
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredPengajuan() {
    return _pengajuan.where((app) {
      final userName = (app['user']?['name'] as String?) ?? '';
      final userKk = (app['nomor_kk_snapshot'] as String?) ?? '';
      final category = (app['category'] as String?) ?? '';
      final searchLower = _pengajuanSearchQuery.toLowerCase();
      final matchSearch =
          userName.toLowerCase().contains(searchLower) ||
          userKk.toLowerCase().contains(searchLower);
      final matchCategory =
          _pengajuanCategoryFilter == null || _pengajuanCategoryFilter!.isEmpty
          ? true
          : category == _pengajuanCategoryFilter;
      return matchSearch && matchCategory;
    }).toList();
  }

  List<Map<String, dynamic>> _paginate(
    List<Map<String, dynamic>> items,
    int page,
    int perPage,
  ) {
    if (items.isEmpty) return [];
    if (page < 1) page = 1;
    final start = (page - 1) * perPage;
    final end = start + perPage;
    return items.sublist(
      start,
      start + perPage > items.length ? items.length : end,
    );
  }

  int _getTotalPages(int totalItems, int perPage) {
    return (totalItems / perPage).ceil();
  }

  List<DataRow> _buildEventTableRows() {
    final filtered = _getFilteredEvents();
    final totalPages = _getTotalPages(filtered.length, _eventPerPage);
    final currentPage = _eventPage > totalPages ? totalPages : _eventPage;
    final paged = _paginate(filtered, currentPage, _eventPerPage);

    return paged.map((event) {
      final startAt =
          (event['start_at'] as String?) ?? (event['date'] as String?) ?? '-';
      final endAt = (event['end_at'] as String?) ?? '-';
      final category = _namaKategori(
        _kategoriEvent,
        (event['category'] as String?) ?? '-',
      );

      return DataRow(
        cells: [
          DataCell(Text((event['title'] as String?) ?? '-')),
          DataCell(Text(category)),
          DataCell(Text(startAt)),
          DataCell(Text(endAt)),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    _showEventDetail(event);
                  },
                  tooltip: 'Lihat Detail',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _editEvent(event);
                  },
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDeleteEvent(event),
                  tooltip: 'Hapus Event',
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  void _showEventDetail(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text((event['title'] as String?) ?? '-'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori: ${_namaKategori(_kategoriEvent, (event['category'] as String?) ?? '-')}',
              ),
              const SizedBox(height: 8),
              Text('Deskripsi: ${(event['description'] as String?) ?? '-'}'),
              const SizedBox(height: 8),
              Text(
                'Mulai: ${(event['start_at'] as String?) ?? (event['date'] as String?) ?? '-'}',
              ),
              const SizedBox(height: 8),
              Text('Selesai: ${(event['end_at'] as String?) ?? '-'}'),
              const SizedBox(height: 8),
              Text(
                'Lokasi: ${(event['location']?['address'] as String?) ?? '-'}',
              ),
            ],
          ),
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

  void _editEvent(Map<String, dynamic> event) {
    _editingEventId = (event['id'] as num?)?.toInt();
    _judulEventController.text = (event['title'] as String?) ?? '';
    _deskripsiEventController.text = (event['description'] as String?) ?? '';
    _alamatEventController.text =
        (event['location']?['address'] as String?) ?? '';
    _kategoriEventTerpilih = (event['category'] as String?) ?? '';

    final startStr =
        (event['start_at'] as String?) ?? (event['date'] as String?);
    if (startStr != null) {
      _waktuMulaiEvent = DateTime.tryParse(startStr);
    }

    final endStr = (event['end_at'] as String?);
    if (endStr != null) {
      _waktuSelesaiEvent = DateTime.tryParse(endStr);
    }

    setState(() {});
    _snack('Edit event - ubah field dan simpan ulang');
  }

  void _confirmDeleteEvent(Map<String, dynamic> event) {
    final id = (event['id'] as num?)?.toInt();
    if (id == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Event?'),
        content: Text('Anda yakin ingin menghapus "${event['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _hapusEvent(id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _hapusEvent(int id) async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) return;

      await _api.deleteEvent(token: token, id: id);
      _snack('Event berhasil dihapus');
      await _load();
    } on ApiError catch (error) {
      _snack(error.message);
    }
  }

  Widget _modulRingkasan() {
    final theme = Theme.of(context);
    return ListView(
      key: const ValueKey('ringkasan'),
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
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel Operasional Admin',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                'Kelola event, template form builder, pengajuan layanan, dan broadcast dalam satu tempat.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metricCard('Event', _events.length.toString(), Icons.event),
            _metricCard(
              'Template',
              _templates.length.toString(),
              Icons.dashboard_customize,
            ),
            _metricCard(
              'Pengajuan',
              _pengajuan.length.toString(),
              Icons.assignment,
            ),
            _metricCard(
              'Jemaat',
              _jemaat.length.toString(),
              Icons.people_alt_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _modulEvent() {
    return ListView(
      key: const ValueKey('event'),
      children: [
        const Text(
          'Kelola Event',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _judulEventController,
                  decoration: const InputDecoration(labelText: 'Judul Event'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _deskripsiEventController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _kategoriEventTerpilih,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Event',
                  ),
                  items: _kategoriEvent
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
                  onChanged: (value) =>
                      setState(() => _kategoriEventTerpilih = value),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _alamatEventController,
                  decoration: const InputDecoration(labelText: 'Alamat Lokasi'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pilihWaktuEvent(mulai: true),
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          _waktuMulaiEvent == null
                              ? 'Pilih Waktu Mulai'
                              : _formatDateTime(_waktuMulaiEvent!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pilihWaktuEvent(mulai: false),
                        icon: const Icon(Icons.schedule_send),
                        label: Text(
                          _waktuSelesaiEvent == null
                              ? 'Pilih Waktu Selesai'
                              : _formatDateTime(_waktuSelesaiEvent!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _buatEvent,
                    icon: const Icon(Icons.add),
                    label: const Text('Simpan Event'),
                  ),
                ),
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
                  'Daftar Event',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                // Search & Filter
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Cari judul event...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _eventSearchQuery = value;
                            _eventPage = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _eventCategoryFilter,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Semua'),
                          ),
                          ..._kategoriEvent.map(
                            (item) => DropdownMenuItem<String?>(
                              value: item['code']?.toString(),
                              child: Text(
                                item['name']?.toString() ??
                                    item['code']?.toString() ??
                                    '-',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _eventCategoryFilter = value;
                            _eventPage = 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Table
                if (_events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada event'),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(
                          label: Text('Judul'),
                          tooltip: 'Judul Event',
                        ),
                        DataColumn(label: Text('Kategori')),
                        DataColumn(label: Text('Mulai')),
                        DataColumn(label: Text('Selesai')),
                        DataColumn(label: Text('Aksi')),
                      ],
                      rows: _buildEventTableRows(),
                    ),
                  ),
                const SizedBox(height: 12),
                // Pagination
                if (_getFilteredEvents().isNotEmpty)
                  Center(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_eventPage > 1)
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _eventPage--),
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Sebelumnya'),
                          ),
                        Text('Halaman $_eventPage'),
                        if (_eventPage <
                            _getTotalPages(
                              _getFilteredEvents().length,
                              _eventPerPage,
                            ))
                          FilledButton.icon(
                            onPressed: () => setState(() => _eventPage++),
                            icon: const Icon(Icons.chevron_right),
                            label: const Text('Selanjutnya'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _modulBuilderTemplate() {
    return ListView(
      key: const ValueKey('builder'),
      children: [
        const Text(
          'Form Builder Layanan',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pilih kategori, muat template existing, lalu update field sesuai kebutuhan.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _kategoriTemplateTerpilih,
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
                            _kategoriTemplateTerpilih = value;
                          });
                          _muatTemplateDariKategori(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _muatTemplateDariKategori(_kategoriTemplateTerpilih),
                      icon: const Icon(Icons.file_open_outlined),
                      label: const Text('Muat Existing'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _namaTemplateController,
                  decoration: const InputDecoration(labelText: 'Nama Template'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Daftar Field',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ..._fieldsBuilder.asMap().entries.map((entry) {
                  final index = entry.key;
                  final field = entry.value;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextField(
                            controller: TextEditingController(
                              text: field.label,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Label Field',
                            ),
                            onChanged: (value) => field.label = value,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: TextEditingController(
                              text: field.keyField,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Key Field (contoh: nama_lengkap)',
                            ),
                            onChanged: (value) => field.keyField = value,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: field.type,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipe Data',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'string',
                                      child: Text('string'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'number',
                                      child: Text('number'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'boolean',
                                      child: Text('boolean'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'date',
                                      child: Text('date'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'select',
                                      child: Text('select'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      field.type = value ?? 'string';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: field.requiredField,
                                  onChanged: (value) => setState(
                                    () => field.requiredField = value,
                                  ),
                                  title: const Text('Wajib'),
                                ),
                              ),
                            ],
                          ),
                          if (field.type == 'select') ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: TextEditingController(
                                text: field.optionsText,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Opsi Select (pisahkan dengan koma)',
                              ),
                              onChanged: (value) => field.optionsText = value,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: _fieldsBuilder.length <= 1
                                  ? null
                                  : () => setState(() {
                                      _fieldsBuilder.removeAt(index);
                                    }),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(
                      () => _fieldsBuilder.add(_FieldBuilderState.standar()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Field'),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _simpanTemplate,
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Template'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final template in _templates)
                  ListTile(
                    title: Text(
                      _namaKategori(
                        _kategoriLayanan,
                        (template['category'] as String?) ?? '-',
                      ),
                    ),
                    subtitle: Text((template['name'] as String?) ?? '-'),
                    trailing: IconButton(
                      onPressed: () => _hapusTemplate(
                        (template['category'] as String?) ?? '',
                      ),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _bukaFormManual() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final fieldsManual = _fieldsManualAktif();
          return AlertDialog(
            title: const Text('Input Manual oleh Admin'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _jemaatTerpilihId,
                      decoration: const InputDecoration(labelText: 'Pilih Jemaat'),
                      items: _jemaat
                          .map(
                            (item) => DropdownMenuItem<int>(
                              value: (item['id'] as num?)?.toInt(),
                              child: Text(
                                '${(item['name'] as String?) ?? '-'} (${(item['username'] as String?) ?? '-'})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => 
                          setDialogState(() {
                            setState(() => _jemaatTerpilihId = value);
                          }),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _kategoriManualTerpilih,
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
                        setDialogState(() {
                          setState(() {
                            _kategoriManualTerpilih = value;
                            _siapkanFormManual();
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    if (fieldsManual.isEmpty)
                      const Text(
                        'Template kategori ini belum tersedia. Silakan buat template dulu di Form Builder.',
                      )
                    else
                      ...fieldsManual.map((field) => _renderManualField(field)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lampiranManualController,
                      decoration: const InputDecoration(
                        labelText: 'Lampiran URL (pisahkan koma)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                onPressed: fieldsManual.isEmpty 
                    ? null 
                    : () {
                        Navigator.pop(context);
                        _buatPengajuanManual();
                      },
                icon: const Icon(Icons.edit_note),
                label: const Text('Kirim Pengajuan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _modulPengajuan() {
    return ListView(
      key: const ValueKey('pengajuan'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pengajuan Layanan',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daftar Pengajuan Layanan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _downloadSemuaPengajuanCsv,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Unduh Semua (CSV)'),
                  ),
                ),
                const SizedBox(height: 8),
                // Search & Filter
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Cari nama atau no KK...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _pengajuanSearchQuery = value;
                            _pengajuanPage = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _pengajuanCategoryFilter,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Semua'),
                          ),
                          ..._kategoriLayanan.map(
                            (item) => DropdownMenuItem<String?>(
                              value: item['code']?.toString(),
                              child: Text(
                                item['name']?.toString() ??
                                    item['code']?.toString() ??
                                    '-',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _pengajuanCategoryFilter = value;
                            _pengajuanPage = 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Table
                if (_pengajuan.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada pengajuan layanan'),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 12,
                      columns: const [
                        DataColumn(label: Text('ID'), tooltip: 'ID Pengajuan'),
                        DataColumn(label: Text('Pemohon')),
                        DataColumn(label: Text('No KK')),
                        DataColumn(label: Text('Kategori')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Aksi')),
                      ],
                      rows: _buildPengajuanTableRows(),
                    ),
                  ),
                const SizedBox(height: 12),
                // Pagination
                if (_getFilteredPengajuan().isNotEmpty)
                  Center(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_pengajuanPage > 1)
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _pengajuanPage--),
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Sebelumnya'),
                          ),
                        Text('Halaman $_pengajuanPage'),
                        if (_pengajuanPage <
                            _getTotalPages(
                              _getFilteredPengajuan().length,
                              _pengajuanPerPage,
                            ))
                          FilledButton.icon(
                            onPressed: () => setState(() => _pengajuanPage++),
                            icon: const Icon(Icons.chevron_right),
                            label: const Text('Selanjutnya'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<DataRow> _buildPengajuanTableRows() {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final filtered = _getFilteredPengajuan();
    final totalPages = _getTotalPages(filtered.length, _pengajuanPerPage);
    final currentPage = _pengajuanPage > totalPages
        ? totalPages
        : _pengajuanPage;
    final paged = _paginate(filtered, currentPage, _pengajuanPerPage);

    return paged.map((item) {
      final id = (item['id'] as num?)?.toInt() ?? 0;
      final category = _namaKategori(
        _kategoriLayanan,
        (item['category'] as String?) ?? '-',
      );
      final status = (item['status'] as String?) ?? 'pending';
      final user = item['user'] as Map<String, dynamic>?;
      final noKk = (item['nomor_kk_snapshot'] as String?) ?? '-';

      return DataRow(
        cells: [
          DataCell(Text('#$id')),
          DataCell(Text((user?['name'] as String?) ?? '-')),
          DataCell(Text(noKk)),
          DataCell(Text(category)),
          DataCell(
            Chip(
              label: Text(status),
              backgroundColor: _statusBackgroundColor(status, appColors),
              labelStyle: TextStyle(
                color: _statusTextColor(status, appColors),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _showPengajuanDetail(item),
                  tooltip: 'Lihat Detail',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editPengajuan(item),
                  tooltip: 'Edit Pengajuan',
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => _downloadPengajuanPdf(id),
                  tooltip: 'Unduh PDF',
                ),
                if (status == 'pending')
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _updateStatusPengajuan(id, 'approved'),
                    tooltip: 'Setujui',
                  ),
                if (status == 'pending')
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _updateStatusPengajuan(id, 'rejected'),
                    tooltip: 'Tolak',
                  ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Future<void> _downloadPengajuanPdf(int applicationId) async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      final bytes = await _api.downloadServiceCertificate(
        token: token,
        applicationId: applicationId,
      );

      final savedPath = await saveDownloadedBytes(
        bytes: bytes,
        fileName: 'pengajuan-$applicationId.pdf',
      );

      _snack(
        kIsWeb
            ? 'PDF berhasil diunduh: $savedPath'
            : 'PDF tersimpan: $savedPath',
      );
    } on ApiError catch (error) {
      _snack(error.message);
    } catch (_) {
      _snack('Gagal mengunduh PDF pengajuan');
    }
  }

  Future<void> _downloadSemuaPengajuanCsv() async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      final bytes = await _api.exportServiceApplicationsCsv(token);
      final savedPath = await saveDownloadedBytes(
        bytes: bytes,
        fileName: 'pengajuan-layanan.csv',
      );

      _snack(
        kIsWeb
            ? 'CSV berhasil diunduh: $savedPath'
            : 'CSV tersimpan: $savedPath',
      );
    } on ApiError catch (error) {
      _snack(error.message);
    } catch (_) {
      _snack('Gagal mengunduh CSV pengajuan');
    }
  }

  void _showPengajuanDetail(Map<String, dynamic> item) {
    final id = (item['id'] as num?)?.toInt() ?? 0;
    final category = _namaKategori(
      _kategoriLayanan,
      (item['category'] as String?) ?? '-',
    );
    final status = (item['status'] as String?) ?? 'pending';
    final user = item['user'] as Map<String, dynamic>?;
    final formData = (item['form_data'] as Map<String, dynamic>?) ?? {};
    final attachments = (item['attachments'] as List?) ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pengajuan #$id - $category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pemohon: ${(user?['name'] as String?) ?? '-'}'),
              const SizedBox(height: 8),
              Text('No KK: ${(item['nomor_kk_snapshot'] as String?) ?? '-'}'),
              const SizedBox(height: 8),
              Text('Status: $status'),
              const SizedBox(height: 12),
              const Text(
                'Data Pengajuan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...formData.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${e.key}: ${e.value}'),
                ),
              ),
              if (attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Lampiran:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...attachments.map((att) => Text('• $att')),
              ],
            ],
          ),
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

  Future<void> _editPengajuan(Map<String, dynamic> item) async {
    final token = widget.session.token;
    if (token == null || token.isEmpty) {
      _snack('Token tidak tersedia');
      return;
    }

    final applicationId = (item['id'] as num?)?.toInt();
    if (applicationId == null) {
      _snack('Pengajuan tidak valid');
      return;
    }

    final category = (item['category'] as String?) ?? '';
    final template = _templates.cast<Map<String, dynamic>?>().firstWhere(
      (it) => it?['category']?.toString() == category,
      orElse: () => null,
    );
    final fields =
        (template?['fields'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        <Map<String, dynamic>>[];

    if (fields.isEmpty) {
      _snack('Template kategori ini tidak tersedia untuk diedit.');
      return;
    }

    final formData =
        (item['form_data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final attachmentsController = TextEditingController(
      text: ((item['attachments'] as List?) ?? <dynamic>[])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .join(', '),
    );
    final textControllers = <String, TextEditingController>{};
    final boolValues = <String, bool>{};
    final selectValues = <String, String?>{};
    final dateValues = <String, DateTime?>{};

    for (final field in fields) {
      final key = field['key']?.toString() ?? '';
      final type = field['type']?.toString() ?? 'string';
      final raw = formData[key];
      if (key.isEmpty) {
        continue;
      }

      if (type == 'boolean') {
        boolValues[key] = raw == true || raw.toString().toLowerCase() == 'true';
      } else if (type == 'select') {
        final options = ((field['options'] as List?) ?? <dynamic>[])
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList();
        final selected = raw?.toString();
        selectValues[key] = options.contains(selected)
            ? selected
            : (options.isNotEmpty ? options.first : null);
      } else if (type == 'date') {
        if (raw == null) {
          dateValues[key] = null;
        } else {
          dateValues[key] = DateTime.tryParse(raw.toString());
        }
      } else {
        textControllers[key] = TextEditingController(
          text: raw?.toString() ?? '',
        );
      }
    }

    if (!mounted) {
      attachmentsController.dispose();
      for (final controller in textControllers.values) {
        controller.dispose();
      }
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate(String key) async {
              final now = DateTime.now();
              final initial = dateValues[key] ?? now;
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(now.year - 100),
                lastDate: DateTime(now.year + 20),
              );
              if (picked == null) {
                return;
              }
              setDialogState(() {
                dateValues[key] = picked;
              });
            }

            Widget buildField(Map<String, dynamic> field) {
              final key = field['key']?.toString() ?? '';
              final label =
                  (field['label']?.toString().trim().isNotEmpty ?? false)
                  ? field['label'].toString()
                  : key;
              final type = field['type']?.toString() ?? 'string';
              final required = field['required'] == true;

              if (key.isEmpty) {
                return const SizedBox.shrink();
              }

              if (type == 'boolean') {
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: boolValues[key] ?? false,
                  onChanged: (value) =>
                      setDialogState(() => boolValues[key] = value),
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
                    initialValue: selectValues[key],
                    decoration: InputDecoration(
                      labelText: required ? '$label *' : label,
                    ),
                    items: options
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectValues[key] = value),
                  ),
                );
              }

              if (type == 'date') {
                final value = dateValues[key];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => pickDate(key),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      value == null
                          ? (required ? 'Pilih $label *' : 'Pilih $label')
                          : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: textControllers[key],
                  decoration: InputDecoration(
                    labelText: required ? '$label *' : label,
                  ),
                  keyboardType: type == 'number'
                      ? TextInputType.number
                      : TextInputType.text,
                ),
              );
            }

            return AlertDialog(
              title: Text('Edit Pengajuan #$applicationId'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori: ${_namaKategori(_kategoriLayanan, category)}',
                      ),
                      const SizedBox(height: 12),
                      ...fields.map(buildField),
                      const SizedBox(height: 8),
                      TextField(
                        controller: attachmentsController,
                        decoration: const InputDecoration(
                          labelText: 'Lampiran URL (pisahkan koma)',
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
                    final updatedFormData = <String, dynamic>{};
                    for (final field in fields) {
                      final key = field['key']?.toString() ?? '';
                      final type = field['type']?.toString() ?? 'string';
                      final required = field['required'] == true;

                      if (key.isEmpty) {
                        continue;
                      }

                      if (type == 'boolean') {
                        updatedFormData[key] = boolValues[key] ?? false;
                        continue;
                      }

                      if (type == 'select') {
                        final selected = selectValues[key];
                        if (required &&
                            (selected == null || selected.isEmpty)) {
                          _snack('Field "$key" wajib dipilih');
                          return;
                        }
                        if (selected != null && selected.isNotEmpty) {
                          updatedFormData[key] = selected;
                        }
                        continue;
                      }

                      if (type == 'date') {
                        final value = dateValues[key];
                        if (required && value == null) {
                          _snack('Field "$key" wajib diisi');
                          return;
                        }
                        if (value != null) {
                          updatedFormData[key] = _formatDateOnly(value);
                        }
                        continue;
                      }

                      final text = textControllers[key]?.text.trim() ?? '';
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
                        updatedFormData[key] = numValue;
                      } else {
                        updatedFormData[key] = text;
                      }
                    }

                    final lampiran = attachmentsController.text
                        .split(',')
                        .map((value) => value.trim())
                        .where((value) => value.isNotEmpty)
                        .toList();

                    try {
                      await _api.updateServiceApplication(
                        token: token,
                        applicationId: applicationId,
                        category: category,
                        formData: updatedFormData,
                        attachments: lampiran,
                      );
                      if (!context.mounted || !mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                      _snack('Pengajuan berhasil diperbarui');
                      await _load();
                    } on ApiError catch (error) {
                      _snack(error.message);
                    }
                  },
                  child: const Text('Simpan Perubahan'),
                ),
              ],
            );
          },
        );
      },
    );

    attachmentsController.dispose();
    for (final controller in textControllers.values) {
      controller.dispose();
    }
  }

  List<Map<String, dynamic>> _getFilteredKeluarga() {
    final search = _keluargaSearchQuery.trim().toLowerCase();
    if (search.isEmpty) {
      return _keluarga;
    }

    return _keluarga.where((row) {
      final nomorKk = (row['nomor_kk'] as String?)?.toLowerCase() ?? '';
      final members =
          (row['members'] as List?)?.whereType<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      final matchKk = nomorKk.contains(search);
      final matchMember = members.any((m) {
        final name = (m['name'] as String?)?.toLowerCase() ?? '';
        final username = (m['username'] as String?)?.toLowerCase() ?? '';
        final email = (m['email'] as String?)?.toLowerCase() ?? '';
        return name.contains(search) ||
            username.contains(search) ||
            email.contains(search);
      });

      return matchKk || matchMember;
    }).toList();
  }

  // ignore: unused_element
  List<DataRow> _buildKeluargaTableRows() {
    final filtered = _getFilteredKeluarga();
    final totalPages = _getTotalPages(filtered.length, _keluargaPerPage);
    final currentPage = _keluargaPage > totalPages ? totalPages : _keluargaPage;
    final paged = _paginate(filtered, currentPage, _keluargaPerPage);

    return paged.map((row) {
      final nomorKk = (row['nomor_kk'] as String?) ?? '-';
      final totalMembers = (row['total_members'] as num?)?.toInt() ?? 0;
      final members =
          (row['members'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          <Map<String, dynamic>>[];
      final memberNames = members
          .map((m) => (m['name'] as String?)?.trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      return DataRow(
        cells: [
          DataCell(Text(nomorKk)),
          DataCell(Text(totalMembers.toString())),
          DataCell(
            Text(
              memberNames.isEmpty ? '-' : memberNames.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DataCell(
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'Lihat anggota keluarga',
              onPressed: () => _showKeluargaDetail(row),
            ),
          ),
        ],
      );
    }).toList();
  }

  void _showKeluargaDetail(Map<String, dynamic> row) {
    final nomorKk = (row['nomor_kk'] as String?) ?? '-';
    final members =
        (row['members'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
        <Map<String, dynamic>>[];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kartu Keluarga $nomorKk'),
        content: SizedBox(
          width: 520,
          child: members.isEmpty
              ? const Text('Belum ada anggota keluarga.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final member = members[index];
                    final name = (member['name'] as String?) ?? '-';
                    final username = (member['username'] as String?) ?? '-';
                    final email = (member['email'] as String?) ?? '-';
                    return ListTile(
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(name),
                      subtitle: Text('$username • $email'),
                    );
                  },
                ),
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

  Widget _modulKartuKeluarga() {
    return AdminKkManagementPage(session: widget.session);
  }

  Future<void> _simpanKategoriEvent() async {
    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      final kode = _kodeKategoriController.text.trim();
      final nama = _namaKategoriController.text.trim();

      if (kode.isEmpty || nama.isEmpty) {
        _snack('Kode dan nama kategori wajib diisi');
        return;
      }

      if (_selectedEditKategoriId == 0) {
        await _api.createEventCategory(token: token, body: {
          'code': kode,
          'name': nama,
          'is_active': _kategoriAktifEdit,
        });
        _snack('Kategori $nama berhasil ditambah');
      } else {
        await _api.updateEventCategory(
          token: token,
          id: _selectedEditKategoriId,
          body: {
            'name': nama,
            'is_active': _kategoriAktifEdit,
          },
        );
        _snack('Kategori $nama berhasil diperbarui');
      }

      _kodeKategoriController.clear();
      _namaKategoriController.clear();
      setState(() {
        _selectedEditKategoriId = 0;
        _kategoriAktifEdit = true;
      });

      await _load();
    } on ApiError catch (error) {
      _snack(error.message);
    }
  }

  Future<void> _hapusKategoriEvent() async {
    if (_selectedEditKategoriId == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: const Text('Apakah Anda yakin ingin menghapus kategori ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
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

      await _api.deleteEventCategory(
        token: token,
        id: _selectedEditKategoriId,
      );

      _kodeKategoriController.clear();
      _namaKategoriController.clear();
      _snack('Kategori berhasil dihapus');
      setState(() {
        _selectedEditKategoriId = 0;
        _kategoriAktifEdit = true;
      });

      await _load();
    } on ApiError catch (error) {
      _snack(error.message);
    }
  }

  Widget _modulKategoriEvent() {
    final theme = Theme.of(context);
    return ListView(
      key: const ValueKey('kategori-event'),
      children: [
        const Text(
          'Kategori Event',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _kodeKategoriController,
                  decoration: const InputDecoration(
                    labelText: 'Kode',
                    hintText: 'contoh: ibadah, persekutuan',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _namaKategoriController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kategori',
                    hintText: 'contoh: Ibadah Raya',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedEditKategoriId == 0 
                          ? 'Tambah Baru' 
                          : 'Edit Kategori',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    if (_selectedEditKategoriId != 0)
                      TextButton.icon(
                        onPressed: () {
                          _kodeKategoriController.clear();
                          _namaKategoriController.clear();
                          _kategoriAktifEdit = true;
                          setState(() => _selectedEditKategoriId = 0);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Batal Edit'),
                      ),
                  ],
                ),
                if (_selectedEditKategoriId != 0) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _kategoriAktifEdit,
                    onChanged: (v) => setState(() => _kategoriAktifEdit = v ?? true),
                    title: const Text('Aktif'),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _simpanKategoriEvent,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _selectedEditKategoriId == 0
                          ? 'Tambah Kategori'
                          : 'Simpan Perubahan',
                    ),
                  ),
                ),
                if (_selectedEditKategoriId != 0) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _hapusKategoriEvent,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus Kategori'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
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
                  'Daftar Kategori',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (_kategoriEvent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada kategori event'),
                  )
                else
                  ..._kategoriEvent.map((item) {
                    final aktif = (item['is_active'] as bool?) ?? true;
                    final itemId = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
                    return ListTile(
                      title: Text(item['name']?.toString() ?? '-'),
                      subtitle: Text(
                        '${item['code']} • ${aktif ? 'Aktif' : 'Nonaktif'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit Kategori',
                            onPressed: () {
                              _kodeKategoriController.text = item['code']?.toString() ?? '';
                              _namaKategoriController.text = item['name']?.toString() ?? '';
                              _kategoriAktifEdit = aktif;
                              setState(() {
                                _selectedEditKategoriId = itemId;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Hapus Kategori',
                            onPressed: () async {
                              _selectedEditKategoriId = itemId;
                              await _hapusKategoriEvent();
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        _kodeKategoriController.text = item['code']?.toString() ?? '';
                        _namaKategoriController.text = item['name']?.toString() ?? '';
                        _kategoriAktifEdit = aktif;
                        setState(() {
                          _selectedEditKategoriId = itemId;
                        });
                      },
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _modulBerita() {
    return ListView(
      key: const ValueKey('berita'),
      children: [
        const Text(
          'Kelola Berita',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _judulBeritaController,
                  decoration: const InputDecoration(labelText: 'Judul Berita'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _deskripsiBeritaController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Singkat',
                    hintText: 'Ringkasan yang tampil di list berita (opsional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _kontenBeritaController,
                  minLines: 4,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: 'Konten Lengkap',
                    hintText: 'Isi berita selengkapnya...',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _coverBeritaController,
                        decoration: const InputDecoration(
                          labelText: 'URL Cover Image (opsional - atau upload file)',
                          hintText: 'https://...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final file = await _imagePicker.pickImage(source: ImageSource.gallery);
                        if (file != null) {
                          setState(() {
                            _coverBeritaFile = file;
                            _coverBeritaController.text = file.name;
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: Text(_coverBeritaFile != null ? 'Ganti File' : 'Upload'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pilihTanggalTerbit,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          _tanggalTerbitBerita == null
                              ? 'Pilih Tanggal Terbit'
                              : _formatDateOnly(_tanggalTerbitBerita!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lampiranBeritaController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Lampiran File (opsional - atau upload file)',
                          hintText: 'Pilih file...',
                          prefixIcon: Icon(Icons.attach_file),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pilihFileBerita,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_beritaFiles.isEmpty ? 'Upload' : 'Tambah'),
                    ),
                  ],
                ),
                if (_beritaFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _beritaFiles.map((f) {
                      return Chip(
                        label: Text(
                          f.name.length > 30
                              ? '${f.name.substring(0, 27)}...'
                              : f.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() {
                          _beritaFiles.remove(f);
                          _lampiranBeritaController.text = _beritaFiles
                              .map((file) => file.name)
                              .join(', ');
                        }),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _uploadingBerita ? null : _simpanBerita,
                    icon: _uploadingBerita
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_uploadingBerita ? 'Menyimpan...' : 'Simpan Berita'),
                  ),
                ),
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
                  'Daftar Berita',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (_beritaList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada berita'),
                  )
                else
                  ..._beritaList.map((berita) {
                    final id = (berita['id'] as num?)?.toInt() ?? 0;
                    final tanggalLabel = formatTanggalString(
                      berita['published_at'] as String? ??
                          berita['created_at'] as String?,
                      useLong: true,
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text((berita['title'] as String?) ?? 'Tanpa Judul'),
                        subtitle: Text(
                          'Terbit: $tanggalLabel',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit',
                              onPressed: () => _editBerita(berita),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Hapus',
                              onPressed: () => _hapusBerita(id),
                            ),
                          ],
                        ),
                        onTap: () => _lihatDetailBerita(berita),
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

  Future<void> _pilihTanggalTerbit() async {
    final now = DateTime.now();
    final initial = _tanggalTerbitBerita ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _tanggalTerbitBerita = picked;
    });
  }

  Future<void> _pilihFileBerita() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf', 'zip'],
      allowMultiple: true,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      for (final file in result.files) {
        if (kIsWeb) {
          if (file.bytes != null) {
            _beritaFiles.add(_PickedFile(name: file.name, bytes: file.bytes));
          }
        } else {
          if (file.path != null) {
            _beritaFiles.add(_PickedFile(name: file.name, path: file.path));
          }
        }
      }
      _lampiranBeritaController.text = _beritaFiles.map((f) => f.name).join(', ');
    });
  }

  Future<void> _simpanBerita() async {
    if (_uploadingBerita) return;

    setState(() => _uploadingBerita = true);

    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      final coverUrl = _coverBeritaController.text.trim();
      final body = <String, dynamic>{
        'title': _judulBeritaController.text.trim(),
        'content': _kontenBeritaController.text.trim(),
        'published_at': _tanggalTerbitBerita?.toIso8601String() ??
            DateTime.now().toIso8601String(),
      };

      final deskripsi = _deskripsiBeritaController.text.trim();
      if (deskripsi.isNotEmpty) body['description'] = deskripsi;

      if (coverUrl.isNotEmpty && _coverBeritaFile == null) {
        body['cover_image'] = {
          'url': coverUrl,
          'disk': 'public',
          'path': coverUrl,
        };
      }

      Uint8List? coverBytes;
      String? coverName;
      if (_coverBeritaFile != null && kIsWeb) {
        coverBytes = await _coverBeritaFile!.readAsBytes();
        coverName = _coverBeritaFile!.name;
      }

      final created = await _api.createNews(
        token: token,
        body: body,
        coverFilePath: kIsWeb ? null : _coverBeritaFile?.path,
        coverFileBytes: coverBytes,
        coverFileName: coverName,
      );
      final newsId = (created['id'] as num?)?.toInt();
      final newsTitle = created['title'] as String? ?? '';

      if (newsId != null && _beritaFiles.isNotEmpty) {
        final files = _beritaFiles
            .map((f) => <String, dynamic>{
                  if (f.path != null) 'path': f.path,
                  if (f.bytes != null) 'bytes': f.bytes,
                  'name': f.name
                })
            .toList();
        await _api.uploadNewsAttachments(token: token, newsId: newsId, files: files);
      }

      _judulBeritaController.clear();
      _deskripsiBeritaController.clear();
      _kontenBeritaController.clear();
      _coverBeritaController.clear();
      _lampiranBeritaController.clear();
      setState(() {
        _tanggalTerbitBerita = null;
        _coverBeritaFile = null;
        _beritaFiles.clear();
      });
      _snack('Berita "$newsTitle" berhasil dibuat');
      await _load();
    } on ApiError catch (error) {
      _snack(error.message);
    } finally {
      if (mounted) setState(() => _uploadingBerita = false);
    }
  }

  Future<void> _editBerita(Map<String, dynamic> berita) async {
    final id = (berita['id'] as num?)?.toInt() ?? 0;

    // Fetch full detail so 'content' is always available (list API omits it).
    Map<String, dynamic> fullBerita = berita;
    try {
      final token = widget.session.token;
      if (token != null && token.isNotEmpty && id > 0) {
        fullBerita = await _api.newsDetail(token: token, id: id);
      }
    } catch (_) {
      // Fall back to the list data if detail fetch fails.
    }

    _judulBeritaController.text = (fullBerita['title'] as String?) ?? '';
    _deskripsiBeritaController.text = (fullBerita['description'] as String?) ?? '';
    _kontenBeritaController.text = (fullBerita['content'] as String?) ?? '';
    final coverImage = fullBerita['cover_image'] as Map<String, dynamic>?;
    _coverBeritaController.text = coverImage?['url'] as String? ?? '';

    final publishedStr = fullBerita['published_at'] as String?;
    if (publishedStr != null) {
      _tanggalTerbitBerita = DateTime.tryParse(publishedStr);
    }


    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Berita'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _judulBeritaController,
                      decoration: const InputDecoration(labelText: 'Judul'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _deskripsiBeritaController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Singkat',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _kontenBeritaController,
                      minLines: 4,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        labelText: 'Konten Lengkap',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _coverBeritaController,
                            decoration: const InputDecoration(
                              labelText: 'URL Cover Image',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final file = await _imagePicker.pickImage(source: ImageSource.gallery);
                            if (file != null) {
                              setDialogState(() {
                                _coverBeritaFile = file;
                                _coverBeritaController.text = file.name;
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: Text(_coverBeritaFile != null ? 'Ganti File' : 'Upload'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final initial = _tanggalTerbitBerita ?? now;
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(now.year - 10),
                          lastDate: DateTime(now.year + 10),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            _tanggalTerbitBerita = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        _tanggalTerbitBerita == null
                            ? 'Pilih Tanggal Terbit'
                            : _formatDateOnly(_tanggalTerbitBerita!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _resetFormBerita();
                  Navigator.pop(ctx);
                },
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    final token = widget.session.token;
                    if (token == null || token.isEmpty) return;

                    final coverUrl = _coverBeritaController.text.trim();
                    final body = <String, dynamic>{
                      'title': _judulBeritaController.text.trim(),
                      'content': _kontenBeritaController.text.trim(),
                      if (_tanggalTerbitBerita != null)
                        'published_at': _tanggalTerbitBerita!.toIso8601String(),
                    };

                    final deskripsi = _deskripsiBeritaController.text.trim();
                    body['description'] = deskripsi.isNotEmpty ? deskripsi : null;

                    if (coverUrl.isNotEmpty && _coverBeritaFile == null) {
                      body['cover_image'] = {
                        'url': coverUrl,
                        'disk': 'public',
                        'path': coverUrl,
                      };
                    } else if (_coverBeritaFile == null) {
                      body['cover_image'] = null;
                    }

                    Uint8List? coverBytes;
                    String? coverName;
                    if (_coverBeritaFile != null && kIsWeb) {
                      coverBytes = await _coverBeritaFile!.readAsBytes();
                      coverName = _coverBeritaFile!.name;
                    }

                    await _api.updateNews(
                      token: token,
                      id: id,
                      body: body,
                      coverFilePath: kIsWeb ? null : _coverBeritaFile?.path,
                      coverFileBytes: coverBytes,
                      coverFileName: coverName,
                    );

                    if (!mounted) return;
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _resetFormBerita();
                    _snack('Berita berhasil diperbarui');
                    await _load();
                  } on ApiError catch (error) {
                    _snack(error.message);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _resetFormBerita() {
    _judulBeritaController.clear();
    _deskripsiBeritaController.clear();
    _kontenBeritaController.clear();
    _coverBeritaController.clear();
    if (mounted) {
      setState(() {
        _tanggalTerbitBerita = null;
        _coverBeritaFile = null;
      });
    }
  }

  Future<void> _hapusBerita(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Berita'),
        content: const Text('Apakah Anda yakin ingin menghapus berita ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
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

      await _api.deleteNews(token: token, id: id);
      _snack('Berita berhasil dihapus');
      await _load();
    } on ApiError catch (error) {
      _snack(error.message);
    }
  }

  void _lihatDetailBerita(Map<String, dynamic> berita) {
    final coverImage = berita['cover_image'] as Map<String, dynamic>?;
    final coverUrl = coverImage?['url'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          (berita['title'] as String?) ?? 'Berita',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (coverUrl != null && coverUrl.isNotEmpty) ...[
                  CachedImage(
                    url: coverUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  (berita['description'] as String?) ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(berita['content'] as String? ?? '-'),
                const SizedBox(height: 12),
                Text(
                  'Terbit: ${berita['published_at'] as String? ?? '-'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
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

  Widget _modulBroadcast() {
    return Card(
      key: const ValueKey('broadcast'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Broadcast Notifikasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _judulBroadcastController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pesanBroadcastController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Pesan'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _targetBroadcast,
              decoration: const InputDecoration(labelText: 'Target'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua pengguna')),
                DropdownMenuItem(
                  value: 'role',
                  child: Text('Berdasarkan role'),
                ),
                DropdownMenuItem(
                  value: 'service_applicants',
                  child: Text('Berdasarkan pengaju layanan'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _targetBroadcast = value ?? 'all'),
            ),
            if (_targetBroadcast == 'role') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _roleBroadcastController,
                decoration: const InputDecoration(
                  labelText: 'Role target',
                  helperText: 'Isi admin atau jemaat',
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _kirimBroadcast,
              icon: const Icon(Icons.campaign),
              label: const Text('Kirim Broadcast'),
            ),
            if (_hasilBroadcast != null) ...[
              const SizedBox(height: 10),
              Text(_hasilBroadcast!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _modulProfilGereja() {
    return SingleChildScrollView(
      child: Card(
        key: const ValueKey('profil'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              'Profil Gereja',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _namaGerejaController,
              decoration: const InputDecoration(labelText: 'Nama Gereja'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alamatGerejaController,
              decoration: const InputDecoration(labelText: 'Alamat'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _teleponGerejaController,
              decoration: const InputDecoration(labelText: 'Telepon'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailGerejaController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _logoGerejaController,
              decoration: const InputDecoration(
                labelText: 'URL Logo (opsional)',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Media Sosial',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _instagramController,
              decoration: const InputDecoration(
                labelText: 'Instagram',
                hintText: 'https://instagram.com/...',
                prefixIcon: Icon(Icons.camera_alt),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _youtubeController,
              decoration: const InputDecoration(
                labelText: 'YouTube',
                hintText: 'https://youtube.com/...',
                prefixIcon: Icon(Icons.play_circle),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tiktokController,
              decoration: const InputDecoration(
                labelText: 'TikTok',
                hintText: 'https://tiktok.com/@...',
                prefixIcon: Icon(Icons.music_note),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _facebookController,
              decoration: const InputDecoration(
                labelText: 'Facebook',
                hintText: 'https://facebook.com/...',
                prefixIcon: Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _simpanProfilGereja,
              icon: const Icon(Icons.save),
              label: const Text('Simpan Profil'),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _modulManajemenJemaat() {
    return AdminJemaatPage(session: widget.session);
  }

  Widget _modulEditProfilAdmin() {
    return AdminProfilePage(session: widget.session);
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
          Text(label),
        ],
      ),
    );
  }

  String _namaKategori(List<Map<String, dynamic>> source, String code) {
    final match = source.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['code']?.toString() == code,
      orElse: () => null,
    );
    if (match == null) {
      return code;
    }
    return match['name']?.toString() ?? code;
  }

  String _formatDateTime(DateTime value) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
  }

  String _formatDateOnly(DateTime value) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}';
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

class _PickedFile {
  _PickedFile({required this.name, this.path, this.bytes});

  final String name;
  final String? path;
  final Uint8List? bytes;
}

class _FieldBuilderState {
  _FieldBuilderState({
    required this.keyField,
    required this.label,
    required this.type,
    required this.requiredField,
    required this.optionsText,
  });

  factory _FieldBuilderState.standar() {
    return _FieldBuilderState(
      keyField: 'nama_lengkap',
      label: 'Nama Lengkap',
      type: 'string',
      requiredField: true,
      optionsText: '',
    );
  }

  String keyField;
  String label;
  String type;
  bool requiredField;
  String optionsText;
}
