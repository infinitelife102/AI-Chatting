import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Verifies Supabase client is initialized (session optional).
Future<bool> verifySupabase() async {
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    return false;
  }
  try {
    final client = Supabase.instance.client;
    client.auth.currentSession;
    return true;
  } catch (_) {
    return false;
  }
}

/// Verifies Groq API with a short completion request.
Future<bool> verifyGroq() async {
  final rawKey = dotenv.env['GROQ_API_KEY'];
  final apiKey = rawKey?.trim();
  if (apiKey == null || apiKey.isEmpty) {
    debugPrint('verifyGroq: GROQ_API_KEY is missing or empty in .env');
    return false;
  }
  try {
    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {'role': 'user', 'content': 'Say OK only.'}
      ],
    });
    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    if (response.statusCode != 200) {
      debugPrint('verifyGroq: ${response.statusCode} ${response.body}');
      return false;
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;
    final content = choices?.isNotEmpty == true
        ? (choices!.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?
        : null;
    final text = content?['content'] as String?;
    return text != null && text.trim().isNotEmpty;
  } catch (e, st) {
    debugPrint('verifyGroq error: $e');
    if (kDebugMode) debugPrint('$st');
    return false;
  }
}

/// Runs Supabase and Groq checks and returns result map.
Future<Map<String, bool>> checkConnections() async {
  final results = <String, bool>{};
  results['Supabase'] = await verifySupabase();
  results['Groq'] = await verifyGroq();
  return results;
}
