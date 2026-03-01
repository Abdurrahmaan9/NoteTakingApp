import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../models/note.dart';

class DeletedItemsService {
  static final DeletedItemsService _instance = DeletedItemsService._internal();
  factory DeletedItemsService() => _instance;
  DeletedItemsService._internal();

  final List<Map<String, dynamic>> _deletedItems = [];

  List<Map<String, dynamic>> get deletedItems => List.unmodifiable(_deletedItems);

  void addDeletedTodo(Todo todo) {
    _deletedItems.add({
      'id': todo.id,
      'title': todo.title,
      'description': todo.description,
      'completed': todo.completed,
      'type': 'todo',
      'color': Colors.blue,
      'deletedAt': DateTime.now(),
      'data': todo.toJson(), // Store original data for restoration
    });
  }

  void addDeletedNote(Note note) {
    _deletedItems.add({
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'type': 'note',
      'color': Colors.green,
      'deletedAt': DateTime.now(),
      'data': note.toJson(), // Store original data for restoration
    });
  }

  void removeDeletedItem(Map<String, dynamic> item) {
    _deletedItems.remove(item);
  }

  void clearAllDeleted() {
    _deletedItems.clear();
  }

  Map<String, dynamic>? getDeletedItemById(String? id) {
    if (id == null) return null;
    try {
      return _deletedItems.firstWhere((item) => item['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Get items deleted within the last N days
  List<Map<String, dynamic>> getRecentlyDeleted({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _deletedItems
        .where((item) => (item['deletedAt'] as DateTime).isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => (b['deletedAt'] as DateTime)
          .compareTo(a['deletedAt'] as DateTime));
  }
}
