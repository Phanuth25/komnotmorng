import 'package:flutter/material.dart';

/// Colors for task states, kept in the theme so light and dark both work.
/// Use: Theme.of(context).extension<TaskColors>()!
@immutable
class TaskColors extends ThemeExtension<TaskColors> {
  final Color done;
  final Color doing;
  final Color todo;

  const TaskColors({
    required this.done,
    required this.doing,
    required this.todo,
  });

  static const light = TaskColors(
    done: Color(0xFF9FE0B8),
    doing: Color(0xFF6C7CF0),
    todo: Color(0xFFE3E4EA),
  );

  static const dark = TaskColors(
    done: Color(0xFF5DBB86),
    doing: Color(0xFF8E9BFF),
    todo: Color(0xFF444857),
  );

  @override
  TaskColors copyWith({Color? done, Color? doing, Color? todo}) => TaskColors(
    done: done ?? this.done,
    doing: doing ?? this.doing,
    todo: todo ?? this.todo,
  );

  @override
  TaskColors lerp(ThemeExtension<TaskColors>? other, double t) {
    if (other is! TaskColors) return this;
    return TaskColors(
      done: Color.lerp(done, other.done, t)!,
      doing: Color.lerp(doing, other.doing, t)!,
      todo: Color.lerp(todo, other.todo, t)!,
    );
  }
}