import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notes_api_service.dart';
import '../services/deleted_items_service.dart';
import '../models/todo.dart';
import '../models/note.dart';
import '../utils/responsive_breakpoints.dart';
import 'add_todo_screen.dart';
import 'add_note_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTodos;
  final VoidCallback? onNavigateToNotes;

  const HomeScreen({super.key, this.onNavigateToTodos, this.onNavigateToNotes});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _todoStats = [];
  List<Map<String, dynamic>> _noteStats = [];
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> _recentDeleted = [];
  bool _isLoading = true;
  String? _error;
  bool _isActivitiesExpanded = true;
  bool _isDeletedExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes to foreground
      _refreshRecentActivities();
      _refreshDeletedItems();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh deleted items when returning to this screen
    _refreshDeletedItems();
    // Add a slight delay to ensure navigation is complete
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _refreshRecentActivities();
      }
    });
  }

  void _refreshDeletedItems() {
    final deletedService = DeletedItemsService();
    setState(() {
      _recentDeleted = deletedService.getRecentlyDeleted();
    });
  }

  void _refreshRecentActivities() {
    // Refresh recent activities by reloading stats
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final todos = await ApiService.getTodos();
      final notes = await NotesApiService.getNotes();

      final completedTodos = todos.where((todo) => todo.completed).length;
      final inProgressTodos = todos.where((todo) => !todo.completed).length;

      // Filter notes created in the last 7 days
      final recentNotesCount = notes.where((note) {
        return DateTime.now().difference(note.createdAt).inDays <= 7;
      }).length;

      setState(() {
        _todoStats = [
          {
            'title': 'Completed',
            'count': completedTodos,
            'icon': Icons.check_circle,
            'color': Colors.green,
          },
          {
            'title': 'In Progress',
            'count': inProgressTodos,
            'icon': Icons.pending,
            'color': Colors.orange,
          },
        ];

        _noteStats = [
          {
            'title': 'Total Notes',
            'count': notes.length,
            'icon': Icons.note,
            'color': Colors.purple,
          },
          {
            'title': 'Recent Notes',
            'count': recentNotesCount,
            'icon': Icons.update,
            'color': Colors.blue,
          },
        ];

        _recentActivities = [];

        // FIX 1: Sort Todos by ID descending (assuming higher ID = newer)
        // or simply reverse the list if the API returns them oldest first.
        final latestTodos = todos.reversed.take(5).toList();

        for (var todo in latestTodos) {
          _recentActivities.add({
            'type': 'todo',
            'id': todo.id, // Keep track of ID
            'title': todo.title,
            'description': todo.description,
            'completed': todo.completed,
            // FIX 2: Since Todos have no createdAt, we use a slightly
            // offset timestamp or just assume they are "now" but sorted correctly later
            'createdAt': DateTime.now().subtract(const Duration(seconds: 1)),
            'icon': todo.completed ? Icons.check_circle : Icons.pending,
            'color': todo.completed ? Colors.green : Colors.orange,
          });
        }

        // FIX 3: Sort Notes by actual createdAt date descending
        final latestNotes = List<Note>.from(notes);
        latestNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        for (var note in latestNotes.take(5)) {
          _recentActivities.add({
            'type': 'note',
            'title': note.title,
            'description': note.content,
            'createdAt': note.createdAt,
            'icon': Icons.note,
            'color': Colors.purple,
          });
        }

        // FINAL SORT: Combine and sort the merged list
        _recentActivities.sort((a, b) {
          // If it's a Todo vs Todo and they both have 'now' timestamps, sort by ID
          if (a['type'] == 'todo' &&
              b['type'] == 'todo' &&
              a['id'] != null &&
              b['id'] != null) {
            return b['id'].compareTo(a['id']);
          }
          return b['createdAt'].compareTo(a['createdAt']);
        });

        // Keep only the top 6
        _recentActivities = _recentActivities.take(6).toList();

        final deletedService = DeletedItemsService();
        _recentDeleted = deletedService.getRecentlyDeleted();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding:
                  ResponsiveBreakpoints.getScreenPadding(
                    constraints.maxWidth,
                  ).copyWith(
                    bottom: 100.0, // Add padding for bottom navigation
                  ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
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
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: () async {
            await _loadStats();
            // Also refresh deleted items after loading stats
            _refreshDeletedItems();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                ResponsiveBreakpoints.getScreenPadding(
                  constraints.maxWidth,
                ).copyWith(
                  bottom: 120.0, // Add padding for bottom navigation
                ),
            child: _buildAdaptiveLayout(constraints.maxWidth),
          ),
        );
      },
    );
  }

  Widget _buildAdaptiveLayout(double screenWidth) {
    if (ResponsiveBreakpoints.isMobile(screenWidth)) {
      return _buildMobileLayout();
    } else if (ResponsiveBreakpoints.isTablet(screenWidth)) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        SizedBox(
          height: ResponsiveBreakpoints.getSectionSpacing(
            MediaQuery.of(context).size.width,
          ),
        ),

        // Todo Stats Section
        _buildStatsSection('Todo Summary', _todoStats),
        SizedBox(
          height: ResponsiveBreakpoints.getSectionSpacing(
            MediaQuery.of(context).size.width,
          ),
        ),

        // Note Stats Section
        _buildStatsSection('Note Summary', _noteStats),
        SizedBox(
          height: ResponsiveBreakpoints.getSectionSpacing(
            MediaQuery.of(context).size.width,
          ),
        ),

        // Quick Actions
        _buildQuickActions(),
        SizedBox(
          height: ResponsiveBreakpoints.getSectionSpacing(
            MediaQuery.of(context).size.width,
          ),
        ),

        // Recent Activity
        _buildRecentActivity(),
        SizedBox(
          height: ResponsiveBreakpoints.getSectionSpacing(
            MediaQuery.of(context).size.width,
          ),
        ),

        // Recently Deleted
        _buildRecentDeleted(),
        SizedBox(
          height: ResponsiveBreakpoints.getSectionSpacing(
            MediaQuery.of(context).size.width,
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        SizedBox(
          height: ResponsiveBreakpoints.getSectionSpacing(
            MediaQuery.of(context).size.width,
          ),
        ),

        // Stats Sections in a row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildStatsSection('Todo Summary', _todoStats)),
            SizedBox(
              width: ResponsiveBreakpoints.getItemSpacing(
                MediaQuery.of(context).size.width,
              ),
            ),
            Expanded(child: _buildStatsSection('Note Summary', _noteStats)),
          ],
        ),
        SizedBox(
          height: ResponsiveBreakpoints.getSectionSpacing(
            MediaQuery.of(context).size.width,
          ),
        ),

        // Quick Actions
        _buildQuickActions(),
        SizedBox(
          height: ResponsiveBreakpoints.getSectionSpacing(
            MediaQuery.of(context).size.width,
          ),
        ),

        // Activity and Deleted sections in a row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildRecentActivity()),
            SizedBox(
              width: ResponsiveBreakpoints.getItemSpacing(
                MediaQuery.of(context).size.width,
              ),
            ),
            Expanded(flex: 1, child: _buildRecentDeleted()),
          ],
        ),
        SizedBox(
          height: ResponsiveBreakpoints.getSectionSpacing(
            MediaQuery.of(context).size.width,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        SizedBox(
          height: ResponsiveBreakpoints.getSectionSpacing(
            MediaQuery.of(context).size.width,
          ),
        ),

        // Main content in 3 columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - Stats
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection('Todo Summary', _todoStats),
                  SizedBox(
                    height: ResponsiveBreakpoints.getSectionSpacing(
                      MediaQuery.of(context).size.width,
                    ),
                  ),
                  _buildStatsSection('Note Summary', _noteStats),
                ],
              ),
            ),
            SizedBox(
              width: ResponsiveBreakpoints.getItemSpacing(
                MediaQuery.of(context).size.width,
              ),
            ),

            // Middle column - Quick Actions and Activity
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActions(),
                  SizedBox(
                    height: ResponsiveBreakpoints.getSectionSpacing(
                      MediaQuery.of(context).size.width,
                    ),
                  ),
                  _buildRecentActivity(),
                ],
              ),
            ),
            SizedBox(
              width: ResponsiveBreakpoints.getItemSpacing(
                MediaQuery.of(context).size.width,
              ),
            ),

            // Right column - Deleted Items
            Expanded(flex: 1, child: _buildRecentDeleted()),
          ],
        ),
        SizedBox(
          height: ResponsiveBreakpoints.getSectionSpacing(
            MediaQuery.of(context).size.width,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
        final cardPadding = ResponsiveBreakpoints.getCardPadding(screenWidth);

        return Container(
          padding: cardPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.home,
                  color: Theme.of(context).colorScheme.primary,
                  size: isMobile ? 24 : 28,
                ),
              ),
              SizedBox(width: isMobile ? 16 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: ResponsiveBreakpoints.getHeaderFontSize(
                              screenWidth,
                            ),
                          ),
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    Text(
                      'Welcome back! Here\'s your productivity overview.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_todoStats.length + _noteStats.length} items',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(String title, List<Map<String, dynamic>> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final crossAxisCount = ResponsiveBreakpoints.getStatsColumns(
          screenWidth,
        );
        final aspectRatio = ResponsiveBreakpoints.getStatsAspectRatio(
          screenWidth,
        );
        final itemSpacing = ResponsiveBreakpoints.getItemSpacing(screenWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: ResponsiveBreakpoints.getTitleFontSize(screenWidth),
              ),
            ),
            SizedBox(height: itemSpacing),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: itemSpacing,
                mainAxisSpacing: itemSpacing,
                childAspectRatio: aspectRatio,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final stat = stats[index];
                return _buildStatCard(stat, screenWidth);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, double screenWidth) {
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final cardPadding = EdgeInsets.all(isMobile ? 10 : 12);

    return Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            stat['color'].withValues(alpha: 0.1),
            stat['color'].withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: stat['color'].withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: stat['color'].withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: stat['color'].withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              stat['icon'],
              color: stat['color'],
              size: isMobile ? 20 : 22,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            '${stat['count']}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: stat['color'],
              fontSize: isMobile
                  ? null
                  : ResponsiveBreakpoints.getTitleFontSize(screenWidth) * 0.7,
            ),
          ),
          SizedBox(height: isMobile ? 1 : 2),
          Text(
            stat['title'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
              fontSize: isMobile ? 10 : 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final itemSpacing = ResponsiveBreakpoints.getItemSpacing(screenWidth);
        final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: ResponsiveBreakpoints.getTitleFontSize(screenWidth),
              ),
            ),
            SizedBox(height: itemSpacing),
            if (isMobile)
              // Mobile: Grid layout like stats (2 columns)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 1.2,
                ),
                itemCount: 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildQuickActionCard(
                      'Add Todo',
                      Icons.add_task_rounded,
                      Colors.blue,
                      () async {
                        final result = await Navigator.of(context).push<Todo>(
                          MaterialPageRoute(
                            builder: (context) => const AddTodoScreen(),
                          ),
                        );

                        if (result != null) {
                          try {
                            await ApiService.createTodo(result);
                            if (mounted) {
                              _loadStats();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Todo added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding todo: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    );
                  } else {
                    return _buildQuickActionCard(
                      'Add Note',
                      Icons.note_add_rounded,
                      Colors.purple,
                      () async {
                        final result = await Navigator.of(context).push<Note>(
                          MaterialPageRoute(
                            builder: (context) => const AddNoteScreen(),
                          ),
                        );

                        if (result != null) {
                          try {
                            await NotesApiService.createNote(result);
                            if (mounted) {
                              _loadStats();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Note added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding note: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    );
                  }
                },
              )
            else
              // Tablet & Desktop: Horizontal layout
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Add Todo',
                      Icons.add_task_rounded,
                      Colors.blue,
                      () async {
                        final result = await Navigator.of(context).push<Todo>(
                          MaterialPageRoute(
                            builder: (context) => const AddTodoScreen(),
                          ),
                        );

                        if (result != null) {
                          try {
                            await ApiService.createTodo(result);
                            if (mounted) {
                              _loadStats();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Todo added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding todo: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                  SizedBox(width: itemSpacing),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Add Note',
                      Icons.note_add_rounded,
                      Colors.purple,
                      () async {
                        final result = await Navigator.of(context).push<Note>(
                          MaterialPageRoute(
                            builder: (context) => const AddNoteScreen(),
                          ),
                        );

                        if (result != null) {
                          try {
                            await NotesApiService.createNote(result);
                            if (mounted) {
                              _loadStats();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Note added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding note: $e'),
                                  backgroundColor: Colors.red,
                                ),
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
      },
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
        final cardPadding = EdgeInsets.all(isMobile ? 8 : 16);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: cardPadding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 20),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                  ),
                  child: Icon(icon, color: color, size: isMobile ? 20 : 32),
                ),
                SizedBox(height: isMobile ? 6 : 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: isMobile
                        ? 12
                        : ResponsiveBreakpoints.getTitleFontSize(screenWidth) *
                              0.9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with expand/collapse button
        GestureDetector(
          onTap: () {
            setState(() {
              _isActivitiesExpanded = !_isActivitiesExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isActivitiesExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Content (expandable)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isActivitiesExpanded
              ? _buildActivitiesContent()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildActivitiesContent() {
    if (_recentActivities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surfaceContainerHighest,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activity yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding todos and notes to see your activity here',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentActivities.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        itemBuilder: (context, index) {
          final activity = _recentActivities[index];
          return _buildActivityItem(activity);
        },
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final isTodo = activity['type'] == 'todo';
    final color = activity['color'] as Color;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(activity['icon'] as IconData, color: color, size: 22),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              activity['title'] as String,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isTodo ? 'Todo' : 'Note',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity['description'] != null &&
              (activity['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              activity['description'] as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatDate(activity['createdAt'] as DateTime),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
      onTap: () {
        // Optional: Add navigation to item details
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildRecentDeleted() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with expand/collapse button
        GestureDetector(
          onTap: () {
            setState(() {
              _isDeletedExpanded = !_isDeletedExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Recently Deleted',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isDeletedExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Content (expandable)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isDeletedExpanded
              ? _buildDeletedContent()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDeletedContent() {
    if (_recentDeleted.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surfaceContainerHighest,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.restore_from_trash_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No recently deleted items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deleted items will appear here for recovery',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentDeleted.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        itemBuilder: (context, index) {
          final deletedItem = _recentDeleted[index];
          return _buildDeletedItem(deletedItem);
        },
      ),
    );
  }

  Widget _buildDeletedItem(Map<String, dynamic> deletedItem) {
    final isTodo = deletedItem['type'] == 'todo';
    final color = deletedItem['color'] as Color;
    final deletedAt = deletedItem['deletedAt'] as DateTime;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isTodo ? Icons.task_alt_rounded : Icons.description_rounded,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        deletedItem['title'],
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Deleted ${_formatDeletedTime(deletedAt)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.restore,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            onPressed: () {
              // TODO: Implement restore functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Restore ${isTodo ? 'todo' : 'note'}: ${deletedItem['title']}',
                  ),
                ),
              );
            },
            tooltip: 'Restore',
          ),
          IconButton(
            icon: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _recentDeleted.removeAt(_recentDeleted.indexOf(deletedItem));
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item permanently deleted')),
              );
            },
            tooltip: 'Delete Forever',
          ),
        ],
      ),
    );
  }

  String _formatDeletedTime(DateTime deletedAt) {
    final now = DateTime.now();
    final difference = now.difference(deletedAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${deletedAt.day}/${deletedAt.month}/${deletedAt.year}';
    }
  }
}
