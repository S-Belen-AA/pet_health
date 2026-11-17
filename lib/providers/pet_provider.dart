import 'package:flutter/material.dart';
import 'package:pet_health/database/database_helper.dart';
import 'package:pet_health/models/pet_model.dart';

class PetProvider extends ChangeNotifier {
  List<PetModel> _pets = [];
  List<PetModel> get pets => _pets;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Cargar todas las mascotas desde SQLite
  Future<void> loadPets() async {
    final db = await _dbHelper.database;
    // Usamos 'var' para que Dart infiera el tipo automáticamente y evitemos problemas de símbolos
    final maps = await db.query('pets', orderBy: 'id DESC');
    
    _pets = maps.map((map) => PetModel.fromMap(map)).toList();
    notifyListeners(); // Notifica a la interfaz para que se redibuje
  }

  // Insertar una nueva mascota en SQLite
  Future<void> addPet(PetModel pet) async {
    final db = await _dbHelper.database;
    await db.insert('pets', pet.toMap());
    await loadPets(); // Recargamos la lista automáticamente
  }

  // Eliminar una mascota por ID
  Future<void> deletePet(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'pets',
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadPets();
  }
}