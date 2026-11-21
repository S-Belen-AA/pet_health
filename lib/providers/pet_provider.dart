import 'package:flutter/material.dart';
import 'package:pet_health/database/database_helper.dart';
import 'package:pet_health/models/pet_model.dart';

class PetProvider extends ChangeNotifier {
  List<PetModel> _pets = [];
  List<PetModel> get pets => _pets;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> loadPets() async {
    final db = await _dbHelper.database;
    final maps = await db.query('pets', orderBy: 'id DESC');

    _pets = maps.map((map) => PetModel.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> addPet(PetModel pet) async {
    final db = await _dbHelper.database;
    await db.insert('pets', pet.toMap());
    await loadPets();
  }

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