import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
const String _model = 'llama-3.3-70b-versatile';

/// Builds OpenAI-format messages from chat history (user/assistant only).
List<Map<String, String>> buildMessages(
  List<Map<String, String>> history,
  String userContent,
) {
  final list = List<Map<String, String>>.from(history);
  list.add({'role': 'user', 'content': userContent});
  return list;
}

/// Streams Groq chat completion; yields content deltas as [String].
/// Throws on HTTP or API errors.
Stream<String> streamChat({
  required String apiKey,
  required List<Map<String, String>> messages,
}) async* {
  final body = jsonEncode({
    'model': _model,
    'messages': messages,
    'stream': true,
  });

  final request = http.Request('POST', Uri.parse(_baseUrl))
    ..headers['Authorization'] = 'Bearer $apiKey'
    ..headers['Content-Type'] = 'application/json'
    ..body = body;

  final client = http.Client();
  try {
    final response = await client.send(request);

    if (response.statusCode != 200) {
      final bytes = await response.stream.toBytes();
      final str = utf8.decode(bytes);
      throw Exception('Groq API error ${response.statusCode}: $str');
    }

    var buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') continue;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            final delta = choices?.isNotEmpty == true
                ? (choices!.first as Map<String, dynamic>)['delta'] as Map<String, dynamic>?
                : null;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) yield content;
          } catch (_) {}
        }
      }
    }
    if (buffer.trim().startsWith('data: ')) {
      final data = buffer.substring(6).trim();
      if (data != '[DONE]') {
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>?;
          final delta = choices?.isNotEmpty == true
              ? (choices!.first as Map<String, dynamic>)['delta'] as Map<String, dynamic>?
              : null;
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) yield content;
        } catch (_) {}
      }
    }
  } finally {
    client.close();
  }
}
