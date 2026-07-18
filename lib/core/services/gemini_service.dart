import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  GenerativeModel? _model;
  String? _loadedApiKey;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('gemini_api_key');
    if (key != null && key.isNotEmpty) {
      _loadedApiKey = key;
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
      );
    }
  }

  Future<void> updateApiKey(String newKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', newKey);
    _loadedApiKey = newKey;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: newKey,
    );
  }

  bool get isConfigured => _model != null;

  GenerativeModel get _activeModel {
    if (_model == null) {
      throw Exception('Gemini API Key is not configured. Please add it in Settings.');
    }
    return _model!;
  }

  // --- 1. AI Task Prioritization ---
  Future<String> suggestPriority({
    required String title,
    required String description,
    DateTime? deadline,
  }) async {
    if (!isConfigured) return 'Medium'; // Fallback
    
    final deadlineStr = deadline != null ? deadline.toIso8601String() : 'None';
    final prompt = '''
Analyze the following task and recommend a priority: "High", "Medium", or "Low".
Task Title: $title
Description: $description
Deadline: $deadlineStr

Respond with ONLY one word: "High", "Medium", or "Low".
''';
    
    try {
      final response = await _activeModel.generateContent([Content.text(prompt)]);
      final result = response.text?.trim() ?? 'Medium';
      if (['High', 'Medium', 'Low'].contains(result)) {
        return result;
      }
      return 'Medium';
    } catch (e) {
      return 'Medium';
    }
  }

  // --- 2. AI Note Assistant ---
  Future<String> summarizeNote(String content) async {
    final prompt = 'Summarize the following note content concisely. Maintain key takeaways and make it easy to read:\n\n$content';
    final response = await _activeModel.generateContent([Content.text(prompt)]);
    return response.text ?? 'Summary failed.';
  }

  Future<String> rewriteNote(String content, String instruction) async {
    final prompt = 'Rewrite the following text based on this instruction: "$instruction". Text:\n\n$content';
    final response = await _activeModel.generateContent([Content.text(prompt)]);
    return response.text ?? 'Rewrite failed.';
  }

  Future<List<Map<String, String>>> generateFlashcards(String content) async {
    final prompt = '''
Based on the following notes, generate 3 to 5 study flashcards.
Format the output as a valid JSON array of objects, where each object has "question" and "answer" keys.
Do not wrap the output in markdown block format. Just output the raw JSON.

Notes Content:
$content
''';
    final response = await _activeModel.generateContent([Content.text(prompt)]);
    final rawText = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '';
    try {
      final decoded = jsonDecode(rawText) as List;
      return decoded.map((e) => {
        'question': e['question'].toString(),
        'answer': e['answer'].toString(),
      }).toList();
    } catch (e) {
      // Fallback manual parsing if JSON fails
      return [
        {'question': 'Key Concept Summary', 'answer': content.length > 50 ? '${content.substring(0, 47)}...' : content}
      ];
    }
  }

  // --- 3. AI Schedule Planner ---
  Future<String> generateSchedule({
    required List<Map<String, dynamic>> tasks,
    required double availableHours,
    required String preferences,
  }) async {
    final tasksJson = jsonEncode(tasks);
    final prompt = '''
Create a detailed hourly schedule based on the following:
Available time: $availableHours hours
User preferences/routine constraints: $preferences

Tasks list:
$tasksJson

Recommend breaks (e.g. Pomodoro breaks) and organize tasks logically by their priorities and deadlines. Provide a professional, structured Markdown formatted schedule.
''';
    final response = await _activeModel.generateContent([Content.text(prompt)]);
    return response.text ?? 'Failed to generate schedule.';
  }

  // --- 4. AI Writing Assistant ---
  Future<String> generateWritingContent({
    required String prompt,
    required String category, // Email, Report, Meeting Notes, Message
  }) async {
    final fullPrompt = 'Act as a professional writing assistant. Generate a high-quality $category based on the following instructions:\n\n$prompt';
    final response = await _activeModel.generateContent([Content.text(fullPrompt)]);
    return response.text ?? 'Failed to generate content.';
  }

  // --- 5. Smart Search ---
  Future<List<String>> searchSemanticMatches({
    required String query,
    required List<Map<String, dynamic>> items, // Contains tasks or notes with ID, Title, Description/Body
  }) async {
    if (!isConfigured) return [];
    
    // We send only minimum details (ID, Title) to optimize token size and respect data privacy boundaries
    final simplifiedItems = items.map((item) => {
      'id': item['id'],
      'title': item['title'],
      'description': item['description'] ?? item['body'] ?? '',
    }).toList();

    final prompt = '''
Search through these items and return a JSON list containing the 'id's of items that semantically match the search query: "$query".
Only match items that are highly relevant to the query. If none match, return an empty list [].
Do not explain your reasoning. Output only the JSON list of matching ids.

Items:
${jsonEncode(simplifiedItems)}
''';

    try {
      final response = await _activeModel.generateContent([Content.text(prompt)]);
      final rawText = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '';
      final decoded = jsonDecode(rawText) as List;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }
}
