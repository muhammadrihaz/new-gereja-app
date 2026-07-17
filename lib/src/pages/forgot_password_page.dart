import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/session_controller.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.session});

  final SessionController session;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _kkController = TextEditingController();
  final _dobController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _kkController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.session.apiClient.verifyForgotPassword(
        phoneNumber: _phoneController.text.trim(),
        familyCardNumber: _kkController.text.trim(),
        birthDate: _dobController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true && result['reset_token'] != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(
              session: widget.session,
              resetToken: result['reset_token'],
            ),
          ),
        );
      } else {
        setState(() {
          _error = result['message'] ?? 'Data tidak ditemukan.';
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Terjadi kesalahan. Silakan coba lagi.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lupa Password'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xEE1E1E1E) : const Color(0xF7FFFFFF),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Verifikasi Data Jemaat',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan Nomor HP, Nomor KK, dan Tanggal Lahir untuk memverifikasi akun Anda.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor HP',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Nomor HP wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _kkController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor KK',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Nomor KK wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Lahir (YYYY-MM-DD)',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          _dobController.text =
                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Tanggal Lahir wajib diisi';
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_user_outlined),
                      label: Text(_loading ? 'Memverifikasi...' : 'Verifikasi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
