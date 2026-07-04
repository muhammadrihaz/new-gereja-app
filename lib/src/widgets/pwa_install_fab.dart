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
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(
            right: 16,
            bottom: kBottomNavigationBarHeight + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'pwa-install-fab-close',
                onPressed: () => setState(() => _dismissed = true),
                child: const Icon(Icons.close, size: 20),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'pwa-install-fab',
                onPressed: _prompting ? null : _handleInstallTap,
                icon: _prompting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_for_offline_outlined),
                label: Text(_prompting ? 'Memproses...' : 'Install App'),
              ),
            ],
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
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.ios_share, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Install app: tap Share → Add to Home Screen',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _showIOSGuide = false;
                      _dismissed = true;
                    }),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Colors.white70, size: 20),
                    ),
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
