import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class GroqService {
  static final GroqService _instance = GroqService._internal();
  factory GroqService() => _instance;
  GroqService._internal();

  String? _apiKey;
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  bool get isInitialized => _apiKey != null;

  void initialize(String apiKey) {
    _apiKey = apiKey;
  }

  Future<String> getExplanation({
    required Question question,
  }) async {
    if (!isInitialized) {
      throw Exception('Groq service not initialized.');
    }

    final prompt = '''
Explain the answer to this question in a helpful, educational way.
Question: ${question.questionText}
Options:
A. ${question.optionA}
B. ${question.optionB}
C. ${question.optionC}
D. ${question.optionD}
Correct Answer: ${question.correctAnswer}

Explain why the correct answer is correct and briefly why the others are incorrect if relevant. Keep it concise (under 150 words).
''';

    print('DEBUG: Generated Prompt for Groq:');
    print(prompt);

    final messages = [
      {
        'role': 'system',
        'content': 'You are a helpful tutor explaining exam questions.',
      },
      {
        'role': 'user',
        'content': prompt,
      },
    ];

    return _makeRequest(messages);
  }

  Future<String> sendMessage(String message) async {
    if (!isInitialized) {
      throw Exception('Groq service not initialized.');
    }

    final messages = [
      {
        'role': 'user',
        'content': message,
      },
    ];

    return _makeRequest(messages);
  }

  Future<String> _makeRequest(List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'No response received.';
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['error']?['message'] ?? response.body;
        throw Exception('Groq API Error: $errorMessage (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to communicate with Groq: $e');
    }
  }
  Future<bool> testConnection(String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'user', 'content': 'hi'}
          ]
        }),
      );

      print('Groq Test Status: ${response.statusCode}');
      print('Groq Test Body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'Status ${response.statusCode}');
      }
    } catch (e) {
      print('Groq Connection Test Failed: $e');
      throw Exception('Connection failed: $e');
    }
  }
}
