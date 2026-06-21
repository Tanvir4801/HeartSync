import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AiRepository {
  static const String _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://heartsync-console.replit.app/api');

  Future<String?> _getToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String> generate(String coupleId, String type, String tone, String? context) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/ai/generate'),
      headers: await _headers(),
      body: jsonEncode({'type': type, 'tone': tone, 'context': context, 'coupleId': coupleId}),
    );
    if (res.statusCode != 200) throw Exception('Generation failed: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }

  Future<String> generateLoveLetter({required String occasion, required String tone, String? coupleId}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/ai/love-letter'),
      headers: await _headers(),
      body: jsonEncode({'occasion': occasion, 'tone': tone, 'coupleId': coupleId}),
    );
    if (res.statusCode != 200) throw Exception('Failed to generate love letter');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }

  Future<List<String>> generateCaptions({String? description, String? coupleId}) async {
    return await suggestCaptions(coupleId ?? '', description ?? '');
  }

  Future<List<String>> suggestCaptions(String coupleId, String description) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/ai/caption'),
      headers: await _headers(),
      body: jsonEncode({'description': description, 'coupleId': coupleId}),
    );
    if (res.statusCode != 200) throw Exception('Failed to generate captions');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return List<String>.from(data['captions'] ?? []);
  }

  Future<String> generateMonthlyRecap({required String coupleId, String? month, Map<String, int>? stats}) async {
    return await monthlyRecap(coupleId, DateTime.now().month, DateTime.now().year);
  }

  Future<String> monthlyRecap(String coupleId, int month, int year) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/ai/monthly-recap'),
      headers: await _headers(),
      body: jsonEncode({'coupleId': coupleId, 'month': month, 'year': year}),
    );
    if (res.statusCode != 200) throw Exception('Failed to generate recap');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['recap'] as String? ?? '';
  }
}
