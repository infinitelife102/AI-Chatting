import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'connection_check.dart';
import 'gemini.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await Hive.initFlutter();
  await Hive.openBox('chat');
  runApp(const AIBusinessMentorApp());
}

class AIBusinessMentorApp extends StatelessWidget {
  const AIBusinessMentorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Business Mentor',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
      ),
      home: Builder(
        builder: (context) {
          final groqKey = dotenv.env['GROQ_API_KEY']?.trim() ?? '';
          if (groqKey.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('AI Business Mentor')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Set GROQ_API_KEY in your .env file.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final results = await checkConnections();
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Connection Check'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Supabase: ${results['Supabase'] == true ? "Connected" : "Failed"}',
                                    style: TextStyle(
                                      color: results['Supabase'] == true
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Groq: ${results['Groq'] == true ? "Connected" : "Failed"}',
                                    style: TextStyle(
                                      color: results['Groq'] == true
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.link),
                        label: const Text('Check connection'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return Gemini(groqApiKey: groqKey);
        },
      ),
    );
  }
}
