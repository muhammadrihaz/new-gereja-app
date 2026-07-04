import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session_controller.dart';

class AdminJemaatFormPage extends StatefulWidget {
  const AdminJemaatFormPage({
    super.key,
    required this.session,
    this.jemaat,
    required this.onSuccess,
  });

  final SessionController session;
  final Map<String, dynamic>? jemaat;
  final VoidCallback onSuccess;

  @override
  State<AdminJemaatFormPage> createState() => _AdminJemaatFormPageState();
}

class _AdminJemaatFormPageState extends State<AdminJemaatFormPage> {
  late final ApiClient _api;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomorKkController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alamatController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  DateTime? _tanggalLahir;

  String _jenisKelamin = 'L';
  String _status = 'active';
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.jemaat != null;

  @override
  void initState() {
    super.initState();
    _api = widget.session.apiClient;

    if (_isEdit) {
      final jemaat = widget.jemaat!;
      _nameController.text = (jemaat['name'] as String?) ?? '';
      _usernameController.text = (jemaat['username'] as String?) ?? '';
      _emailController.text = (jemaat['email'] as String?) ?? '';
      _nomorKkController.text = (jemaat['nomor_kk'] as String?) ?? '';
      _phoneController.text = (jemaat['phone_number'] as String?) ?? '';
      _alamatController.text = (jemaat['alamat'] as String?) ?? '';
      _tempatLahirController.text = (jemaat['tempat_lahir'] as String?) ?? '';
      final tglLahirStr = jemaat['tanggal_lahir'] as String?;
      if (tglLahirStr != null) {
        _tanggalLahir = DateTime.tryParse(tglLahirStr);
      }
      _jenisKelamin = (jemaat['jenis_kelamin'] as String?) ?? 'L';
      _status = (jemaat['status'] as String?) ?? 'active';
      _usernameController.text = _usernameController.text; // Make readonly
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nomorKkController.dispose();
    _phoneController.dispose();
    _alamatController.dispose();
    _tempatLahirController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      if (_isEdit) {
        final userId = (widget.jemaat!['id'] as num?)?.toInt() ?? 0;
        await _api.updateJemaat(
          token,
          userId,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          jenisKelamin: _jenisKelamin,
          tempatLahir: _tempatLahirController.text.trim(),
          tanggalLahir: _tanggalLahir?.toIso8601String().split('T').first,
          alamat: _alamatController.text.trim(),
          status: _status,
          password: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jemaat berhasil diperbarui')),
          );
        }
      } else {
        await _api.createJemaat(
          token,
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nomorKk: _nomorKkController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          jenisKelamin: _jenisKelamin,
          tempatLahir: _tempatLahirController.text.trim(),
          tanggalLahir: _tanggalLahir?.toIso8601String().split('T').first,
          alamat: _alamatController.text.trim(),
          status: _status,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jemaat berhasil ditambahkan')),
          );
        }
      }

      widget.onSuccess();

      if (mounted) {
        Navigator.pop(context);
      }
    } on ApiError catch (error) {
      setState(() {
        String msg = error.message;
        if (error.errors != null && error.errors!.isNotEmpty) {
           final validationMsg = error.errors!.values.expand((e) => e).join('\n• ');
           msg = '$msg\n• $validationMsg';
        } else if (error.traceId != null) {
           msg += ' (trace: ${error.traceId})';
        }
        _error = msg;
      });
    } catch (_) {
      setState(() {
        _error = _isEdit
            ? 'Gagal memperbarui jemaat'
            : 'Gagal menambahkan jemaat';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Jemaat' : 'Tambah Jemaat Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap (wajib)',
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
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (wajib)',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nomorKkController,
                keyboardType: TextInputType.number,
                readOnly: _isEdit,
                decoration: InputDecoration(
                  labelText:
                      'Nomor KK (wajib)${_isEdit ? ' - tidak bisa diubah' : ''}',
                  prefixIcon: const Icon(Icons.credit_card_outlined),
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
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon (wajib)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Nomor telepon wajib diisi';
                  }
                  if (trimmed.length < 10) {
                    return 'Nomor telepon minimal 10 digit';
                  }
                  return null;
                },
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
                controller: _tempatLahirController,
                decoration: const InputDecoration(
                  labelText: 'Tempat Lahir (wajib)',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tempat Lahir wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _tanggalLahir ?? DateTime(now.year - 20),
                          firstDate: DateTime(now.year - 100),
                          lastDate: now,
                        );
                        if (picked != null) {
                          setState(() => _tanggalLahir = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        _tanggalLahir == null
                            ? 'Pilih Tanggal Lahir (wajib)'
                            : _tanggalLahir!.toIso8601String().split('T').first,
                      ),
                    ),
                  ),
                ],
              ),
              if (_tanggalLahir == null && _error != null && _error!.contains('Tanggal'))
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Tanggal Lahir wajib diisi',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _alamatController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat (wajib)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alamat wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Aktif')),
                  DropdownMenuItem(value: 'jemaat', child: Text('Jemaat')),
                  DropdownMenuItem(
                    value: 'simpatisan',
                    child: Text('Simpatisan'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value ?? 'active';
                  });
                },
              ),
              const Divider(height: 48),
              const Text(
                'Kredensial Login',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                readOnly: _isEdit,
                decoration: InputDecoration(
                  labelText:
                      'Username (wajib)${_isEdit ? ' - tidak bisa diubah' : ''}',
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
                validator: (value) {
                  if (!_isEdit && (value == null || value.trim().isEmpty)) {
                    return 'Username wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: _isEdit
                      ? 'Password Baru (kosongkan jika tidak mengubah)'
                      : 'Password (wajib)',
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (!_isEdit && (value == null || value.isEmpty)) {
                    return 'Password wajib diisi';
                  }
                  if (value != null && value.isNotEmpty && value.length < 8) {
                    return 'Password minimal 8 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Perbarui Jemaat' : 'Tambah Jemaat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
