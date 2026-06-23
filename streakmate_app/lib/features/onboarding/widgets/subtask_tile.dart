import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// subtask_tile.dart
/// Matches the "Warm-up / 10 min" row style — icon badge, name + meta
/// subtitle, toggle/checkmark on the right.
class SubtaskTile extends StatelessWidget {
  const SubtaskTile({
    super.key,
    required this.icon,
    required this.name,
    required this.metaLabel,
    required this.enabled,
    required this.color,
    required this.onToggle,
    this.isOptionalLabel = false,
  });

  final String icon;
  final String name;
  final String metaLabel;
  final bool enabled;
  final Color color;
  final VoidCallback onToggle;
  final bool isOptionalLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 17))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.lightCardTitle),
                Text(
                  metaLabel,
                  style: AppTextStyles.lightCardSubtitle.copyWith(
                    color: isOptionalLabel ? AppColors.lightTextSecondary : AppColors.lightTextSecondary,
                    fontStyle: isOptionalLabel ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? color : Colors.transparent,
                border: Border.all(color: enabled ? color : AppColors.lightCardBorder, width: 1.4),
              ),
              child: enabled ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.drag_indicator, size: 18, color: AppColors.lightTextSecondary.withOpacity(0.5)),
        ],
      ),
    );
  }
}
