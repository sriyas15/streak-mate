import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// habit_selection_card.dart
/// Island-style card for habit picker — 3D island PNG fills the card,
/// label pinned to bottom, green checkmark badge top-right when selected.
class HabitSelectionCard extends StatelessWidget {
  const HabitSelectionCard({
    super.key,
    required this.islandAsset, // e.g. 'assets/images/island1.png'
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String islandAsset;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // No background — island PNG floats over bg3 directly
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: selected ? 2.2 : 0,
            ),
          ),
          child: Stack(
            children: [
              // Island image — full card, no padding, transparent bg
              // Island image — full card, no padding, transparent bg
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  // Wrap Image.asset in a Transform.scale
                  child: Transform.scale(
                    scale: 1.25, // <-- Increase this number (1.25 = 25% larger)
                    child: Image.asset(
                      islandAsset,
                      fit: BoxFit.contain, // Keep contain so it scales proportionally
                    ),
                  ),
                ),
              ),

              // Label at bottom — no background, just text + soft shadow
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Text(
                  label,
                  style: AppTextStyles.lightCardTitle.copyWith(
                    fontSize: 13,
                    color: Colors.black,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Checkmark / radio badge top-right
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: selected
                      ? Container(
                          key: const ValueKey('checked'),
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 14, color: Colors.white),
                        )
                      : Container(
                          key: const ValueKey('unchecked'),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.85),
                            border: Border.all(color: AppColors.lightCardBorder, width: 1.4),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}