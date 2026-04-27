import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/report_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('parkir_its.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE reports (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      imagePath TEXT NOT NULL,
      caption TEXT NOT NULL,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      timestamp TEXT NOT NULL
    )
    ''');
  }

  // create: new report
  Future<int> insertReport(Report report) async {
    final db = await instance.database;
    return await db.insert('reports', report.toMap());
  }

  // read: get all reports, ordered by newest first
  Future<List<Report>> getAllReports() async {
    final db = await instance.database;
    final maps = await db.query('reports', orderBy: 'timestamp DESC');

    // convert the list of maps back into a list of report objects
    return List.generate(maps.length, (i) {
      return Report(
        id: maps[i]['id'] as int,
        imagePath: maps[i]['imagePath'] as String,
        caption: maps[i]['caption'] as String,
        latitude: maps[i]['latitude'] as double,
        longitude: maps[i]['longitude'] as double,
        timestamp: maps[i]['timestamp'] as String,
      );
    });
  }

  // delete: remove a report by its id
  Future<int> deleteReport(int id) async {
    final db = await instance.database;
    return await db.delete('reports', where: 'id = ?', whereArgs: [id]);
  }
}