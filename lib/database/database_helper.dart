import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // 1. Patrón Singleton: Instancia única privada
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // 2. Getter perezoso (Lazy getter) para obtener la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 3. Inicialización del archivo de base de datos en el dispositivo
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pet_health.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // 4. Creación de las tablas relacionales la primera vez que se instala la app
  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabla de Mascotas
    await db.execute('''
      CREATE TABLE pets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        breed TEXT,
        is_quiltro INTEGER,
        size TEXT,
        coat_length TEXT,
        morph_emoji TEXT,
        weight REAL NOT NULL,
        age INTEGER NOT NULL,
        activity_level TEXT,
        body_condition TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Tabla del Catálogo de Vacunas Chilenas
    await db.execute('''
      CREATE TABLE vaccines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        validity_months INTEGER NOT NULL
      )
    ''');

    // 3. Tabla del Historial de Vacunación Aplicadas
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

    // --- PRECARGA DE VACUNAS CHILENAS (SEED DATA) ---
    // Vacunas para Perros
    await db.insert('vaccines', {'name': 'Séxtuple (DHPPi+L)', 'species': 'Perro', 'validity_months': 12});
    await db.insert('vaccines', {'name': 'Antirrábica', 'species': 'Ambos', 'validity_months': 12});
    await db.insert('vaccines', {'name': 'Tos de las Perreras (Bordetella)', 'species': 'Perro', 'validity_months': 12});
    await db.insert('vaccines', {'name': 'Coronavirus Canino', 'species': 'Perro', 'validity_months': 12});

    // Vacunas para Gatos
    await db.insert('vaccines', {'name': 'Triple Felina (FVRCP)', 'species': 'Gato', 'validity_months': 12});
    await db.insert('vaccines', {'name': 'Leucemia Felina (FeLV)', 'species': 'Gato', 'validity_months': 12});
  }