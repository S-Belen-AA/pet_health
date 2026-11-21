import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Instancia única (Singleton)
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'pet_health.db';
  static const int _dbVersion = 3;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Habilita integridad referencial (ON DELETE CASCADE) en SQLite
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabla de Mascotas (snake_case consistente con PetModel.toMap())
    await db.execute('''
      CREATE TABLE pets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        breed TEXT NOT NULL,
        is_quiltro INTEGER NOT NULL,
        size TEXT NOT NULL,
        coat_length TEXT,
        morph_emoji TEXT NOT NULL,
        weight REAL NOT NULL,
        age INTEGER NOT NULL,
        birth_date TEXT,
        activity_level TEXT NOT NULL,
        body_condition TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Tabla del Catálogo de Vacunas base
    await db.execute('''
      CREATE TABLE vaccines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        validity_months INTEGER NOT NULL
      )
    ''');

    // 3. Tabla de Vacunas Aplicadas a cada mascota
    await db.execute('''
      CREATE TABLE pet_vaccines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        vaccine_id INTEGER NOT NULL,
        date_applied TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE,
        FOREIGN KEY (vaccine_id) REFERENCES vaccines (id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabla de Controles Médicos (pasados y próximos)
    await db.execute('''
      CREATE TABLE medical_checkups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        checkup_date TEXT NOT NULL,
        reason TEXT NOT NULL,
        vet_or_notes TEXT,
        is_upcoming INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
      )
    ''');

    // 5. Tabla de Desparasitaciones (interna / externa)
    await db.execute('''
      CREATE TABLE dewormings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        product_name TEXT NOT NULL,
        date_applied TEXT NOT NULL,
        validity_days INTEGER NOT NULL,
        next_due_date TEXT NOT NULL,
        FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
      )
    ''');

    // Índices para acelerar consultas por mascota
    await db.execute('CREATE INDEX idx_pet_vaccines_pet_id ON pet_vaccines(pet_id)');
    await db.execute('CREATE INDEX idx_pet_vaccines_vaccine_id ON pet_vaccines(vaccine_id)');
    await db.execute('CREATE INDEX idx_medical_checkups_pet_id ON medical_checkups(pet_id)');
    await db.execute('CREATE INDEX idx_dewormings_pet_id ON dewormings(pet_id)');

    // 6. Datos iniciales de vacunas por defecto para Chile
    await _seedDefaultVaccines(db);
  }

  Future<void> _seedDefaultVaccines(Database db) async {
    final existing = await db.rawQuery('SELECT COUNT(*) as total FROM vaccines');
    final count = Sqflite.firstIntValue(existing) ?? 0;
    if (count > 0) return;

    final batch = db.batch();
    batch.insert('vaccines', {
      'name': 'Óctuple / Séxtuple (Canina)',
      'species': 'Perro',
      'validity_months': 12,
    });
    batch.insert('vaccines', {
      'name': 'Antirrábica',
      'species': 'Ambos',
      'validity_months': 12,
    });
    batch.insert('vaccines', {
      'name': 'Triple Felina',
      'species': 'Gato',
      'validity_months': 12,
    });
    batch.insert('vaccines', {
      'name': 'Leucemia Felina',
      'species': 'Gato',
      'validity_months': 12,
    });
    await batch.commit(noResult: true);
  }

  Future<bool> _columnExists(Database db, String table, String column) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    return columns.any((col) => col['name'] == column);
  }

  // Migración progresiva y segura entre versiones
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final hasCreatedAt = await _columnExists(db, 'pets', 'created_at');
      if (!hasCreatedAt) {
        await db.execute(
          "ALTER TABLE pets ADD COLUMN created_at TEXT NOT NULL DEFAULT ''",
        );
      }
      await _seedDefaultVaccines(db);
    }

    if (oldVersion < 3) {
      final hasBirthDate = await _columnExists(db, 'pets', 'birth_date');
      if (!hasBirthDate) {
        await db.execute('ALTER TABLE pets ADD COLUMN birth_date TEXT');
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS medical_checkups(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pet_id INTEGER NOT NULL,
          checkup_date TEXT NOT NULL,
          reason TEXT NOT NULL,
          vet_or_notes TEXT,
          is_upcoming INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS dewormings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pet_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          product_name TEXT NOT NULL,
          date_applied TEXT NOT NULL,
          validity_days INTEGER NOT NULL,
          next_due_date TEXT NOT NULL,
          FOREIGN KEY (pet_id) REFERENCES pets (id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_medical_checkups_pet_id ON medical_checkups(pet_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_dewormings_pet_id ON dewormings(pet_id)',
      );
    }
  }
}