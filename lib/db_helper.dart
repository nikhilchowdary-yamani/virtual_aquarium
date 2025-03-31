import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'aquarium.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY, fishCount INTEGER, speed REAL, color INTEGER, collisionEnabled INTEGER)',
        );
      },
    );
  }

  Future<void> saveSettings(int fishCount, double speed, int color, bool collisionEnabled) async {
    final db = await database;
    
    // Delete any existing settings
    await db.delete('settings');
    
    // Insert new settings
    await db.insert(
      'settings',
      {
        'id': 1,
        'fishCount': fishCount,
        'speed': speed,
        'color': color,
        'collisionEnabled': collisionEnabled ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> loadSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('settings');
    
    if (maps.isNotEmpty) {
      return maps.first;
    }
    
    return null;
  }
}