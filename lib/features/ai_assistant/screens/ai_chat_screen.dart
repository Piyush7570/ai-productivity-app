import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/gemini_service.dart';
import '../providers/ai_providers.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatInputController = TextEditingController();
  final _scrollController = ScrollController();

  // Writing assistant fields
  String _writingCategory = 'Email';
  final _writingPromptController = TextEditingController();
  String _writingResult = '';
  bool _isWritingLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatInputController.dispose();
    _scrollController.dispose();
    _writingPromptController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendChatMessage() async {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;
    _chatInputController.clear();
    await ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _generateWritingContent() async {
    final prompt = _writingPromptController.text.trim();
    if (prompt.isEmpty) return;

    if (!GeminiService().isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API is not configured. Add your key in Settings.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isWritingLoading = true;
      _writingResult = '';
    });

    try {
      final result = await GeminiService().generateWritingContent(
        prompt: prompt,
        category: _writingCategory,
      );
      setState(() {
        _writingResult = result;
      });
    } catch (e) {
      setState(() {
        _writingResult = 'Failed to generate writing content: $e';
      });
    } finally {
      setState(() => _isWritingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Hub', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'AI Assistant', icon: Icon(Icons.forum_outlined)),
            Tab(text: 'Writing Assistant', icon: Icon(Icons.draw_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(),
          _buildWritingTab(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    final theme = Theme.of(context);
    final chatMessages = ref.watch(aiChatProvider);

    return Column(
      children: [
        Expanded(
          child: chatMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt, size: 64, color: theme.colorScheme.primary.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'AI Assistant Ready',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          'Ask: "Plan my day", "How should I prioritize these?", "Draft study notes"',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatMessages.length,
                  itemBuilder: (context, idx) {
                    final msg = chatMessages[idx];
                    return _buildChatBubble(msg);
                  },
                ),
        ),
        // Chat Input Area
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatInputController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Type your prompt here...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sendChatMessage,
                icon: const Icon(Icons.send_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.brightness == Brightness.dark ? AppColors.darkBg : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final isMe = message.isUser;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary
              : theme.brightness == Brightness.dark
                  ? AppColors.darkCardBg
                  : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isMe
                ? (theme.brightness == Brightness.dark ? AppColors.darkBg : Colors.white)
                : theme.textTheme.bodyMedium?.color,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildWritingTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select Format',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _writingCategory,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                  items: ['Email', 'Report', 'Meeting Notes', 'Message']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _writingCategory = val ?? 'Email'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Instructions / Prompt',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _writingPromptController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Draft an email to my manager asking for a status meeting update, make it polite...',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _isWritingLoading ? null : _generateWritingContent,
            icon: _isWritingLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.bolt),
            label: Text(_isWritingLoading ? 'Generating...' : 'Generate Content'),
          ),

          if (_writingResult.isNotEmpty || _isWritingLoading) ...[
            const SizedBox(height: 24),
            Text(
              'Result Output',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isWritingLoading ? 'Please wait, generating draft...' : _writingResult,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  if (!_isWritingLoading && _writingResult.isNotEmpty) ...[
                    const Divider(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _writingResult));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy to Clipboard'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
