import 'package:flutter/material.dart';
import 'package:ottobit/models/lesson_model.dart';
import 'package:ottobit/models/lesson_resource_model.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/services/lesson_detail_service.dart';

class LearningPath extends StatelessWidget {
  final List<Lesson> lessons;
  final Map<String, List<LessonResourceItem>> lessonResources;
  final String courseId;
  final Set<String>? completedLessonIds;
  final int? currentLessonOrder;

  const LearningPath({
    super.key,
    required this.lessons,
    required this.lessonResources,
    required this.courseId,
    this.completedLessonIds,
    this.currentLessonOrder,
  });

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_empty, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Chưa có bài học trong khóa này',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PathConnectorPainter(
                  count: lessons.length,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final parityLeft = index % 2 == 0; // zig-zag
                final resources = lessonResources[lesson.id] ?? const <LessonResourceItem>[];
                final status = _statusForLesson(lesson);
                final double progress = status == _NodeStatus.completed
                    ? 1.0
                    : (status == _NodeStatus.current ? 0.25 : 0.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (parityLeft)
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _LessonNode(
                              title: lesson.title,
                              order: lesson.order,
                              status: status,
                              color: _palette(index),
                              emoji: _emoji(index),
                              progress: progress,
                              onTap: () async {
                                if (status == _NodeStatus.current) {
                                  try {
                                    await LessonDetailService().startLesson(lesson.id);
                                  } catch (_) {}
                                }
                                if (status == _NodeStatus.current || status == _NodeStatus.completed) {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.challenges,
                                    arguments: {
                                      'lessonId': lesson.id,
                                      'courseId': courseId,
                                      'lessonTitle': lesson.title,
                                      'showBestStars': true,
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: _ResourceColumn(
                            resources: resources,
                            alignRight: false,
                            onTapResource: (r) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.lessonResourceDetail,
                                arguments: {'resourceId': r.id},
                              );
                            },
                          ),
                        ),
                      const SizedBox(width: 16),
                      Container(width: 4, height: 120, color: Colors.transparent),
                      const SizedBox(width: 16),
                      if (parityLeft)
                        Expanded(
                          child: _ResourceColumn(
                            resources: resources,
                            alignRight: true,
                            onTapResource: (r) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.lessonResourceDetail,
                                arguments: {'resourceId': r.id},
                              );
                            },
                          ),
                        )
                      else
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _LessonNode(
                              title: lesson.title,
                              order: lesson.order,
                              status: status,
                              color: _palette(index),
                              emoji: _emoji(index),
                              progress: progress,
                              onTap: () async {
                                if (status == _NodeStatus.current) {
                                  try {
                                    await LessonDetailService().startLesson(lesson.id);
                                  } catch (_) {}
                                }
                                if (status == _NodeStatus.current || status == _NodeStatus.completed) {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.challenges,
                                    arguments: {
                                      'lessonId': lesson.id,
                                      'courseId': courseId,
                                      'lessonTitle': lesson.title,
                                      'showBestStars': true,
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: lessons.length,
            ),
          ],
        );
      },
    );
  }

  _NodeStatus _statusForLesson(Lesson l) {
    if ((completedLessonIds ?? const <String>{}).contains(l.id)) {
      return _NodeStatus.completed;
    }
    if (currentLessonOrder != null) {
      if (l.order == currentLessonOrder) return _NodeStatus.current;
      if (l.order == (currentLessonOrder! + 1)) return _NodeStatus.available;
      if (l.order > (currentLessonOrder! + 1)) return _NodeStatus.locked;
      // lower order but not completed yet
      return _NodeStatus.available;
    }
    // Fallback: first current, second available, rest locked
    if (l.order <= 1) return _NodeStatus.current;
    if (l.order == 2) return _NodeStatus.available;
    return _NodeStatus.locked;
  }

  Color _palette(int i) {
    const colors = [
      Color(0xFF58CC02), // duolingo green
      Color(0xFF1CB0F6),
      Color(0xFFFF4B4B),
      Color(0xFFFFB800),
      Color(0xFFA560E8),
    ];
    return colors[i % colors.length];
  }

  String _emoji(int i) {
    const items = ['😀', '🧠', '🚀', '🎯', '🧩', '📚', '💡'];
    return items[i % items.length];
  }
}

class _ResourceColumn extends StatelessWidget {
  final List<LessonResourceItem> resources;
  final bool alignRight;
  final void Function(LessonResourceItem) onTapResource;

  const _ResourceColumn({
    required this.resources,
    required this.alignRight,
    required this.onTapResource,
  });

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) return const SizedBox(height: 120);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        for (final r in resources.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ResourceNode(
              title: r.title,
              type: r.type,
              onTap: () => onTapResource(r),
              alignRight: alignRight,
            ),
          ),
      ],
    );
  }
}

enum _NodeStatus { locked, current, available, completed, mastered }

class _LessonNode extends StatelessWidget {
  final String title;
  final int order;
  final _NodeStatus status;
  final VoidCallback onTap;
  final Color color;
  final String emoji;
  final double progress;

