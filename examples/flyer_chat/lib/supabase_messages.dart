import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _tableName = 'messages';

/// Fetches all messages from Supabase ordered by created_at.
Future<List<Message>> fetchMessages() async {
  final client = Supabase.instance.client;
  final res = await client
      .from(_tableName)
      .select()
      .order('created_at', ascending: true);

  final list = res as List<dynamic>;
  return list.map((row) => _rowToMessage(row as Map<String, dynamic>)).toList();
}

Message _rowToMessage(Map<String, dynamic> row) {
  final id = row['id']?.toString() ?? '';
  final authorId = row['author_id'] as String? ?? 'me';
  final createdAt = row['created_at'] != null
      ? DateTime.parse(row['created_at'] as String).toUtc()
      : DateTime.now().toUtc();
  final text = row['text'] as String? ?? '';
  final imageUrl = row['image_url'] as String?;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    return ImageMessage(
      id: id,
      authorId: authorId,
      createdAt: createdAt,
      source: imageUrl,
    );
  }
  return TextMessage(
    id: id,
    authorId: authorId,
    createdAt: createdAt,
    text: text,
  );
}

/// Inserts a message into Supabase. [id] optional; if omitted Supabase generates uuid.
/// Returns the inserted row with id and created_at.
Future<Map<String, dynamic>> insertMessage({
  String? id,
  required String text,
  required bool isAi,
  String? imageUrl,
  required String authorId,
}) async {
  final client = Supabase.instance.client;
  final map = <String, dynamic>{
    'text': text,
    'is_ai': isAi,
    'author_id': authorId,
  };
  if (id != null && id.isNotEmpty) map['id'] = id;
  if (imageUrl != null && imageUrl.isNotEmpty) map['image_url'] = imageUrl;

  final res = await client.from(_tableName).insert(map).select().single();
  return res;
}
