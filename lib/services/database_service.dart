import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/schedule_model.dart';
// Ensure this import exists if we use Reminder class internally

/// ROLE: Backend Engine - Manages all SQLite persistent storage.
/// DESIGN CHOICE: Singleton pattern used to ensure a single DB connection.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  // Getter for the database connection
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('water_collection.db');
    return _database!;
  }

  // Initializes the local file on the device
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Bumped version for migration
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      // CRITICAL: Enables Foreign Keys for Parent-Child relationships
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  /// ROLE: Defines the "Parent-Child" table structure.
  Future _createDB(Database db, int version) async {
    // Parent Table: Stores the collection day and main notes
    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        collection_date TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        notes TEXT,
        selected_days TEXT NOT NULL
      )
    ''');

    // Child Table: Stores multiple alarm times linked to one schedule
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schedule_id INTEGER NOT NULL,
        reminder_time TEXT NOT NULL,
        FOREIGN KEY (schedule_id) REFERENCES schedules (id) ON DELETE CASCADE
      )
    ''');
  }

  // Handle Schema Migrations
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE schedules ADD COLUMN selected_days TEXT DEFAULT ''");
    }
  }

  // --- CRUD OPERATIONS ---

  /// ROLE: Fetches ALL schedules and populates their reminder times.
  /// Used for the Reminder List Screen.
  Future<List<Schedule>> getAllSchedules() async {
    final db = await instance.database;
    
    // 1. Fetch all parent schedules
    final scheduleMaps = await db.query('schedules', orderBy: 'collection_date ASC');
    
    List<Schedule> schedules = [];

    for (var map in scheduleMaps) {
      Schedule schedule = Schedule.fromMap(map);
      
      // 2. Fetch associated reminders for this schedule
      // OPTIMIZATION: Could be done with a JOIN, but for small datasets, this is cleaner to read.
      final reminderMaps = await db.query(
        'reminders',
        where: 'schedule_id = ?',
        whereArgs: [schedule.id],
        orderBy: 'reminder_time ASC'
      );

      // Extract just the time strings
      List<String> times = reminderMaps.map((r) => r['reminder_time'] as String).toList();
      
      // Attach to the object
      schedules.add(schedule.copyWith(reminderTimes: times));
    }

    return schedules;
  }

  /// ROLE: Fetches schedules for a specific month (for Calendar).
  Future<List<Schedule>> getSchedulesForMonth(DateTime month) async {
    final db = await instance.database;
    String prefix = "${month.year}-${month.month.toString().padLeft(2, '0')}";
    
    final result = await db.query(
      'schedules',
      where: 'collection_date LIKE ?',
      whereArgs: ['$prefix%'],
    );

    // Note: We might want reminders here too, but for calendar dots, we might just need dates.
    // For now, let's just return the basic info.
    return result.map((json) => Schedule.fromMap(json)).toList();
  }

  /// ROLE: Unique ID Generator substitute (SQLite does this, but we need it for notifications sometimes)
  /// actually, we use the DB ID.

  /// ROLE: Atomic Transaction to save a schedule with its multiple reminders.
  /// Accepts a Schedule object (which might have `reminderTimes` populated).
  Future<int> saveFullSchedule(Schedule schedule) async {
    final db = await instance.database;
    
    return await db.transaction((txn) async {
      int scheduleId;
      
      // 1. Insert or Update Parent
      if (schedule.id != null) {
        await txn.update(
          'schedules',
          schedule.toMap(),
          where: 'id = ?',
          whereArgs: [schedule.id],
        );
        scheduleId = schedule.id!;
        
        // If updating, clear old reminders to replace with new ones (simplest approach)
        await txn.delete('reminders', where: 'schedule_id = ?', whereArgs: [scheduleId]);
      } else {
        scheduleId = await txn.insert('schedules', schedule.toMap());
      }

      // 2. Save all associated Child Reminders
      for (String time in schedule.reminderTimes) {
        await txn.insert('reminders', {
          'schedule_id': scheduleId,
          'reminder_time': time,
        });
      }
      
      return scheduleId;
    });
  }

  /// ROLE: Deletes a schedule and its cascades (reminders).
  Future<void> deleteSchedule(int id) async {
    final db = await instance.database;
    await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ROLE: Toggles the active state of a schedule.
  Future<void> toggleScheduleActive(int id, bool isActive) async {
    final db = await instance.database;
    await db.update(
      'schedules',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}