import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';

// ── Auth header ───────────────────────────────────────────────────────────────

Future<Map<String, String>> _authHeaders() async {
  try {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
  } catch (_) {}
  return {'Content-Type': 'application/json'};
}

// ── Public helpers ────────────────────────────────────────────────────────────

/// POST JSON to the backend; attaches Firebase ID token automatically.
Future<Map<String, dynamic>> backendPost(String path, Map<String, dynamic> body) async {
  final headers = await _authHeaders();
  try {
    final res = await http.post(
      Uri.parse('$kBackendUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
    return jsonDecode(res.body) as Map<String, dynamic>;
  } catch (e) {
    return {'error': e.toString()};
  }
}

/// GET from the backend; attaches Firebase ID token automatically.
Future<Map<String, dynamic>> backendGet(String path) async {
  final headers = await _authHeaders();
  try {
    final res = await http.get(
      Uri.parse('$kBackendUrl$path'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));
    return jsonDecode(res.body) as Map<String, dynamic>;
  } catch (e) {
    return {'error': e.toString()};
  }
}

/// PUT JSON to the backend.
Future<Map<String, dynamic>> backendPut(String path, Map<String, dynamic> body) async {
  final headers = await _authHeaders();
  try {
    final res = await http.put(
      Uri.parse('$kBackendUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
    return jsonDecode(res.body) as Map<String, dynamic>;
  } catch (e) {
    return {'error': e.toString()};
  }
}

/// DELETE with optional query params.
Future<Map<String, dynamic>> backendDelete(String path) async {
  final headers = await _authHeaders();
  try {
    final res = await http.delete(
      Uri.parse('$kBackendUrl$path'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));
    return jsonDecode(res.body) as Map<String, dynamic>;
  } catch (e) {
    return {'error': e.toString()};
  }
}
