import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session_controller.dart';

class JemaatEditProfilPage extends StatefulWidget {
  const JemaatEditProfilPage({super.key, required this.session});

  final SessionController session;

  @override
  State<JemaatEditProfilPage> createState() => _JemaatEditProfilPageState();
}

class _JemaatEditProfilPageState extends State<JemaatEditProfilPage> {
  late final ApiClient _api;

  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _alamatController = TextEditingController();
  final _usiaController = TextEditingController();
  final _phoneController = TextEditingController();

  String _jenisKelamin = 'L';
  String? _fotoProfilUrl;
  List<Map<String, dynamic>> _anggotaKeluarga = <Map<String, dynamic>>[];
  XFile? _selectedFotoFile;
  bool _showPasswordField = false;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingFoto = false;
  String? _error;
  String? _success;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _api = widget.session.apiClient;
    _loadProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _alamatController.dispose();
    _usiaController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
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
      _anggotaKeluarga = await _api.userFamilyMembers(token);

      _namaController.text = (me['name'] as String?) ?? '';
      _usernameController.text = (me['username'] as String?) ?? '';
      _emailController.text = (me['email'] as String?) ?? '';
      _alamatController.text = (me['alamat'] as String?) ?? '';
      _usiaController.text = ((me['usia'] as num?)?.toInt().toString()) ?? '';
      _phoneController.text = (me['phone_number'] as String?) ?? '';
      _jenisKelamin = (me['jenis_kelamin'] as String?) ?? 'L';
      _fotoProfilUrl = me['profile_photo_url'] as String?;
    } on ApiError catch (error) {
      _error =
          '${error.message}${error.traceId != null ? ' (trace: ${error.traceId})' : ''}';
    } catch (_) {
      _error = 'Gagal memuat profil';
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _pickFoto() async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      setState(() {
        _selectedFotoFile = file;
        _uploadingFoto = true;
      });

      final token = widget.session.token;
      if (token == null || token.isEmpty) return;

      final payload = await _api.uploadProfilePhoto(
        token: token,
        filePath: file.path,
      );

      final newUrl = payload['profile_photo_url'] as String?;

      if (newUrl != null && mounted) {
        final oldUrl = _fotoProfilUrl;
        _fotoProfilUrl = newUrl;
        _selectedFotoFile = null;

        if (oldUrl != null) {
          final provider = NetworkImage(oldUrl);
          await provider.evict();
        }
        if (mounted) {
          setState(() => _uploadingFoto = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui')),
          );
        }
      } else if (mounted) {
        setState(() => _uploadingFoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal upload foto: server tidak mengembalikan URL foto')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingFoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal upload foto')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });

    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      final usiaText = _usiaController.text.trim();
      final usia = usiaText.isNotEmpty ? int.tryParse(usiaText) : null;

      final body = <String, dynamic>{
        'name': _namaController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'jenis_kelamin': _jenisKelamin,
        'alamat': _alamatController.text.trim(),
        'usia': usia,
        if (_passwordController.text.isNotEmpty) ...{
          'password': _passwordController.text,
          'password_confirmation': _passwordController.text,
        },
      };

      await _api.updateMe(token, body);

      // Update session user data
      widget.session.updateCurrentUser(await _api.me(token));

      if (mounted) {
        setState(() {
          _success = 'Profil berhasil diperbarui';
          _passwordController.clear();
          _showPasswordField = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } on ApiError catch (error) {
      setState(() {
        _error =
            '${error.message}${error.traceId != null ? ' (trace: ${error.traceId})' : ''}';
      });
    } catch (_) {
      setState(() {
        _error = 'Gagal menyimpan profil';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null) ...[
              Container(
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
              const SizedBox(height: 16),
            ],
            if (_success != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _success!,
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    backgroundImage: _uploadingFoto
                        ? null
                        : _selectedFotoFile != null
                            ? FileImage(_xFileToFile(_selectedFotoFile!))
                            : (_fotoProfilUrl != null
                                ? NetworkImage(_fotoProfilUrl!)
                                : null),
                    child: _uploadingFoto
                        ? const SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _selectedFotoFile == null && _fotoProfilUrl == null
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: theme.colorScheme.onSurfaceVariant,
                              )
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: FloatingActionButton.small(
                      onPressed: _pickFoto,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _usernameController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Username (tidak bisa diubah)',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _jenisKelamin,
              decoration: const InputDecoration(
                labelText: 'Jenis Kelamin',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: const [
                DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                DropdownMenuItem(value: 'P', child: Text('Perempuan')),
              ],
              onChanged: (value) {
                setState(() {
                  _jenisKelamin = value ?? 'L';
                });
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _usiaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Usia',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              validator: (value) {
                if (value != null &&
                    value.trim().isNotEmpty &&
                    int.tryParse(value.trim()) == null) {
                  return 'Usia harus berupa angka';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _alamatController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                prefixIcon: Icon(Icons.location_on_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            if (_anggotaKeluarga.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Data Keluarga (${_anggotaKeluarga.length} anggota)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ..._anggotaKeluarga.map((anggota) {
                final nama = (anggota['name'] as String?) ?? '-';
                final username = (anggota['username'] as String?) ?? '-';
                final usia = anggota['usia']?.toString() ?? '-';
                final jk = ((anggota['jenis_kelamin'] as String?) == 'P')
                    ? 'Perempuan'
                    : 'Laki-laki';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(nama),
                    subtitle: Text('Username: $username • $jk • Usia: $usia'),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            CheckboxListTile(
              value: _showPasswordField,
              onChanged: (value) {
                setState(() {
                  _showPasswordField = value ?? false;
                  if (!_showPasswordField) {
                    _passwordController.clear();
                  }
                });
              },
              title: const Text('Ganti Password'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_showPasswordField) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru (minimal 8 karakter)',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (_showPasswordField && value != null && value.isNotEmpty) {
                    if (value.length < 8) {
                      return 'Password minimal 8 karakter';
                    }
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to convert XFile to File
File _xFileToFile(XFile xfile) {
  return File(xfile.path);
}
