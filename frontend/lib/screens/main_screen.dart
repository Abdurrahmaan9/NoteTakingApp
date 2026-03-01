import 'package:flutter/material.dart';
import '../widgets/floating_navigation_bar.dart';
import 'todo_list_screen.dart';
import 'notes_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                HomeScreen(
                  onNavigateToTodos: () => _navigateToTab(1),
                  onNavigateToNotes: () => _navigateToTab(2),
                ),
                const TodoListScreen(),
                const NotesScreen(),
              ],
            ),
            FloatingNavigationBar(
              currentIndex: _currentIndex,
              onTabSelected: _navigateToTab,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
