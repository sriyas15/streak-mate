import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// bottom_nav_bar.dart
/// 5-tab nav matching image 2: Home, Journey, + (FAB), Friends, Profile.
/// The centre "+" is a raised FAB-style button, not a regular tab.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.route_rounded,
            label: 'Journey',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          // Centre FAB
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: onAddTap,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF2A33D), Color(0xFFE8762B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.flameOrange.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
          _NavItem(
            icon: Icons.people_rounded,
            label: 'Friends',
            selected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            selected: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppColors.flameOrange : AppColors.darkTextSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
