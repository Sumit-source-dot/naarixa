import 'package:flutter/material.dart';

import 'section_header.dart';

class TaskItem {
  final String label;
  final bool done;

  const TaskItem({required this.label, required this.done});
}

class TasksChecklist extends StatelessWidget {
  final List<TaskItem> tasks;

  const TasksChecklist({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final pending = tasks.where((t) => !t.done).toList();
    final done = tasks.where((t) => t.done).toList();
    final colorScheme = Theme.of(context).colorScheme;
    final shadowColor = Theme.of(context).shadowColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SectionHeader(title: 'To-Do', actionLabel: 'Add task'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withOpacity(0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                ...pending.map((t) => _TaskRow(task: t)),
                if (done.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                    child: Divider(color: colorScheme.outlineVariant),
                  ),
                ...done.map((t) => _TaskRow(task: t)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskItem task;

  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: task.done ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: task.done
                  ? null
                  : Border.all(color: colorScheme.outlineVariant, width: 1.5),
            ),
            child: task.done
                ? Icon(Icons.check, color: colorScheme.onPrimary, size: 13)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: task.done ? FontWeight.w400 : FontWeight.w600,
                color: task.done ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                decoration:
                    task.done ? TextDecoration.lineThrough : TextDecoration.none,
                decorationColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