  const _LessonNode({
    required this.title,
    required this.order,
    required this.status,
    required this.onTap,
    required this.color,
    required this.emoji,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLocked = status == _NodeStatus.locked || status == _NodeStatus.available;
    final bool completed = status == _NodeStatus.completed;
    final bool mastered = status == _NodeStatus.mastered;
    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: isLocked ? 0.5 : 1,
        child: Column(
          children: [
            _AvailablePulse(
              enabled: status == _NodeStatus.current,
              child: _CylinderNode(
                color: color,
                mastered: mastered,
                progress: completed ? 1.0 : progress,
                locked: isLocked,
                child: completed
                    ? const Icon(Icons.check, color: Color(0xFF58CC02), size: 28)
                    : Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              width: 160,
              child: Column(
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  _LessonMeta(order: order, status: status, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonMeta extends StatelessWidget {
  final int order;
  final _NodeStatus status;
  final Color color;

  const _LessonMeta({required this.order, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final String label = status == _NodeStatus.current
        ? 'Hiện tại'
        : (status == _NodeStatus.available
            ? 'Sẵn sàng'
            : (status == _NodeStatus.completed
                ? 'Hoàn thành'
                : (status == _NodeStatus.mastered ? 'Thành thạo' : 'Bị khóa')));
    final IconData icon = status == _NodeStatus.current
        ? Icons.flag
        : (status == _NodeStatus.available
            ? Icons.play_circle
            : (status == _NodeStatus.completed
                ? Icons.check_circle
                : (status == _NodeStatus.mastered ? Icons.emoji_events : Icons.lock)));
    final Color chip = status == _NodeStatus.completed
        ? const Color(0xFF58CC02)
        : (status == _NodeStatus.mastered ? const Color(0xFFFFB800) : color);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: chip.withOpacity(0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: chip),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: chip),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: chip, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text('#$order', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

class _CylinderNode extends StatelessWidget {
  final Color color;
  final Widget child;
  final bool mastered;
  final bool locked;
  final double progress; // 0..1
  const _CylinderNode({required this.color, required this.child, this.mastered = false, this.locked = false, this.progress = 0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base shadow ellipse (3D base)
          Positioned(
            bottom: 2,
            child: Container(
              width: 60,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Main cylinder body
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  color.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4)),
                BoxShadow(color: Colors.white.withOpacity(0.95), blurRadius: 2, offset: const Offset(-1, -1)),
              ],
              border: Border.all(color: color, width: 2),
            ),
            child: Center(child: child),
          ),
          // Progress ring
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ProgressRingPainter(
                  progress: progress.clamp(0.0, 1.0),
                  color: locked ? Colors.grey : color,
                  mastered: mastered,
                ),
              ),
            ),
          ),
          // Mastered glow
          if (mastered)
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFFE082).withOpacity(0.6), blurRadius: 24, spreadRadius: 1),
                ],
              ),
            ),
          // Lock overlay
          if (locked)
            const Positioned(
              bottom: 8,
              right: 12,
              child: Icon(Icons.lock, size: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final bool mastered;
  _ProgressRingPainter({required this.progress, required this.color, required this.mastered});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final background = Paint()
      ..color = (mastered ? const Color(0xFFFFE082) : Colors.grey.withOpacity(0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..shader = SweepGradient(
        colors: [color, color.withOpacity(0.4), color],
      ).createShader(Rect.fromCircle(center: center, radius: 42))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    final rect = Rect.fromCircle(center: center, radius: 42);
    canvas.drawArc(rect, -1.5708, 6.28318, false, background);
    canvas.drawArc(rect, -1.5708, 6.28318 * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.mastered != mastered;
  }
}

class _ResourceNode extends StatelessWidget {
  final String title;
  final int type; // 1 video, 2 document, etc.
  final VoidCallback onTap;
  final bool alignRight;

  const _ResourceNode({
    required this.title,
    required this.type,
    required this.onTap,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    final Color border = Colors.blueAccent;
    final IconData icon = type == 1
        ? Icons.play_circle_fill
        : type == 2
        ? Icons.description
        : Icons.bookmark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: border.withOpacity(0.06),
          border: Border.all(color: border, width: 1.5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(alignRight ? 12 : 2),
            bottomLeft: Radius.circular(alignRight ? 12 : 2),
            topRight: Radius.circular(alignRight ? 2 : 12),
            bottomRight: Radius.circular(alignRight ? 2 : 12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: border, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathConnectorPainter extends CustomPainter {
  final int count;

  _PathConnectorPainter({required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final double colCenterLeft = size.width * 0.25;
    final double colCenterRight = size.width * 0.75;
    final double stepY = 120; // height per row
    final Path path = Path();

    for (int i = 0; i < count - 1; i++) {
      final bool left = i % 2 == 0;
      final double y = 8 + i * (stepY + 16);
      final double nextY = 8 + (i + 1) * (stepY + 16);
      final Offset from = Offset(left ? colCenterLeft : colCenterRight, y + stepY * 0.35);
      final Offset to = Offset(!left ? colCenterLeft : colCenterRight, nextY + stepY * 0.35);
      final double midY = (y + nextY) / 2;
      final Offset c1 = Offset(from.dx, midY);
      final Offset c2 = Offset(to.dx, midY);
      path.moveTo(from.dx, from.dy);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, to.dx, to.dy);

      paint.shader = const LinearGradient(
        colors: [Color(0xFFBBF7D0), Color(0xFFC7D2FE)],
      ).createShader(Rect.fromPoints(from, to));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AvailablePulse extends StatelessWidget {
  final bool enabled;
  final Widget child;
  const _AvailablePulse({required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.05),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, scale, _) => Transform.scale(scale: scale, child: child),
      onEnd: () {},
    );
  }
}


