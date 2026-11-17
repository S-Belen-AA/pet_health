import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Instancia única (Singleton)
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Variable estática privada que faltaba y causaba el error
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pet_health.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabla de Mascotas
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
        activity_level TEXT NOT NULL,
        body_condition TEXT NOT NULL,
        createdAt TEXT NOT NULL
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

    // Insertar datos iniciales de vacunas por defecto para Chile
    await db.insert('vaccines', {'name': 'Óctuple / Séxtuple (Canina)', 'species': 'Perro', 'validity_months': 12});
    await db.insert('vaccines', {'name': 'Antirrábica', 'species': 'Ambos', 'validity_months': 12});
    await db.insert('vaccines', {'name': 'Triple Felina', 'species': 'Gato', 'validity_months': 12});
    await db.insert('vaccines', {'name': 'Leucemia Felina', 'species': 'Gato', 'validity_months': 12});
  }
}