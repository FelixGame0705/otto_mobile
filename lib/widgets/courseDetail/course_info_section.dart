import 'package:flutter/material.dart';
import 'package:otto_mobile/models/course_detail_model.dart';

class CourseInfoSection extends StatelessWidget {
  final CourseDetail course;

  const CourseInfoSection({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'Thông tin khóa học',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Course Details
          _buildInfoRow(
            icon: Icons.person,
            label: 'Giảng viên',
            value: course.createdByName,
            color: const Color(0xFF4299E1),
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Ngày tạo',
            value: course.formattedCreatedAt,
            color: const Color(0xFF48BB78),
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.update,
            label: 'Cập nhật lần cuối',
            value: course.formattedUpdatedAt,
            color: const Color(0xFFED8936),
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.play_lesson,
            label: 'Số bài học',
            value: '${course.lessonsCount} bài',
            color: const Color(0xFF9F7AEA),
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.people,
            label: 'Số học viên',
            value: '${course.enrollmentsCount} người',
            color: const Color(0xFF38B2AC),
          ),
          
          const SizedBox(height: 20),
          
          // Description Section
          const Text(
            'Mô tả chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Text(
              course.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A5568),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
