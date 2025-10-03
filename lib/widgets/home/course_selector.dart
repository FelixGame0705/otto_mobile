import 'package:flutter/material.dart';
import 'package:ottobit/models/enrollment_model.dart';

class CourseSelector extends StatelessWidget {
  final List<Enrollment> enrollments;
  final String? selectedCourseId;
  final void Function(Enrollment) onSelect;

  const CourseSelector({
    super.key,
    required this.enrollments,
    required this.selectedCourseId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (enrollments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.school, color: Colors.orange),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Bạn chưa đăng ký khóa học nào. Hãy khám phá và đăng ký!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Khám phá khóa học'),
            ),
          ],
        ),
      );
    }

    final String current = selectedCourseId ?? (enrollments.isNotEmpty ? enrollments.first.courseId : '');

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: enrollments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final e = enrollments[index];
          final bool selected = e.courseId == current;
          return _CourseChip(
            enrollment: e,
            selected: selected,
            onTap: () => onSelect(e),
          );
        },
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final int progress;
  const _ProgressChip({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.green),
      ),
      child: Text('$progress%'),
    );
  }
}

class _CourseChip extends StatelessWidget {
  final Enrollment enrollment;
  final bool selected;
  final VoidCallback onTap;

  const _CourseChip({required this.enrollment, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color base = selected ? const Color(0xFF58CC02) : Colors.grey.shade300;
    final Color bg = selected ? const Color(0xFFECFFDC) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: base.withOpacity(0.9), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
            BoxShadow(color: Colors.white.withOpacity(0.9), blurRadius: 2, offset: const Offset(-1, -1)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CylinderAvatar(imageUrl: enrollment.courseImageUrl, color: base),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enrollment.courseTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: selected ? const Color(0xFF2D6A00) : Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  _ProgressChip(progress: enrollment.progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CylinderAvatar extends StatelessWidget {
  final String imageUrl;
  final Color color;
  const _CylinderAvatar({required this.imageUrl, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Base shadow ellipse
        Positioned(
          bottom: 0,
          child: Container(
            width: 28,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // Cylinder circle with strong top highlight and bottom shadow
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withOpacity(0.15)],
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4)),
              BoxShadow(color: Colors.white.withOpacity(0.9), blurRadius: 2, offset: const Offset(-1, -1)),
            ],
            border: Border.all(color: color, width: 1.5),
            image: imageUrl.isNotEmpty
                ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                : null,
          ),
          child: imageUrl.isEmpty
              ? Icon(Icons.menu_book, size: 18, color: color)
              : null,
        ),
      ],
    );
  }
}


