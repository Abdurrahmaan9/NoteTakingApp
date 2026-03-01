import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
 
class FloatingNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
 
  const FloatingNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });
 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        _buildFloatingNavBar(context),
        _buildNavigationItems(context),
      ],
    );
  }
 
  Widget _buildFloatingNavBar(BuildContext context) {
    final theme = Theme.of(context);
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
 
  Widget _buildNavigationItems(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 20,
      right: 20,
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _navItem(Icons.grid_view_rounded, 0, context),
          _navItem(Icons.task_alt_rounded, 1, context),
          _navItem(Icons.description_rounded, 2, context),
          _navItem(Icons.settings_outlined, 3, context),
        ],
      ),
    );
  }
 
  Widget _navItem(IconData icon, int index, BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = currentIndex == index;
    return ZoomTapAnimation(
      onTap: () => onTabSelected(index),
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