import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
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
            _buildFloatingNavBar(),
            _buildNavigationItems(),
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

  Widget _buildFloatingNavBar() {
    ThemeData theme = Theme.of(context);
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: theme.scaffoldBackgroundColor),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(35),
            bottomRight: Radius.circular(35),
          ),
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.1),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(35),
            bottomRight: Radius.circular(35),
          ),
          child: ClipPath(
            clipper: MyCustomClipper(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaY: 6, sigmaX: 6),
              child: Container(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItems() {
    return Positioned(
      bottom: 16,
      left: 20,
      right: 20,
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _navItem(Icons.grid_view_rounded, 0),
          _navItem(Icons.task_alt_rounded, 1),
          _navItem(Icons.description_rounded, 2),
          _navItem(Icons.settings_outlined, 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    ThemeData theme = Theme.of(context);
    bool isSelected = _currentIndex == index;
    return ZoomTapAnimation(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          size: 24,
        ),
      ),
    );
  }
}

class MyCustomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(64, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
