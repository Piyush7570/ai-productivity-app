import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AIChatNotifier extends StateNotifier<List<ChatMessage>> {
  AIChatNotifier() : super([]);

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(text: text, isUser: true, timestamp: DateTime.now());
    state = [...state, userMsg];

    if (!GeminiService().isConfigured) {
      final errorMsg = ChatMessage(
        text: 'Error: Gemini API Key is not configured. Please add it in Settings to enable the AI assistant.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = [...state, errorMsg];
      return;
    }

    // Temporary Loading Message
    final loadingMsg = ChatMessage(text: 'AI is thinking...', isUser: false, timestamp: DateTime.now());
    state = [...state, loadingMsg];

    try {
      final responseText = await GeminiService().generateWritingContent(
        prompt: text,
        category: 'general query',
      );
      // Remove loading message and add reply
      state = state.sublist(0, state.length - 1);
      final replyMsg = ChatMessage(text: responseText, isUser: false, timestamp: DateTime.now());
      state = [...state, replyMsg];
    } catch (e) {
      state = state.sublist(0, state.length - 1);
      final errorMsg = ChatMessage(
        text: 'Failed to generate response: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = [...state, errorMsg];
    }
  }

  void clearChat() {
    state = [];
  }
}

final aiChatProvider = StateNotifierProvider<AIChatNotifier, List<ChatMessage>>((ref) {
  return AIChatNotifier();
});
