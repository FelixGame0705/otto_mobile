import 'package:intl/intl.dart';

class CourseAvailableDiscount {
  final String requiredCourseId;
  final String requiredCourseTitle;
  final String requiredCourseImageUrl;
  final int requiredCoursePrice;
  final int discountType;
  final int discountValue;
  final int discountAmount;
  final int discountedPrice;
  final int originalPrice;
  final bool userOwnsRequiredCourse;
  final bool userEnrolledRequiredCourse;
  final bool requiredCourseInCart;
  final DateTime startDate;
  final DateTime endDate;

  CourseAvailableDiscount({
    required this.requiredCourseId,
    required this.requiredCourseTitle,
    required this.requiredCourseImageUrl,
    required this.requiredCoursePrice,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.discountedPrice,
    required this.originalPrice,
    required this.userOwnsRequiredCourse,
    required this.userEnrolledRequiredCourse,
    required this.requiredCourseInCart,
    required this.startDate,
    required this.endDate,
  });

  factory CourseAvailableDiscount.fromJson(Map<String, dynamic> json) {
    return CourseAvailableDiscount(
      requiredCourseId: json['requiredCourseId'] ?? '',
      requiredCourseTitle: json['requiredCourseTitle'] ?? '',
      requiredCourseImageUrl: json['requiredCourseImageUrl'] ?? '',
      requiredCoursePrice: (json['requiredCoursePrice'] as num?)?.toInt() ?? 0,
      discountType: (json['discountType'] as num?)?.toInt() ?? 0,
      discountValue: (json['discountValue'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      discountedPrice: (json['discountedPrice'] as num?)?.toInt() ?? 0,
      originalPrice: (json['originalPrice'] as num?)?.toInt() ??
          (json['requiredCoursePrice'] as num?)?.toInt() ??
          0,
      userOwnsRequiredCourse: json['userOwnsRequiredCourse'] ?? false,
      userEnrolledRequiredCourse: json['userEnrolledRequiredCourse'] ?? false,
      requiredCourseInCart: json['requiredCourseInCart'] ?? false,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }

  String _fmt(int value) => NumberFormat('#,###', 'vi_VN').format(value);

  String get formattedOriginalPrice => '${_fmt(originalPrice)} VNĐ';
  String get formattedDiscountedPrice => '${_fmt(discountedPrice)} VNĐ';
  String get formattedDiscountAmount => '${_fmt(discountAmount)} VNĐ';
}

