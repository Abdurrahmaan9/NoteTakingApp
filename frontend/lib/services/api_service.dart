import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/todo.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:4000/api';
  
  // Get all todos
  static Future<List<Todo>> getTodos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/items'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> todosJson = data['data'];
        return todosJson.map((json) => Todo.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load todos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching todos: $e');
    }
  }

  // Create a new todo
  static Future<Todo> createTodo(Todo todo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/items'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'item': todo.toJson()}),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Todo.fromJson(data['data']);
      } else {
        throw Exception('Failed to create todo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating todo: $e');
    }
  }

  // Update an existing todo
  static Future<Todo> updateTodo(Todo todo) async {
    if (todo.id == null) {
      throw Exception('Todo ID is required for updates');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/items/${todo.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'item': todo.toJson()}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Todo.fromJson(data['data']);
      } else {
        throw Exception('Failed to update todo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating todo: $e');
    }
  }

  // Delete a todo
  static Future<void> deleteTodo(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/items/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete todo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting todo: $e');
    }
  }
}
