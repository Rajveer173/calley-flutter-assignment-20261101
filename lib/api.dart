import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiError implements Exception {
  final String message;
  const ApiError(this.message);
  @override
  String toString() => message;
}

class User {
  final String id, name, email;
  const User(this.id, this.name, this.email);
  factory User.fromJson(Map<String, dynamic> j) {
    final id = j['_id']?.toString() ?? '';
    if (id.isEmpty) {
      throw const ApiError('Login response did not contain a user ID.');
    }
    return User(
      id,
      j['username']?.toString() ?? '',
      j['email']?.toString() ?? '',
    );
  }
}

class CallList {
  final String id, name;
  const CallList(this.id, this.name);
  factory CallList.fromJson(Map<String, dynamic> j) {
    final id = j['_id']?.toString() ?? '';
    if (id.isEmpty) {
      throw const ApiError('A calling list has no ID.');
    }
    return CallList(id, j['name']?.toString() ?? 'Calling list');
  }
}

class CallRecord {
  final String name, status;
  const CallRecord(this.name, this.status);
}

class CallSummary {
  final int pending, called, scheduled;
  final List<CallRecord> calls;
  const CallSummary(this.pending, this.called, this.scheduled, this.calls);
  int get total => pending + called + scheduled;
  factory CallSummary.fromJson(Map<String, dynamic> j) {
    int number(String key) =>
        ((num.tryParse('${j[key] ?? 0}') ?? 0).toInt()).clamp(0, 100000000);
    final calls = (j['calls'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (c) => CallRecord(
            '${c['FirstName'] ?? ''} ${c['LastName'] ?? ''}'.trim(),
            '${c['status'] ?? 'pending'}',
          ),
        )
        .toList();
    return CallSummary(
      number('pending'),
      number('called'),
      number('rescheduled'),
      calls,
    );
  }
}

class CalleyApi {
  final http.Client client;
  final bool demo;
  final String base;
  String? _token;
  String _demoName = 'Alex';
  CalleyApi({
    http.Client? client,
    this.demo = false,
    this.base = 'https://mock-api.calleyacd.com/api',
  }) : client = client ?? http.Client();
  Future<dynamic> request(String path, {Map<String, dynamic>? body}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };
      final uri = Uri.parse('$base$path');
      final response =
          await (body == null
                  ? client.get(uri, headers: headers)
                  : client.post(uri, headers: headers, body: jsonEncode(body)))
              .timeout(const Duration(seconds: 20));
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw const ApiError(
          'The server returned an unreadable response. Please retry.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiError(
          data is Map
              ? '${data['message'] ?? data['error'] ?? 'Request failed (${response.statusCode})'}'
              : 'Request failed (${response.statusCode})',
        );
      }
      return data;
    } on TimeoutException {
      throw const ApiError(
        'The server took too long to respond. Please retry.',
      );
    } on http.ClientException {
      throw const ApiError(
        'Cannot connect to Calley. Check your internet connection.',
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    if (demo) {
      _demoName = name;
      return;
    }
    await request(
      '/auth/register',
      body: {'username': name, 'email': email, 'password': password},
    );
  }

  Future<User> login(String email, String password) async {
    if (demo) {
      return User('demo-user', _demoName, email);
    }
    final data = await request(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    if (data is! Map<String, dynamic> ||
        data['user'] is! Map<String, dynamic>) {
      throw const ApiError('Login response is missing the user profile.');
    }
    _token = data['token'] as String?;
    return User.fromJson(data['user']);
  }

  Future<void> sendOtp(String email) async {
    if (!demo) {
      await request('/auth/send-otp', body: {'email': email});
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    if (demo) {
      if (otp != '123456') {
        throw const ApiError('Incorrect demo code. Use 123456.');
      }
      return;
    }
    await request('/auth/verify-otp', body: {'email': email, 'otp': otp});
  }

  Future<List<CallList>> lists(String userId) async {
    if (demo) {
      return [const CallList('demo-list', 'Test List')];
    }
    final data = await request(
      '/list?userId=${Uri.encodeQueryComponent(userId)}',
    );
    final dynamic rows = data is List
        ? data
        : data is Map && data['_id'] != null
        ? [data]
        : data is Map
        ? data['lists'] ?? data['data'] ?? []
        : [];
    if (rows is! List) {
      throw const ApiError('Unexpected calling-list format.');
    }
    return rows
        .map((j) => CallList.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<CallSummary> details(String id) async {
    if (demo) {
      return const CallSummary(27, 23, 11, [
        CallRecord('Danielle Johnson', 'called'),
        CallRecord('Sherri Walter', 'pending'),
        CallRecord('Sandra Miller', 'rescheduled'),
      ]);
    }
    final data = await request('/list/${Uri.encodeComponent(id)}');
    if (data is! Map<String, dynamic>) {
      throw const ApiError('Unexpected call-summary format.');
    }
    return CallSummary.fromJson(data);
  }

  void logout() {
    _token = null;
  }
}
