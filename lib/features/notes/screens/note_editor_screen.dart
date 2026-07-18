import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/gemini_service.dart';
import '../models/note_model.dart';
import '../providers/note_providers.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final NoteModel? note;

  const NoteEditorScreen({Key? key, this.note}) : super(key: key);

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _tagController;
  final List<String> _tags = [];
  bool _isPreviewMode = false;
  bool _isAILoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
    _tagController = TextEditingController();
    if (widget.note != null) {
      _tags.addAll(widget.note!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty && body.isEmpty) return;

    if (widget.note == null) {
      ref.read(noteListProvider.notifier).addNote(
            title: title.isEmpty ? 'Untitled Note' : title,
            body: body,
            tags: _tags,
          );
    } else {
      final updated = widget.note!.copyWith(
        title: title.isEmpty ? 'Untitled Note' : title,
        body: body,
        tags: _tags,
      );
      ref.read(noteListProvider.notifier).updateNote(updated);
    }
  }

  Future<void> _runAIAction(Future<String> Function() action, Function(String) onDone) async {
    if (!GeminiService().isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API is not configured. Add your key in Settings.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isAILoading = true);
    try {
      final result = await action();
      onDone(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI action failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isAILoading = false);
    }
  }

  void _showSummarizeDialog() {
    final noteBody = _bodyController.text.trim();
    if (noteBody.isEmpty) return;

    _runAIAction(
      () => GeminiService().summarizeNote(noteBody),
      (summary) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('AI Summary'),
            content: SingleChildScrollView(
              child: Text(summary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Dismiss'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _bodyController.text += '\n\n### AI Summary\n$summary';
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Append to Note'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRewriteDialog() {
    final noteBody = _bodyController.text.trim();
    if (noteBody.isEmpty) return;

    final instructionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI Note Rewrite'),
        content: TextField(
          controller: instructionController,
          decoration: const InputDecoration(
            hintText: 'e.g., Make it formal, summarize into bullet points, etc.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final instr = instructionController.text.trim();
              Navigator.pop(ctx);
              if (instr.isNotEmpty) {
                _runAIAction(
                  () => GeminiService().rewriteNote(noteBody, instr),
                  (rewritten) {
                    setState(() {
                      _bodyController.text = rewritten;
                    });
                  },
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showFlashcardsDialog() {
    final noteBody = _bodyController.text.trim();
    if (noteBody.isEmpty) return;

    if (!GeminiService().isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API is not configured. Add key in Settings.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isAILoading = true);
    
    // Perform async generation
    GeminiService().generateFlashcards(noteBody).then((flashcards) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Study Flashcards Generated'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: flashcards.length,
                itemBuilder: (context, idx) {
                  final card = flashcards[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Q: ${card['question']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(height: 12),
                          Text('A: ${card['answer']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }).whenComplete(() {
      if (mounted) setState(() => _isAILoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note', style: GoogleFonts.outfit()),
        actions: [
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.edit_rounded : Icons.visibility_rounded),
            tooltip: _isPreviewMode ? 'Edit Mode' : 'Markdown Preview',
            onPressed: () {
              setState(() => _isPreviewMode = !_isPreviewMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _saveNote();
              Navigator.pop(context);
            },
          ),
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () {
                ref.read(noteListProvider.notifier).deleteNote(widget.note!.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          _saveNote();
          return true;
        },
        child: Column(
          children: [
            // AI Action Panel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.primary.withOpacity(0.08),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('AI Assistant:', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _isAILoading
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  children: [
                                    ActionChip(
                                      label: const Text('Summarize'),
                                      onPressed: _showSummarizeDialog,
                                    ),
                                    ActionChip(
                                      label: const Text('Rewrite'),
                                      onPressed: _showRewriteDialog,
                                    ),
                                    ActionChip(
                                      label: const Text('Flashcards'),
                                      onPressed: _showFlashcardsDialog,
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Note Editor / Previewer
            Expanded(
              child: _isPreviewMode
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: MarkdownBody(
                        data: _bodyController.text.isEmpty
                            ? '*Empty Note content (type in edit mode to see Markdown output)*'
                            : _bodyController.text,
                        selectable: true,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Title Field
                          TextField(
                            controller: _titleController,
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              hintText: 'Note Title',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const Divider(),
                          // Tags List display
                          Row(
                            children: [
                              const Icon(Icons.tag_rounded, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ..._tags.map((tag) => Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: theme.dividerColor,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(tag, style: const TextStyle(fontSize: 12)),
                                                const SizedBox(width: 4),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() => _tags.remove(tag));
                                                  },
                                                  child: const Icon(Icons.close, size: 12),
                                                ),
                                              ],
                                            ),
                                          )),
                                      // Add Tag inline
                                      SizedBox(
                                        width: 80,
                                        height: 28,
                                        child: TextField(
                                          controller: _tagController,
                                          style: const TextStyle(fontSize: 12),
                                          decoration: const InputDecoration(
                                            hintText: '+ tag',
                                            contentPadding: EdgeInsets.only(bottom: 12),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                          ),
                                          onSubmitted: (val) {
                                            final tag = val.trim();
                                            if (tag.isNotEmpty && !_tags.contains(tag)) {
                                              setState(() {
                                                _tags.add(tag);
                                                _tagController.clear();
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          
                          // Body Field
                          Expanded(
                            child: TextField(
                              controller: _bodyController,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              style: const TextStyle(fontSize: 16, height: 1.5),
                              decoration: const InputDecoration(
                                hintText: 'Write notes here... (Supports Markdown)',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
