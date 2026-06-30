import 'package:flutter/material.dart';

/// add_custom_subtask_row.dart
/// Shared "Add custom sub-task" expandable input row.
/// Used in both onboarding (SubtaskSetupScreen) and AddHabitScreen.
class AddCustomSubtaskRow extends StatefulWidget {
  const AddCustomSubtaskRow({
    super.key,
    required this.color,
    required this.onAdd,
  });

  final Color color;
  final ValueChanged<String> onAdd;

  @override
  State<AddCustomSubtaskRow> createState() => _AddCustomSubtaskRowState();
}

class _AddCustomSubtaskRowState extends State<AddCustomSubtaskRow> {
  bool _expanded = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return GestureDetector(
        onTap: () => setState(() => _expanded = true),
        child: Container(
          margin: const EdgeInsets.only(top: 4, bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            border: Border.all(color: widget.color.withOpacity(0.2), width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 20, color: widget.color),
              const SizedBox(width: 8),
              Text(
                'Add custom sub-task',
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.color),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. Read 20 pages',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          IconButton(
            onPressed: _submit,
            icon: Icon(Icons.check, color: widget.color),
          ),
        ],
      ),
    );
  }
}