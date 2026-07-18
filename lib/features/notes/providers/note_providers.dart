import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/note_model.dart';
import '../repositories/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  FirebaseFirestore? firestore;
  try {
    firestore = FirebaseFirestore.instance;
  } catch (_) {}
  return NoteRepository(firestore: firestore);
});

class NoteListNotifier extends StateNotifier<AsyncValue<List<NoteModel>>> {
  final NoteRepository _repository;
  final String _userId;

  NoteListNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    try {
      final notes = await _repository.getNotes(_userId);
      state = AsyncValue.data(notes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addNote({
    required String title,
    required String body,
    required List<String> tags,
  }) async {
    final list = state.value ?? [];
    final newNote = NoteModel(
      id: const Uuid().v4(),
      userId: _userId,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags,
    );

    state = AsyncValue.data([newNote, ...list]);

    try {
      await _repository.saveNote(newNote);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateNote(NoteModel updatedNote) async {
    final list = state.value ?? [];
    final changedNote = updatedNote.copyWith(updatedAt: DateTime.now());
    state = AsyncValue.data(
      list.map((n) => n.id == changedNote.id ? changedNote : n).toList(),
    );

    try {
      await _repository.saveNote(changedNote);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteNote(String id) async {
    final list = state.value ?? [];
    state = AsyncValue.data(list.where((n) => n.id != id).toList());

    try {
      await _repository.deleteNote(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final noteListProvider =
    StateNotifierProvider<NoteListNotifier, AsyncValue<List<NoteModel>>>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  final user = ref.watch(authControllerProvider).value;
  final userId = user?.uid ?? 'guest';
  return NoteListNotifier(repository, userId);
});
