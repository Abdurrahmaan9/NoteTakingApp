import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notes_api_service.dart';
import '../models/todo.dart';
import '../models/note.dart';
import 'add_todo_screen.dart';
import 'add_note_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTodos;
  final VoidCallback? onNavigateToNotes;

  const HomeScreen({
    super.key,
    this.onNavigateToTodos,
    this.onNavigateToNotes,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _todoStats = [];
  List<Map<String, dynamic>> _noteStats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load todos and notes to calculate stats
      final todos = await ApiService.getTodos();
      final notes = await NotesApiService.getNotes();

      final completedTodos = todos.where((todo) => todo.completed).length;
      final inProgressTodos = todos.where((todo) => !todo.completed).length;
      
      // Calculate note stats (you can expand this with more categories)
      final totalNotes = notes.length;
      final recentNotes = notes.where((note) {
        return DateTime.now().difference(note.updatedAt).inDays <= 7;
      }).length;

      setState(() {
        _todoStats = [
          {'title': 'Completed', 'count': completedTodos, 'color': Colors.green, 'icon': Icons.check_circle},
          {'title': 'In Progress', 'count': inProgressTodos, 'color': Colors.blue, 'icon': Icons.pending},
        ];
        
        _noteStats = [
          {'title': 'Total Notes', 'count': totalNotes, 'color': Colors.purple, 'icon': Icons.note},
          {'title': 'Recent Notes', 'count': recentNotes, 'color': Colors.orange, 'icon': Icons.update},
        ];
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 100.0, // Add padding for bottom navigation
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading stats',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(_error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadStats,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 100.0, // Add padding for bottom navigation
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Todo Stats Section
            _buildStatsSection('Todo Summary', _todoStats),
            const SizedBox(height: 24),
            
            // Note Stats Section
            _buildStatsSection('Note Summary', _noteStats),
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 24),
            
            // Recent Activity
            _buildRecentActivity(),
            const SizedBox(height: 24), // Add extra padding at the bottom
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome back! Here\'s your productivity overview.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Last updated: ${DateTime.now().toString().substring(0, 19)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(String title, List<Map<String, dynamic>> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0, // Increased from 1.2 to give more height
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _buildStatCard(stat);
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      decoration: BoxDecoration(
        color: (stat['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (stat['color'] as Color).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Prevent overflow
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Reduced padding
              decoration: BoxDecoration(
                color: stat['color'] as Color,
                borderRadius: BorderRadius.circular(6), // Reduced border radius
              ),
              child: Icon(
                stat['icon'] as IconData,
                color: Colors.white,
                size: 16, // Reduced icon size
              ),
            ),
            const SizedBox(height: 8), // Reduced spacing
            Text(
              '${stat['count']}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith( // Smaller text style
                fontWeight: FontWeight.bold,
                color: stat['color'] as Color,
              ),
            ),
            const SizedBox(height: 2), // Reduced spacing
            Text(
              stat['title'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith( // Smaller text style
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Add Todo',
                Icons.add_task,
                Colors.blue,
                () async {
                  final result = await Navigator.of(context).push<Todo>(
                    MaterialPageRoute(builder: (context) => const AddTodoScreen()),
                  );
                  
                  if (result != null) {
                    try {
                      await ApiService.createTodo(result);
                      _loadStats(); // Refresh stats after adding
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Todo added successfully!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error adding todo: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Add Note',
                Icons.note_add,
                Colors.purple,
                () async {
                  final result = await Navigator.of(context).push<Note>(
                    MaterialPageRoute(builder: (context) => const AddNoteScreen()),
                  );
                  
                  if (result != null) {
                    try {
                      await NotesApiService.createNote(result);
                      _loadStats(); // Refresh stats after adding
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note added successfully!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error adding note: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.history, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your recent activity will appear here',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
