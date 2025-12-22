/// Utility functions for DateTime parsing and manipulation
class DateTimeUtils {
  /// Parse DateTime string and add 7 hours for UTC+7 timezone offset
  /// 
  /// This is used to convert UTC timestamps from the backend to Vietnam timezone (UTC+7)
  /// 
  /// [dateTimeString] - ISO 8601 formatted date time string (e.g., "2025-12-22T10:30:00Z")
  /// 
  /// Returns [DateTime] with 7 hours added, or [DateTime.now()] if parsing fails
  static DateTime parseDateTimeWithOffset(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return dateTime.add(const Duration(hours: 7));
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Parse DateTime from dynamic value (handles String, int, or null)
  /// 
  /// [value] - Can be a String (ISO 8601), int (timestamp), or null
  /// 
  /// Returns [DateTime] converted to local timezone using toLocal(), or [DateTime.now()] if parsing fails
  static DateTime parseDateTimeWithOffsetFromDynamic(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
    
    if (value is int) {
      try {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(value);
        return dateTime.toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
    
    // Try to convert to string and parse
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }
}

