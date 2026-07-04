import 'package:flutter/material.dart';

import '../core/models.dart';

/// A friendly error state widget that renders a title, description and a
/// primary "coba lagi" retry action. Handles both `ApiError` (with codes)
/// and generic exceptions gracefully.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
    this.padding = const EdgeInsets.all(24),
  });

  final Object? error;
  final VoidCallback? onRetry;
  final bool compact;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _title();
    final message = _message();
    final icon = _icon();
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 56 : 72,
                height: compact ? 56 : 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.errorContainer.withValues(alpha: 0.5),
                ),
                child: Icon(icon, size: compact ? 28 : 36, color: scheme.error),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _title() {
    final err = error;
    if (err is ApiError) {
      if (err.isNetworkError) return 'Tidak dapat terhubung';
      if (err.isAuthError) return 'Sesi berakhir';
      if (err.isForbidden) return 'Akses ditolak';
      if (err.isNotFound) return 'Data tidak ditemukan';
      if (err.isServerError) return 'Terjadi kendala di server';
      if (err.isValidationError) return 'Validasi gagal';
    }
    return 'Terjadi kesalahan';
  }

  String _message() {
    final err = error;
    if (err is ApiError) {
      if (err.isNetworkError) {
        return 'Periksa koneksi internet Anda lalu coba lagi.';
      }
      return err.message;
    }
    if (err == null) return 'Silakan coba beberapa saat lagi.';
    return err.toString();
  }

  IconData _icon() {
    final err = error;
    if (err is ApiError) {
      if (err.isNetworkError) return Icons.wifi_off_rounded;
      if (err.isAuthError) return Icons.lock_outline_rounded;
      if (err.isForbidden) return Icons.block_rounded;
      if (err.isNotFound) return Icons.search_off_rounded;
      if (err.isServerError) return Icons.cloud_off_rounded;
    }
    return Icons.error_outline_rounded;
  }
}
