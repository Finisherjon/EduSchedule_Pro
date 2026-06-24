import 'package:flutter/foundation.dart';
import '../models/class_group_model.dart';
import '../repositories/class_group_repository.dart';

class ClassGroupProvider extends ChangeNotifier {
  final _repo = ClassGroupRepository();

  List<ClassGroupModel> _groups = [];
  bool _isLoading = false;
  String? _error;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<ClassGroupModel> get groups => List.unmodifiable(_groups);
  bool get isLoading => _isLoading;
  bool get isEmpty => _groups.isEmpty;
  int get count => _groups.length;
  String? get error => _error;

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _groups = _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ClassGroupModel? getById(String id) => _repo.getById(id);

  // ─── Write ────────────────────────────────────────────────────────────────

  /// Bitta sinfni saqlaydi (yangi yoki yangilash).
  Future<void> save(ClassGroupModel group) async {
    await _repo.save(group);
    // Local listni ham yangilaymiz — to'liq reload qilmasdan
    final idx = _groups.indexWhere((g) => g.id == group.id);
    if (idx >= 0) {
      _groups[idx] = group;
    } else {
      _groups.add(group);
    }
    notifyListeners();
  }

  /// Bir vaqtda bir nechta sinfni saqlaydi (setup jarayonidan keladi).
  Future<void> saveAll(List<ClassGroupModel> groups) async {
    await _repo.saveAll(groups);
    _groups = _repo.getAll();
    notifyListeners();
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _groups.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  Future<void> deleteAll() async {
    await _repo.deleteAll();
    _groups = [];
    notifyListeners();
  }

  // ─── Subject helpers ──────────────────────────────────────────────────────

  /// Mavjud sinfga yangi fan qo'shadi.
  Future<void> addSubject(String groupId, subject) async {
    final group = getById(groupId);
    if (group == null) return;
    final updated = group.copyWith(
      subjects: [...group.subjects, subject],
    );
    await save(updated);
  }

  /// Mavjud sinfdan fan o'chiradi.
  Future<void> removeSubject(String groupId, String subjectId) async {
    final group = getById(groupId);
    if (group == null) return;
    final updated = group.copyWith(
      subjects: group.subjects.where((s) => s.id != subjectId).toList(),
    );
    await save(updated);
  }
}
