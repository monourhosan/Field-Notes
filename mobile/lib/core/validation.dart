class RecordValidation {
  static void text(
    String? value,
    String field,
    int maximum, {
    bool required = false,
  }) {
    if (required && (value == null || value.trim().isEmpty)) {
      throw ArgumentError('$field is required');
    }
    if (value != null && value.length > maximum) {
      throw ArgumentError('$field must have at most $maximum characters');
    }
  }

  static void inspectionDate(DateTime? value) {
    if (value != null &&
        (value.toUtc().year < 1000 || value.toUtc().year > 9999)) {
      throw ArgumentError(
        'Inspection date must be between years 1000 and 9999 UTC',
      );
    }
  }

  static void note(
    String title,
    String? description,
    String? location,
    String status,
    String? photo,
  ) {
    text(title, 'Title', 255, required: true);
    text(description, 'Description', 16000);
    text(location, 'Location', 255);
    text(photo, 'Photo', 2000000);
    if (!['DRAFT', 'IN_PROGRESS', 'COMPLETED', 'PENDING'].contains(status)) {
      throw ArgumentError('Invalid note status');
    }
  }
}
