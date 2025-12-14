import 'package:intl/intl.dart';

class CourseDiscountOffer {
  final String targetCourseId;
  final String targetCourseTitle;
  final String targetCourseImageUrl;
  final int targetCoursePrice;
  final int discountType;
  final int discountValue;
  final int discountAmount;
  final int discountedPrice;
  final DateTime startDate;
  final DateTime endDate;

  CourseDiscountOffer({
    required this.targetCourseId,
    required this.targetCourseTitle,
    required this.targetCourseImageUrl,
    required this.targetCoursePrice,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.discountedPrice,
    required this.startDate,
    required this.endDate,
  });

  factory CourseDiscountOffer.fromJson(Map<String, dynamic> json) {
    return CourseDiscountOffer(
      targetCourseId: json['targetCourseId'] ?? '',
      targetCourseTitle: json['targetCourseTitle'] ?? '',
      targetCourseImageUrl: json['targetCourseImageUrl'] ?? '',
      targetCoursePrice: (json['targetCoursePrice'] as num?)?.toInt() ?? 0,
      discountType: (json['discountType'] as num?)?.toInt() ?? 0,
      discountValue: (json['discountValue'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      discountedPrice: (json['discountedPrice'] as num?)?.toInt() ??
          (json['targetCoursePrice'] as num?)?.toInt() ??
          0,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }

  String formatCurrency(int value) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(value)} VNĐ';
  }

  String get formattedOriginalPrice => formatCurrency(targetCoursePrice);
  String get formattedDiscountedPrice => formatCurrency(discountedPrice);
  String get formattedDiscountAmount => formatCurrency(discountAmount);
}

