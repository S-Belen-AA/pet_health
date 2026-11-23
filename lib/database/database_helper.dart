import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static const String _dbName = 'pet_health.db';
  static const int _dbVersion = 3;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        sex TEXT,
        breed TEXT,
        is_quiltro INTEGER NOT NULL DEFAULT 0,
        size TEXT,
        coat_length TEXT,
        morph_emoji TEXT,
        weight REAL NOT NULL,
        age INTEGER NOT NULL,
        birth_date TEXT,
        is_birth_date_estimated INTEGER NOT NULL DEFAULT 0,
        activity_level TEXT,
        body_condition TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pet_vaccines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        vaccine_id INTEGER,
        vaccine_name TEXT,
        date_applied TEXT NOT NULL,
        next_due_date TEXT,
        expiry_date TEXT,
        provider_or_clinic TEXT,
        notes TEXT,
        FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dewormings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        date_applied TEXT NOT NULL,
        next_due_date TEXT,
        provider_or_clinic TEXT,
        notes TEXT,
        FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vet_visits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        visit_date TEXT NOT NULL,
        reason TEXT NOT NULL,
        clinic_or_vet TEXT,
        observations TEXT,
        treatment TEXT,
        FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(db, 'pets', 'sex', 'TEXT');
      await _addColumnIfMissing(db, 'pets', 'birth_date', 'TEXT');
      await _addColumnIfMissing(
        db,
        'pets',
        'is_birth_date_estimated',
        'INTEGER NOT NULL DEFAULT 0',
      );

      await db.execute('''
        CREATE TABLE IF NOT EXISTS pet_vaccines(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pet_id INTEGER NOT NULL,
          vaccine_id INTEGER,
          vaccine_name TEXT,
          date_applied TEXT NOT NULL,
          next_due_date TEXT,
          expiry_date TEXT,
          provider_or_clinic TEXT,
          notes TEXT,
          FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS dewormings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pet_id INTEGER NOT NULL,
          product_name TEXT NOT NULL,
          date_applied TEXT NOT NULL,
          next_due_date TEXT,
          provider_or_clinic TEXT,
          notes TEXT,
          FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS vet_visits(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pet_id INTEGER NOT NULL,
          visit_date TEXT NOT NULL,
          reason TEXT NOT NULL,
          clinic_or_vet TEXT,
          observations TEXT,
          treatment TEXT,
          FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      await _addColumnIfMissing(db, 'pets', 'sex', 'TEXT');
      await _addColumnIfMissing(db, 'pets', 'birth_date', 'TEXT');
      await _addColumnIfMissing(
        db,
        'pets',
        'is_birth_date_estimated',
        'INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}