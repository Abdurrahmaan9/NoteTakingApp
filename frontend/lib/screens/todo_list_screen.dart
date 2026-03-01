import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/api_service.dart';
import 'add_todo_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Todo> _todos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final todos = await ApiService.getTodos();
      setState(() {
        _todos = todos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTodoComplete(Todo todo) async {
    try {
      final updatedTodo = todo.copyWith(completed: !todo.completed);
      await ApiService.updateTodo(updatedTodo);
      if (mounted) {
        _loadTodos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating todo: $e')));
      }
    }
  }

  Future<void> _deleteTodo(Todo todo) async {
    if (todo.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteTodo(todo.id!);
        if (mounted) {
          _loadTodos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting todo: $e')));
        }
      }
    }
  }

  Future<void> _addTodo() async {
    final result = await Navigator.of(context).push<Todo>(
      MaterialPageRoute(builder: (context) => const AddTodoScreen()),
    );

    if (result != null) {
      try {
        await ApiService.createTodo(result);
        if (mounted) {
          _loadTodos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating todo: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(
          bottom: 80,
        ), // Add margin to avoid navigation bar
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'todo_fab_unique',
          onPressed: _addTodo,
          tooltip: 'Add Todo',
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 28),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Custom Header
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.1),
                theme.colorScheme.secondary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Todos',
                style: GoogleFonts.ubuntu(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${_todos.where((todo) => todo.completed).length}/${_todos.length}',
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading todos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadTodos, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No todos yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first todo',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTodos,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          bottom: 100,
        ), // Add padding for navigation bar
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          final todo = _todos[index];
          return TodoTile(
            todo: todo,
            onToggle: () => _toggleTodoComplete(todo),
            onDelete: () => _deleteTodo(todo),
          );
        },
      ),
    );
  }
}

class TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            todo.completed
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.8,
                  )
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            todo.completed
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  )
                : theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: todo.completed
                ? Colors.grey.withValues(alpha: 0.2)
                : theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: todo.completed
              ? theme.colorScheme.outline.withValues(alpha: 0.2)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and checkbox
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: todo.completed
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.5,
                                ),
                          width: 2,
                        ),
                        color: todo.completed
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: todo.completed
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: theme.colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        todo.title,
                        style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: todo.completed
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                )
                              : theme.colorScheme.onSurface,
                          height: 1.2,
                          decoration: todo.completed
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: todo.completed
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                )
                              : null,
                          decorationThickness: 2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Description
                if (todo.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    todo.description,
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: todo.completed
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                      decoration: todo.completed
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: todo.completed
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                          : null,
                      decorationThickness: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                // Actions and metadata
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: todo.completed
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.colorScheme.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        todo.completed ? 'Completed' : 'Active',
                        style: GoogleFonts.ubuntu(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: todo.completed
                              ? theme.colorScheme.primary
                              : theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.red.withValues(alpha: 0.8),
                        ),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
