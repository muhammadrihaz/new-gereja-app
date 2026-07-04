enum UserRole { admin, jemaat }

UserRole parseRole(String? value) {
  if (value == 'admin') {
    return UserRole.admin;
  }
  return UserRole.jemaat;
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.role,
    required this.user,
  });

  final String token;
  final UserRole role;
  final Map<String, dynamic> user;
}

class ApiError implements Exception {
  const ApiError({
    required this.message,
    this.errorCode,
    this.traceId,
    this.statusCode,
    this.errors,
  });

  final String message;
  final String? errorCode;
  final String? traceId;
  final int? statusCode;

  /// Field-level validation errors returned by the API, if any.
  /// Shape: { field_name: [error_message_1, error_message_2] }
  final Map<String, List<String>>? errors;

  bool get isNetworkError => statusCode == null;
  bool get isValidationError => statusCode == 422 || errorCode == 'VALIDATION_ERROR';
  bool get isAuthError => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => message;
}

/// A paginated result envelope for list endpoints that support pagination meta.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.hasMore,
  });

  factory PaginatedResult.fromMeta({
    required List<T> items,
    Map<String, dynamic>? meta,
  }) {
    final m = meta ?? const <String, dynamic>{};
    return PaginatedResult<T>(
      items: items,
      currentPage: (m['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (m['last_page'] as num?)?.toInt() ?? 1,
      perPage: (m['per_page'] as num?)?.toInt() ?? items.length,
      total: (m['total'] as num?)?.toInt() ?? items.length,
      hasMore: (m['has_more'] as bool?) ??
          (((m['current_page'] as num?)?.toInt() ?? 1) <
              ((m['last_page'] as num?)?.toInt() ?? 1)),
    );
  }

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  PaginatedResult<T> copyWithItems(List<T> newItems) => PaginatedResult<T>(
        items: newItems,
        currentPage: currentPage,
        lastPage: lastPage,
        perPage: perPage,
        total: total,
        hasMore: hasMore,
      );
}
