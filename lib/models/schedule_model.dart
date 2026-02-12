/// ROLE: Represents the parent 'Schedule' entry for water collection.
class Schedule {
  final int? id;
  final String title;
  final String collectionDate; // Format: YYYY-MM-DD
  final int isActive; // 1 for active, 0 for inactive
  final String? notes;
  final String selectedDays; // e.g. "Mon, Wed, Fri" or "1,3,5"

  // ROLE: UI Helper - Holds the list of reminder times (strings like "HH:mm") associated with this schedule.
  // Not directly stored in the 'schedules' table, but populated via joins or separate queries.
  final List<String> reminderTimes; 

  Schedule({
    this.id,
    required this.title,
    required this.collectionDate,
    this.isActive = 1,
    this.notes,
    required this.selectedDays, // New required field
    this.reminderTimes = const [],
  });

  // Converts a Schedule object into a Map for SQLite insertion.
  // NOTE: 'reminderTimes' is NOT included here as it resides in a child table.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'collection_date': collectionDate,
      'is_active': isActive,
      'notes': notes,
      'selected_days': selectedDays, // Save to DB
    };
  }

  // Creates a Schedule object from a database Map.
  // NOTE: This usually only populates the parent fields. Reminders must be attached separately.
  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      title: map['title'],
      collectionDate: map['collection_date'],
      isActive: map['is_active'] ?? 1,
      notes: map['notes'],
      selectedDays: map['selected_days'] ?? '', // Load from DB
      // We don't populate reminderTimes here from a simple SELECT * FROM schedules.
      // passing empty list by default.
      reminderTimes: [], 
    );
  }

  // Helper to create a copy of the schedule with new data (e.g. attaching reminders)
  Schedule copyWith({
    int? id,
    String? title,
    String? collectionDate,
    int? isActive,
    String? notes,
    String? selectedDays,
    List<String>? reminderTimes,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      collectionDate: collectionDate ?? this.collectionDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      selectedDays: selectedDays ?? this.selectedDays,
      reminderTimes: reminderTimes ?? this.reminderTimes,
    );
  }
}
  