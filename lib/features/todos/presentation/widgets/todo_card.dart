import 'package:flutter/material.dart';
import '../../../../core/models/todo.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;
  final Function(int) onToggleComplete;
  final Function(Todo) onEdit;
  final Function(int) onDelete;
  final bool showDragHandle;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    this.showDragHandle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _getPriorityColor(),
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => onToggleComplete(todo.id),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: todo.completionStatus.isCompleted
                                ? const Color(0xFF52D681)
                                : Colors.grey[400]!,
                            width: 2,
                          ),
                          color: todo.completionStatus.isCompleted
                              ? const Color(0xFF52D681)
                              : Colors.transparent,
                        ),
                        child: todo.completionStatus.isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        todo.description,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: todo.completionStatus.isCompleted
                              ? Colors.grey[500]
                              : const Color(0xFF1B4D3E),
                          decoration: todo.completionStatus.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    if (showDragHandle)
                      Icon(
                        Icons.drag_handle,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit(todo);
                            break;
                          case 'delete':
                            onDelete(todo.id);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  ],
                ),
                if (todo.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    todo.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: todo.completionStatus.isCompleted
                          ? Colors.grey[400]
                          : Colors.grey[600],
                      decoration: todo.completionStatus.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (todo.priority != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          todo.priority!.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getPriorityColor(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (todo.dateInfo.date != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDueDateColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: _getDueDateColor(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDueDate(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _getDueDateColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFF52D681),
                      child: Text(
                        todo.user.name.isNotEmpty
                            ? todo.user.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    if (todo.priority == null) return Colors.grey;

    switch (todo.priority!.name.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getDueDateColor() {
    if (todo.dateInfo.isOverdue) {
      return Colors.red; // Overdue
    } else if (todo.dateInfo.isToday) {
      return Colors.orange; // Due today
    } else {
      return Colors.green; // Not urgent
    }
  }

  String _formatDueDate() {
    if (todo.dateInfo.date == null) return '';

    if (todo.dateInfo.isOverdue) {
      return 'Overdue';
    } else if (todo.dateInfo.isToday) {
      return 'Today';
    } else if (todo.dateInfo.formattedDate != null) {
      return todo.dateInfo.formattedDate!;
    } else {
      return todo.dateInfo.date!;
    }
  }
}
