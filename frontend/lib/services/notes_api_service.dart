import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note.dart';

class NotesApiService {
  static const String baseUrl = 'http://localhost:4000/api';
  
  // Get all notes
  static Future<List<Note>> getNotes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notes'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> notesJson = data['data'];
        return notesJson.map((json) => Note.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notes: $e');
    }
  }

  // Create a new note
  static Future<Note> createNote(Note note) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notes'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'note': note.toJson()}),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Note.fromJson(data['data']);
      } else {
        throw Exception('Failed to create note: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating note: $e');
    }
  }

  // Update an existing note
  static Future<Note> updateNote(Note note) async {
    if (note.id == null) {
      throw Exception('Note ID is required for updates');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notes/${note.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'note': note.toJson()}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Note.fromJson(data['data']);
      } else {
        throw Exception('Failed to update note: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating note: $e');
    }
  }

  // Delete a note
  static Future<void> deleteNote(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notes/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete note: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting note: $e');
    }
  }
}
