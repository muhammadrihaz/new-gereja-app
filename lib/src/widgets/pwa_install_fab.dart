import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/pwa_install_controller.dart';

class PwaInstallFab extends StatefulWidget {
  const PwaInstallFab({super.key});

  @override
  State<PwaInstallFab> createState() => _PwaInstallFabState();
}

class _PwaInstallFabState extends State<PwaInstallFab> {
  final PwaInstallController _controller = PwaInstallController();
  bool _prompting = false;
  bool _showIOSGuide = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller.initialize();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_controller.shouldShowIOSGuide && !_showIOSGuide) {
      setState(() => _showIOSGuide = true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleInstallTap() async {
    if (_prompting) return;

    setState(() => _prompting = true);

    try {
      await _controller.promptInstall();
      if (mounted) setState(() => _dismissed = true);
    } finally {
      if (mounted) setState(() => _prompting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    if (kIsWeb) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.shouldShowIOSGuide && !_dismissed) {
            return _iosGuideBanner(context);
          }

          if (!_controller.canInstall || _dismissed) {
            return const SizedBox.shrink();
          }

          return _androidFab();
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _androidFab() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      Icon(Icons.get_app, size: 32, color: colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Install Aplikasi Gereja',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tambahkan ke layar utama untuk pengalaman seperti aplikasi native (APK).',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _dismissed = true),
                        child: const Text('Nanti saja'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _prompting ? null : _handleInstallTap,
                        icon: _prompting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.download_for_offline),
                        label: Text(_prompting ? 'Memproses...' : 'Install Sekarang'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iosGuideBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.apple, color: colorScheme.onPrimaryContainer, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Install Aplikasi di iOS',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _showIOSGuide = false;
                          _dismissed = true;
                        }),
                        child: Icon(Icons.close, color: colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap ikon Share (panah ke atas) di menu bawah browser Anda, lalu pilih "Add to Home Screen" agar bisa diakses seperti profil native.',
                    style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
