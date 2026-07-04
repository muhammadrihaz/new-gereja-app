import 'package:flutter/material.dart';

// import '../core/api_client.dart';
import '../core/environment.dart';
import '../core/models.dart';
import '../core/session_controller.dart';
import '../widgets/church_logo.dart';
import '../widgets/google_signin_button.dart';

// import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.session});

  final SessionController session;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const bool _showGoogleSignIn = true;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginUsernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _verifNameController = TextEditingController();
  final _verifKkController = TextEditingController();

  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmController = TextEditingController();

  int _authTab = 0;
  int _regStep = 1;
  bool _verifyingKk = false;
  String? _verifError;
  String? _error;

  bool _showLoginPassword = false;
  bool _showRegPassword = false;
  bool _showRegConfirm = false;

  String _churchAddress = 'Jl. Sunset Road No. 767, Denpasar, Bali';
  String _churchPhone = '(0361) 123456';

  @override
  void initState() {
    super.initState();
    _loadChurchProfile();
  }

  Future<void> _loadChurchProfile() async {
    try {
      final profile = await widget.session.apiClient.churchProfile('');
      if (mounted) {
        setState(() {
          _churchAddress = (profile['address'] as String?) ?? '';
          _churchPhone = (profile['phone'] as String?) ?? '';
        });
      }
    } catch (_) {
      // Fallback ke default jika gagal fetch
      if (mounted) {
        setState(() {
          _churchAddress = 'Jl. Sunset Road No. 767, Denpasar, Bali';
          _churchPhone = '(0361) 123456';
        });
      }
    }
  }

  void _setJemaatCredentials() {
    _loginUsernameController.text = Environment.localJemaatEmail;
    _passwordController.text = Environment.localJemaatPassword;
  }

  void _setAdminCredentials() {
    _loginUsernameController.text = Environment.localAdminEmail;
    _passwordController.text = Environment.localAdminPassword;
  }

  Future<void> _handleGoogleSignIn() async {
    // Fitur dinonaktifkan sementara karena secret key OAuth belum tersedia.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign In - Coming Soon! (Saat ini dinonaktifkan)'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _loginUsernameController.dispose();
    _passwordController.dispose();
    _verifNameController.dispose();
    _verifKkController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _regConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _error = null;
    });

    try {
      await widget.session.signIn(
        username: _loginUsernameController.text.trim(),
        password: _passwordController.text,
      );
    } on ApiError catch (error) {
      setState(() {
        _error =
            '${error.message}${error.traceId != null ? ' (trace: ${error.traceId})' : ''}';
      });
    } catch (_) {
      setState(() {
        _error = 'Login gagal. Silakan coba lagi.';
      });
    }
  }

  Future<void> _verifyKk() async {
    final formState = _registerFormKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() {
      _verifyingKk = true;
      _verifError = null;
    });

    try {
      final result = await widget.session.apiClient.verifyKk(
        name: _verifNameController.text.trim(),
        nomorKk: _verifKkController.text.trim(),
      );

      if (result['verified'] == true) {
        setState(() {
          _verifyingKk = false;
          _regStep = 2;
          _verifError = null;
        });
      } else {
        setState(() {
          _verifyingKk = false;
          _verifError = 'Data tidak ditemukan. Periksa kembali nama dan nomor KK Anda.';
        });
      }
    } on ApiError catch (e) {
      setState(() {
        _verifyingKk = false;
        _verifError = e.message;
      });
    } catch (e) {
      setState(() {
        _verifyingKk = false;
        _verifError = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    }
  }

  Future<void> _submitRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _error = null);

    try {
      await widget.session.signUp(
        username: _regUsernameController.text.trim(),
        password: _regPasswordController.text,
        nomorKk: _verifKkController.text.trim(),
      );
    } on ApiError catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    }
  }

  Widget _buildVerifyStep() {
    return Column(
      key: const ValueKey('verify-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Verifikasi Data Jemaat',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Masukkan nama dan nomor KK untuk verifikasi',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _verifNameController,
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Nama wajib diisi';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _verifKkController,
          decoration: const InputDecoration(
            labelText: 'Nomor KK',
            prefixIcon: Icon(Icons.credit_card_outlined),
            hintText: '16 digit',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) return 'Nomor KK wajib diisi';
            if (trimmed.length < 16) return 'Nomor KK minimal 16 digit';
            return null;
          },
        ),
        if (_verifError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _verifError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _verifyingKk ? null : _verifyKk,
          icon: _verifyingKk
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(_verifyingKk ? 'Memverifikasi...' : 'Verifikasi Data'),
        ),
      ],
    );
  }

  Widget _buildRegisterStep() {
    return Column(
      key: const ValueKey('register-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Data ditemukan! Buat akun Anda.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _regUsernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.alternate_email),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Username wajib diisi';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _regPasswordController,
          obscureText: !_showRegPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _showRegPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => _showRegPassword = !_showRegPassword);
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Password wajib diisi';
            if (value.length < 8) return 'Password minimal 8 karakter';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _regConfirmController,
          obscureText: !_showRegConfirm,
          decoration: InputDecoration(
            labelText: 'Konfirmasi Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _showRegConfirm ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => _showRegConfirm = !_showRegConfirm);
              },
            ),
          ),
          validator: (value) {
            if (value != _regPasswordController.text) return 'Password tidak cocok';
            return null;
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: widget.session.busy ? null : _submitRegister,
          icon: widget.session.busy
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add_alt_1),
          label: Text(widget.session.busy ? 'Mendaftar...' : 'Daftar Akun'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _regStep = 1;
              _verifError = null;
            });
          },
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Kembali'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerLow,
                    theme.colorScheme.surfaceContainer,
                  ]
                : [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerLow,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xEE1E1E1E)
                        : const Color(0xF7FFFFFF),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.28 : 0.08,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ChurchLogo(
                          logo: null,
                          isDark: isDark,
                          height: 92,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'GPI Yehuda',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistem Informasi Jemaat & Pelayanan',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment<int>(
                            value: 0,
                            icon: Icon(Icons.login),
                            label: Text('Login'),
                          ),
                          ButtonSegment<int>(
                            value: 1,
                            icon: Icon(Icons.person_add_alt_1),
                            label: Text('Daftar Akun'),
                          ),
                        ],
                        selected: {_authTab},
                        onSelectionChanged: (value) {
                          setState(() {
                            _authTab = value.first;
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _authTab == 0
                            ? Form(
                                key: _loginFormKey,
                                child: Column(
                                  key: const ValueKey('login-form'),
                                  children: [
                                    TextFormField(
                                      controller: _loginUsernameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Username atau Email',
                                        prefixIcon: Icon(Icons.alternate_email),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Username atau Email wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_showLoginPassword,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _showLoginPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _showLoginPassword = !_showLoginPassword;
                                            });
                                          },
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : Form(
                                key: _registerFormKey,
                                child: _authTab == 1
                                    ? (_regStep == 1
                                        ? _buildVerifyStep()
                                        : _buildRegisterStep())
                                    : const SizedBox.shrink(),
                              ),
                      ),
                      if (_authTab == 0) ...[
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: widget.session.busy ? null : _submit,
                          icon: widget.session.busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: const Text('Masuk ke Dashboard'),
                        ),
                      ],
                      const SizedBox(height: 22),
                      if (Environment.isLocal)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 32,
                                child: OutlinedButton.icon(
                                  onPressed: _setAdminCredentials,
                                  icon: const Icon(
                                    Icons.admin_panel_settings,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Admin',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 32,
                                child: OutlinedButton.icon(
                                  onPressed: _setJemaatCredentials,
                                  icon: const Icon(Icons.person, size: 16),
                                  label: const Text(
                                    'Jemaat',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Divider(color: theme.colorScheme.outlineVariant),
                      if (_showGoogleSignIn) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Atau lanjutkan dengan',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: 12),
                        GoogleSignInButton(
                          onPressed: _handleGoogleSignIn,
                          isDarkMode: isDark,
                          text: 'Lanjutkan dengan Google',
                        ),
                        const SizedBox(height: 22),
                        Divider(color: theme.colorScheme.outlineVariant),
                      ],
                      const SizedBox(height: 10),
                      if (_churchAddress.isNotEmpty)
                        Text(
                          _churchAddress,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      if (_churchPhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Telp: $_churchPhone',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
