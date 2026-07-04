import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'models.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.defaultTimeout = const Duration(seconds: 15),
    this.maxRetries = 2,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String baseUrl;
  final Duration defaultTimeout;
  final int maxRetries;
  final http.Client _client;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$root$path').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  /// Perform an HTTP request with timeout + exponential-backoff retry on
  /// transient failures (network errors, 502/503/504). GET/HEAD are retried
  /// automatically; mutating verbs are retried only on network errors.
  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    int? retries,
  }) async {
    final effectiveTimeout = timeout ?? defaultTimeout;
    final effectiveRetries = retries ?? maxRetries;
    final isIdempotent = method == 'GET' || method == 'HEAD';

    Object? lastError;
    for (var attempt = 0; attempt <= effectiveRetries; attempt++) {
      try {
        final request = http.Request(method, uri);
        if (headers != null) request.headers.addAll(headers);
        if (body != null) {
          request.body = body is String ? body : jsonEncode(body);
        }
        final streamed = await _client.send(request).timeout(effectiveTimeout);
        final response = await http.Response.fromStream(streamed);

        // Retry on transient 5xx for idempotent methods.
        if (isIdempotent &&
            attempt < effectiveRetries &&
            (response.statusCode == 502 ||
                response.statusCode == 503 ||
                response.statusCode == 504)) {
          await Future.delayed(_backoffDelay(attempt));
          continue;
        }
        return response;
      } catch (e) {
        lastError = e;
        if (attempt < effectiveRetries) {
          await Future.delayed(_backoffDelay(attempt));
          continue;
        }
        // Network error surfaces as ApiError with null statusCode.
        throw ApiError(
          message: 'Tidak dapat terhubung ke server. Cek koneksi internet Anda.',
          errorCode: 'NETWORK_ERROR',
          statusCode: null,
        );
      }
    }

    // Unreachable, but Dart requires an explicit return.
    throw ApiError(
      message: lastError?.toString() ?? 'Unknown network error',
      errorCode: 'NETWORK_ERROR',
    );
  }

  Duration _backoffDelay(int attempt) {
    // 250ms, 500ms, 1s (capped)
    final ms = (250 * (1 << attempt)).clamp(250, 2000);
    return Duration(milliseconds: ms);
  }

  Map<String, String> _headers({String? token, String? deviceToken}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (deviceToken != null && deviceToken.isNotEmpty) {
      headers['X-Device-Token'] = deviceToken;
    }
    return headers;
  }

  Future<dynamic> _decode(http.Response response) async {
    dynamic body = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = <String, dynamic>{};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final mapBody = body is Map<String, dynamic> ? body : <String, dynamic>{};

    // Parse Laravel-style validation errors: { errors: { field: [msg, ...] } }
    Map<String, List<String>>? fieldErrors;
    final rawErrors = mapBody['errors'];
    if (rawErrors is Map) {
      fieldErrors = <String, List<String>>{};
      rawErrors.forEach((key, value) {
        if (value is List) {
          fieldErrors![key.toString()] =
              value.map((e) => e.toString()).toList();
        } else if (value != null) {
          fieldErrors![key.toString()] = [value.toString()];
        }
      });
    }

    throw ApiError(
      message:
          (mapBody['message'] as String?) ??
          'Request gagal (${response.statusCode})',
      errorCode: mapBody['error_code'] as String?,
      traceId: mapBody['trace_id'] as String?,
      statusCode: response.statusCode,
      errors: fieldErrors,
    );
  }

  Future<AuthSession> login({
    required String username,
    required String password,
    required String fcmToken,
  }) async {
    final response = await http.post(
      _uri('/auth/login'),
      headers: _headers(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'fcm_token': fcmToken,
      }),
    );

    final payload = await _decode(response) as Map<String, dynamic>;
    final data =
        (payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    return AuthSession(
      token: (data['token'] as String?) ?? '',
      role: parseRole(data['role'] as String?),
      user: (data['user'] as Map<String, dynamic>? ?? <String, dynamic>{}),
    );
  }

  Future<AuthSession> signInWithGoogle({
    required String idToken,
    required String fcmToken,
  }) async {
    final response = await http.post(
      _uri('/auth/google-signin'),
      headers: _headers(),
      body: jsonEncode({
        'id_token': idToken,
        'fcm_token': fcmToken,
      }),
    );

    final payload = await _decode(response) as Map<String, dynamic>;
    final data =
        (payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    return AuthSession(
      token: (data['token'] as String?) ?? '',
      role: parseRole(data['role'] as String?),
      user: (data['user'] as Map<String, dynamic>? ?? <String, dynamic>{}),
    );
  }

  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
    required String nomorKk,
    required String phoneNumber,
    required String fcmToken,
    String? name,
    String? jenisKelamin,
    int? usia,
    String? alamat,
  }) async {
    final body = <String, dynamic>{
      'username': username,
      'password': password,
      'password_confirmation': password,
      'nomor_kk': nomorKk,
      'phone_number': phoneNumber,
      'fcm_token': fcmToken,
    };

    if (name != null && name.trim().isNotEmpty) {
      body['name'] = name.trim();
    }
    if (email.isNotEmpty) {
      body['email'] = email;
    }
    if (jenisKelamin != null && jenisKelamin.isNotEmpty) {
      body['jenis_kelamin'] = jenisKelamin;
    }
    if (usia != null) {
      body['usia'] = usia;
    }
    if (alamat != null && alamat.trim().isNotEmpty) {
      body['alamat'] = alamat.trim();
    }

    final response = await http.post(
      _uri('/auth/register'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    final payload = await _decode(response) as Map<String, dynamic>;
    final data =
        (payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    return AuthSession(
      token: (data['token'] as String?) ?? '',
      role: parseRole(data['role'] as String?),
      user: (data['user'] as Map<String, dynamic>? ?? <String, dynamic>{}),
    );
  }

  Future<Map<String, dynamic>> verifyKk({
    required String name,
    required String nomorKk,
  }) async {
    final response = await http.post(
      _uri('/auth/verify-kk'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'nomor_kk': nomorKk,
      }),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> me(String token) async {
    final response = await http.get(
      _uri('/auth/me'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateMe(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      _uri('/auth/me'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    required String token,
    required String filePath,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/auth/me/photo'));
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    request.files.add(await http.MultipartFile.fromPath('photo', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final payload = await _decode(response) as Map<String, dynamic>;

    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> uploadProfilePhotoBytes({
    required String token,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/auth/me/photo'));
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    request.files.add(
      http.MultipartFile.fromBytes('photo', bytes, filename: fileName),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final payload = await _decode(response) as Map<String, dynamic>;

    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> logout(String token) async {
    debugPrint('🔵 API.logout: Making POST request to /auth/logout');
    try {
      final response = await http.post(
        _uri('/auth/logout'),
        headers: _headers(token: token),
      );
      debugPrint('🔵 API.logout: Response status = ${response.statusCode}');
      debugPrint('🔵 API.logout: Response body = ${response.body}');
      await _decode(response);
      debugPrint('🟢 API.logout: Logout successful');
    } catch (e, stackTrace) {
      debugPrint('🔴 API.logout ERROR: $e');
      debugPrint('🔴 API.logout STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  Future<void> registerDevice({
    required String token,
    required String deviceToken,
    required String deviceType,
    required String deviceName,
  }) async {
    final response = await http.post(
      _uri('/devices/register'),
      headers: _headers(token: token),
      body: jsonEncode({
        'fcm_token': deviceToken,
        'device_type': deviceType,
        'device_name': deviceName,
      }),
    );
    await _decode(response);
  }

  Future<List<Map<String, dynamic>>> devices(
    String token,
    String currentDeviceToken,
  ) async {
    final response = await http.get(
      _uri('/devices'),
      headers: _headers(token: token, deviceToken: currentDeviceToken),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> health() async {
    final response = await http.get(_uri('/health'), headers: _headers());
    final payload = await _decode(response);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> churchProfile(String token) async {
    final response = await http.get(
      _uri('/church/profile'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> upsertChurchProfile(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      _uri('/church/profile'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> events(String token) async {
    final result = await eventsPaginated(token: token, perPage: 20);
    return result.items;
  }

  /// Paginated / filterable events endpoint.
  ///
  /// - [status] one of `upcoming`, `ongoing`, `past`, `archived` (admin-only), `all` (admin-only)
  /// - [search] free-text match against title/description
  /// - [category] event category code filter
  Future<PaginatedResult<Map<String, dynamic>>> eventsPaginated({
    required String token,
    int page = 1,
    int perPage = 15,
    String? status,
    String? search,
    String? category,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (sortBy != null && sortBy.isNotEmpty) query['sort_by'] = sortBy;
    if (sortOrder != null && sortOrder.isNotEmpty) query['sort_order'] = sortOrder;

    final response = await _send(
      'GET',
      _uri('/events', query),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'];
    final items = data is List
        ? data.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    final meta = payload['meta'];
    return PaginatedResult<Map<String, dynamic>>.fromMeta(
      items: items,
      meta: meta is Map<String, dynamic> ? meta : null,
    );
  }

  Future<Map<String, dynamic>> createEventCategory({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await http.post(
      _uri('/events/categories'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateEventCategory({
    required String token,
    required int id,
    required Map<String, dynamic> body,
  }) async {
    final response = await http.put(
      _uri('/events/categories/$id'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> deleteEventCategory({
    required String token,
    required int id,
  }) async {
    final response = await http.delete(
      _uri('/events/categories/$id'),
      headers: _headers(token: token),
    );
    await _decode(response);
  }

  Future<Map<String, dynamic>> createEvent({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await http.post(
      _uri('/events'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateEvent({
    required String token,
    required int id,
    required Map<String, dynamic> body,
  }) async {
    final response = await http.put(
      _uri('/events/$id'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> deleteEvent({
    required String token,
    required int id,
  }) async {
    final response = await http.delete(
      _uri('/events/$id'),
      headers: _headers(token: token),
    );
    await _decode(response);
  }

  Future<Uint8List> downloadEventDocumentation({
    required String token,
    required int eventId,
  }) async {
    final response = await http.get(
      _uri('/events/$eventId/documentation/download'),
      headers: _headers(token: token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }

    await _decode(response);
    return Uint8List(0);
  }

  Future<Uint8List> downloadServiceCertificate({
    required String token,
    required int applicationId,
  }) async {
    final response = await http.get(
      _uri('/services/applications/$applicationId/certificate/pdf'),
      headers: _headers(token: token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }

    await _decode(response);
    return Uint8List(0);
  }

  Future<List<Map<String, dynamic>>> serviceCategories(String token) async {
    final response = await http.get(
      _uri('/services/categories'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response);

    final rawList = (payload is Map<String, dynamic>)
        ? payload['data']
        : payload;
    if (rawList is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawList.map((item) {
      if (item is Map<String, dynamic>) {
        return {
          'code': item['code']?.toString() ?? '',
          'name': item['name']?.toString() ?? item['code']?.toString() ?? '',
        };
      }

      final value = item.toString();
      return {'code': value, 'name': value};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> eventCategories(String token) async {
    final response = await http.get(
      _uri('/events/categories'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response);

    final rawList = (payload is Map<String, dynamic>)
        ? payload['data']
        : payload;
    if (rawList is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawList.map((item) {
      if (item is Map<String, dynamic>) {
        return {
          'code': item['code']?.toString() ?? '',
          'name': item['name']?.toString() ?? item['code']?.toString() ?? '',
        };
      }

      final value = item.toString();
      return {'code': value, 'name': value};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> serviceForms(String token) async {
    final response = await http.get(
      _uri('/services/forms'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> serviceApplications(String token) async {
    final result = await serviceApplicationsPaginated(token: token, perPage: 50);
    return result.items;
  }

  Future<PaginatedResult<Map<String, dynamic>>> serviceApplicationsPaginated({
    required String token,
    int page = 1,
    int perPage = 20,
    String? status,
    String? category,
    String? search,
  }) async {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await http.get(
      _uri('/services/applications', query),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'];
    final items = data is List
        ? data.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    final meta = payload['meta'];
    return PaginatedResult<Map<String, dynamic>>.fromMeta(
      items: items,
      meta: meta is Map<String, dynamic> ? meta : null,
    );
  }

  Future<Map<String, dynamic>> userFamilies(
    String token, {
    int perPage = 20,
    int page = 1,
    String? search,
  }) async {
    final query = <String, dynamic>{'per_page': perPage, 'page': page};
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await http.get(
      _uri('/users/families', query),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;

    final data = payload['data'];
    final meta = payload['meta'];
    return {
      'data': data is List
          ? data.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[],
      'meta': meta is Map<String, dynamic> ? meta : <String, dynamic>{},
    };
  }

  Future<Map<String, dynamic>> upsertServiceTemplate({
    required String token,
    String? categoryPath,
    required Map<String, dynamic> body,
  }) async {
    final response = categoryPath == null
        ? await http.post(
            _uri('/services/forms'),
            headers: _headers(token: token),
            body: jsonEncode(body),
          )
        : await http.put(
            _uri('/services/forms/$categoryPath'),
            headers: _headers(token: token),
            body: jsonEncode(body),
          );

    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> deleteServiceTemplate({
    required String token,
    required String category,
  }) async {
    final response = await http.delete(
      _uri('/services/forms/$category'),
      headers: _headers(token: token),
    );
    await _decode(response);
  }

  Future<Map<String, dynamic>> updateServiceStatus({
    required String token,
    required int applicationId,
    required String status,
    String? adminNote,
  }) async {
    final response = await http.patch(
      _uri('/services/applications/$applicationId/status'),
      headers: _headers(token: token),
      body: jsonEncode({'status': status, 'admin_note': adminNote}),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateServiceApplication({
    required String token,
    required int applicationId,
    required String category,
    required Map<String, dynamic> formData,
    required List<String> attachments,
  }) async {
    final response = await http.patch(
      _uri('/services/applications/$applicationId'),
      headers: _headers(token: token),
      body: jsonEncode({
        'category': category,
        'form_data': formData,
        'attachments': attachments,
      }),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> applyService({
    required String token,
    required String category,
    required Map<String, dynamic> formData,
    required List<String> attachments,
    int? targetUserId,
  }) async {
    final body = <String, dynamic>{
      'category': category,
      'form_data': formData,
      'attachments': attachments,
    };
    if (targetUserId != null) {
      body['target_user_id'] = targetUserId;
    }

    final response = await http.post(
      _uri('/services/apply'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    await _decode(response);
  }

  Future<Map<String, dynamic>> broadcastNotification({
    required String token,
    required String title,
    required String message,
    required String targetType,
    Map<String, dynamic>? targetFilters,
  }) async {
    final response = await http.post(
      _uri('/notifications/broadcast'),
      headers: _headers(token: token),
      body: jsonEncode({
        'title': title,
        'message': message,
        'target_type': targetType,
        if (targetFilters?.isNotEmpty ?? false) 'target_filters': targetFilters,
      }),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  // New methods for jemaat and admin management

  Future<List<Map<String, dynamic>>> userFamilyMembers(
    String token, {
    int perPage = 100,
  }) async {
    final response = await http.get(
      _uri('/users/family-members', {'per_page': perPage}),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>?;
    final members = data?['members'];
    if (members is List) {
      return members.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> users(
    String token, {
    String? role,
    int perPage = 30,
    int page = 1,
    String? search,
  }) async {
    final query = <String, dynamic>{'per_page': perPage, 'page': page};
    if (role != null) {
      query['role'] = role;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await http.get(
      _uri('/users', query),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data =
        (payload['data'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        <Map<String, dynamic>>[];
    return data;
  }

  Future<List<Map<String, dynamic>>> kkRegistrations(
    String token, {
    int perPage = 30,
    int page = 1,
    String? search,
  }) async {
    final query = <String, dynamic>{'per_page': perPage, 'page': page};
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await http.get(
      _uri('/kk-registrations', query),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data =
        (payload['data'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        <Map<String, dynamic>>[];
    return data;
  }

  Future<Map<String, dynamic>> createKkRegistration(
    String token, {
    required String nomorKk,
    required String namaKepalaKeluarga,
    String? alamat,
    String? phoneNumber,
  }) async {
    final response = await http.post(
      _uri('/kk-registrations'),
      headers: _headers(token: token),
      body: jsonEncode({
        'nomor_kk': nomorKk,
        'nama_kepala_keluarga': namaKepalaKeluarga,
        if (alamat != null && alamat.isNotEmpty) 'alamat': alamat,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      }),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateKkRegistration(
    String token,
    String kkId, {
    required String nomorKk,
    required String namaKepalaKeluarga,
    String? alamat,
    String? phoneNumber,
  }) async {
    final response = await http.put(
      _uri('/kk-registrations/$kkId'),
      headers: _headers(token: token),
      body: jsonEncode({
        'nomor_kk': nomorKk,
        'nama_kepala_keluarga': namaKepalaKeluarga,
        if (alamat != null && alamat.isNotEmpty) 'alamat': alamat,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      }),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> deleteKkRegistration(String token, String kkId) async {
    final response = await http.delete(
      _uri('/kk-registrations/$kkId'),
      headers: _headers(token: token),
    );
    await _decode(response);
  }

  Future<Map<String, dynamic>> createJemaat(
    String token, {
    required String name,
    required String username,
    required String email,
    required String password,
    required String nomorKk,
    required String phoneNumber,
    String? jenisKelamin,
    String? tempatLahir,
    String? tanggalLahir,
    int? usia,
    String? alamat,
    String? status,
  }) async {
    final response = await http.post(
      _uri('/jemaats'),
      headers: _headers(token: token),
      body: jsonEncode({
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'nomor_kk': nomorKk,
        'phone_number': phoneNumber,
        if (jenisKelamin != null && jenisKelamin.isNotEmpty)
          'jenis_kelamin': jenisKelamin,
        if (tempatLahir != null && tempatLahir.isNotEmpty)
          'tempat_lahir': tempatLahir,
        if (tanggalLahir != null && tanggalLahir.isNotEmpty)
          'tanggal_lahir': tanggalLahir,
        if (usia != null) ...{'usia': usia},
        if (alamat != null && alamat.isNotEmpty) 'alamat': alamat,
        if (status != null && status.isNotEmpty) 'status': status,
      }),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateJemaat(
    String token,
    int userId, {
    String? name,
    String? email,
    String? password,
    String? jenisKelamin,
    String? tempatLahir,
    String? tanggalLahir,
    int? usia,
    String? alamat,
    String? phoneNumber,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (password != null) {
      body['password'] = password;
      body['password_confirmation'] = password;
    }
    if (jenisKelamin != null) body['jenis_kelamin'] = jenisKelamin;
    if (tempatLahir != null) body['tempat_lahir'] = tempatLahir;
    if (tanggalLahir != null) body['tanggal_lahir'] = tanggalLahir;
    if (usia != null) body['usia'] = usia;
    if (alamat != null) body['alamat'] = alamat;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (status != null) body['status'] = status;

    final response = await http.put(
      _uri('/jemaats/$userId'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> deleteJemaat(String token, int userId) async {
    final response = await http.delete(
      _uri('/jemaats/$userId'),
      headers: _headers(token: token),
    );
    await _decode(response);
  }

  Future<List<Map<String, dynamic>>> news(
    String token, {
    int perPage = 15,
    bool publishedOnly = true,
  }) async {
    final result = await newsPaginated(
      token: token,
      perPage: perPage,
      publishedOnly: publishedOnly,
    );
    return result.items;
  }

  /// Paginated news list endpoint. Supports search + published_only filter.
  Future<PaginatedResult<Map<String, dynamic>>> newsPaginated({
    required String token,
    int page = 1,
    int perPage = 15,
    String? search,
    bool publishedOnly = true,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'published_only': publishedOnly ? '1' : '0',
    };
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _send(
      'GET',
      _uri('/news', query),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final rawData = payload['data'];
    // Support both flat-list responses and nested Laravel paginator objects:
    // Flat:   { "data": [ {...}, ... ], "meta": {...} }
    // Nested: { "data": { "current_page": 1, "data": [ {...}, ... ], ... } }
    final List<dynamic> dataList;
    final dynamic rawMeta;
    if (rawData is List) {
      dataList = rawData;
      rawMeta = payload['meta'];
    } else if (rawData is Map && rawData['data'] is List) {
      dataList = rawData['data'] as List;
      // meta may be separately in payload['meta'] or built from rawData fields
      rawMeta = payload['meta'] ?? <String, dynamic>{
        'current_page': rawData['current_page'],
        'last_page': rawData['last_page'],
        'per_page': rawData['per_page'],
        'total': rawData['total'],
      };
    } else {
      dataList = const <dynamic>[];
      rawMeta = payload['meta'];
    }
    final items = dataList.whereType<Map<String, dynamic>>().toList();
    final meta = rawMeta;
    return PaginatedResult<Map<String, dynamic>>.fromMeta(
      items: items,
      meta: meta is Map<String, dynamic> ? meta : null,
    );
  }

  /// Fetch a single news article with full content, attachments and creator info.
  Future<Map<String, dynamic>> newsDetail({
    required String token,
    required int id,
  }) async {
    final response = await _send(
      'GET',
      _uri('/news/$id'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  // ------------------------------------------------------------------
  // Notification inbox / unread badge
  // ------------------------------------------------------------------

  /// Fetch the authenticated user's personal notification inbox (paginated).
  Future<PaginatedResult<Map<String, dynamic>>> notificationInbox({
    required String token,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _send(
      'GET',
      _uri('/notifications/inbox', {'page': page, 'per_page': perPage}),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'];
    final items = data is List
        ? data.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    final meta = payload['meta'];
    return PaginatedResult<Map<String, dynamic>>.fromMeta(
      items: items,
      meta: meta is Map<String, dynamic> ? meta : null,
    );
  }

  /// Returns the number of unread in-app / push notifications for the user.
  Future<int> notificationUnreadCount({required String token}) async {
    final response = await _send(
      'GET',
      _uri('/notifications/unread-count'),
      headers: _headers(token: token),
      timeout: const Duration(seconds: 8),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      return (data['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<void> markNotificationRead({
    required String token,
    required int logId,
  }) async {
    final response = await _send(
      'PATCH',
      _uri('/notifications/$logId/read'),
      headers: _headers(token: token),
    );
    await _decode(response);
  }

  Future<int> markAllNotificationsRead({required String token}) async {
    final response = await _send(
      'PATCH',
      _uri('/notifications/read-all'),
      headers: _headers(token: token),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      return (data['updated'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<Map<String, dynamic>> createNews({
    required String token,
    required Map<String, dynamic> body,
    String? coverFilePath,
    Uint8List? coverFileBytes,
    String? coverFileName,
  }) async {
    final hasCoverFile = (coverFilePath != null && coverFilePath.isNotEmpty) ||
        (coverFileBytes != null && coverFileName != null);
    if (hasCoverFile) {
      final request = http.MultipartRequest('POST', _uri('/news'));
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      for (final entry in body.entries) {
        if (entry.value != null && entry.value is! Map && entry.value is! List) {
          request.fields[entry.key] = entry.value.toString();
        }
      }
      if (coverFileBytes != null && coverFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes('cover_file', coverFileBytes, filename: coverFileName),
        );
      } else if (coverFilePath != null) {
        request.files.add(await http.MultipartFile.fromPath('cover_file', coverFilePath));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final payload = await _decode(response) as Map<String, dynamic>;
      return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    }

    final response = await http.post(
      _uri('/news'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateNews({
    required String token,
    required int id,
    required Map<String, dynamic> body,
    String? coverFilePath,
    Uint8List? coverFileBytes,
    String? coverFileName,
  }) async {
    final hasCoverFile = (coverFilePath != null && coverFilePath.isNotEmpty) ||
        (coverFileBytes != null && coverFileName != null);
    if (hasCoverFile) {
      final request = http.MultipartRequest('POST', _uri('/news/$id'));
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.fields['_method'] = 'PUT'; // Laravel form spoofing for files
      for (final entry in body.entries) {
        if (entry.value != null && entry.value is! Map && entry.value is! List) {
          request.fields[entry.key] = entry.value.toString();
        }
      }
      if (coverFileBytes != null && coverFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes('cover_file', coverFileBytes, filename: coverFileName),
        );
      } else if (coverFilePath != null) {
        request.files.add(await http.MultipartFile.fromPath('cover_file', coverFilePath));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final payload = await _decode(response) as Map<String, dynamic>;
      return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    }

    final response = await http.put(
      _uri('/news/$id'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    final payload = await _decode(response) as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<void> deleteNews({
    required String token,
    required int id,
  }) async {
    final response = await http.delete(
      _uri('/news/$id'),
      headers: _headers(token: token),
    );
    await _decode(response);
  }

  Future<List<Map<String, dynamic>>> uploadNewsAttachments({
    required String token,
    required int newsId,
    required List<Map<String, dynamic>> files,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/news/$newsId/attachments'),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    for (final file in files) {
      if (file['path'] != null) {
        request.files.add(
          await http.MultipartFile.fromPath('files[]', file['path'] as String),
        );
      } else if (file['bytes'] != null && file['name'] != null) {
        final fileName = file['name'] as String;
        final mimeType = _guessMimeType(fileName);
        request.files.add(
          http.MultipartFile.fromBytes(
            'files[]',
            file['bytes'] as Uint8List,
            filename: fileName,
            contentType: mimeType,
          ),
        );
      }
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final payload = await _decode(response) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }


  Future<Uint8List> downloadNewsAttachments({
    required String token,
    required int newsId,
  }) async {
    final response = await http.get(
      _uri('/news/$newsId/attachments/download'),
      headers: _headers(token: token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }

    await _decode(response);
    return Uint8List(0);
  }

  Future<Uint8List> exportServiceApplicationsCsv(
    String token, {
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (fromDate != null && fromDate.isNotEmpty) query['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) query['to_date'] = toDate;

    final response = await http.get(
      _uri('/services/applications/export/csv', query),
      headers: _headers(token: token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }

    throw ApiError(
      message: 'Gagal mengunduh file CSV',
      statusCode: response.statusCode,
    );
  }

  /// Guess MIME type from file extension for multipart uploads.
  static MediaType _guessMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const map = <String, String>{
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'zip': 'application/zip',
    };
    final mime = map[ext] ?? 'application/octet-stream';
    final parts = mime.split('/');
    return MediaType(parts[0], parts.length > 1 ? parts[1] : 'octet-stream');
  }
}
