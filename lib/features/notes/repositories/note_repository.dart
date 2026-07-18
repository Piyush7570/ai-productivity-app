import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/db_service.dart';
import '../models/note_model.dart';

class NoteRepository {
  final FirebaseFirestore? _firestore;

  NoteRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  bool get _useFirebase {
    try {
      return _firestore != null;
    } catch (_) {
      return false;
    }
  }

  Future<List<NoteModel>> getNotes(String userId) async {
    final box = DatabaseService.notesBox;
    final localNotes = box.values
        .map((map) => NoteModel.fromMap(map))
        .where((note) => note.userId == userId)
        .toList();

    if (_useFirebase) {
      try {
        final snapshot = await _firestore!
            .collection('notes')
            .where('userId', isEqualTo: userId)
            .get();

        final remoteNotes = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return NoteModel.fromMap(data);
        }).toList();

        for (var note in remoteNotes) {
          await box.put(note.id, note.toMap());
        }

        return remoteNotes;
      } catch (_) {
        return localNotes;
      }
    }
    return localNotes;
  }

  Future<void> saveNote(NoteModel note) async {
    await DatabaseService.notesBox.put(note.id, note.toMap());

    if (_useFirebase) {
      try {
        await _firestore!
            .collection('notes')
            .doc(note.id)
            .set(note.toMap());
      } catch (_) {}
    }
  }

  Future<void> deleteNote(String id) async {
    await DatabaseService.notesBox.delete(id);

    if (_useFirebase) {
      try {
        await _firestore!.collection('notes').doc(id).delete();
      } catch (_) {}
    }
  }
}
