import 'package:flutter/material.dart';
import 'package:pet_health/database/database_helper.dart';
import 'package:pet_health/models/vaccine_model.dart';

class AppliedVaccineModel {
  final int id;
  final int petId;
  final int vaccineId;
  final String vaccineName;
  final String dateApplied;
  final String expiryDate;
  final String status; // 'Activa' o 'Pendiente'

  AppliedVaccineModel({
    required this.id,
    required this.petId,
    required this.vaccineId,
    required this.vaccineName,
    required this.dateApplied,
    required this.expiryDate,
    required this.status,
  });

  factory AppliedVaccineModel.fromMap(Map<String, dynamic> map) {
    // Cálculo dinámico del estado comparando la fecha de vencimiento con hoy
    final expiry = DateTime.parse(map['expiry_date']);
    final now = DateTime.now();
    final computedStatus = expiry.isAfter(now) ? 'Activa' : 'Pendiente';

    return AppliedVaccineModel(
      id: map['id'],
      petId: map['pet_id'],
      vaccineId: map['vaccine_id'],
      vaccineName: map['vaccine_name'],
      dateApplied: map['date_applied'],
      expiryDate: map['expiry_date'],
      status: computedStatus,
    );
  }
}

class VaccineProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<VaccineModel> _catalogVaccines = [];
  List<AppliedVaccineModel> _petVaccines = [];

  List<VaccineModel> get catalogVaccines => _catalogVaccines;
  List<AppliedVaccineModel> get petVaccines => _petVaccines;

  // 1. Cargar el catálogo general de vacunas filtrado por especie
  Future<void> loadCatalogForSpecies(String species) async {
    final db = await _dbHelper.database;
    // Usamos 'var' para evitar problemas con los símbolos de mayor/menor
    final maps = await db.query(
      'vaccines',
      where: 'species = ? OR species = ?',
      whereArgs: [species, 'Ambos'],
    );
    _catalogVaccines = maps.map((m) => VaccineModel.fromMap(m)).toList();
    notifyListeners();
  }

  // 2. Cargar el historial de vacunas aplicadas a una mascota específica
  Future<void> loadVaccinesForPet(int petId) async {
    final db = await _dbHelper.database;
    // Consulta con JOIN utilizando 'var'
    final maps = await db.rawQuery('''
      SELECT pv.id, pv.pet_id, pv.vaccine_id, v.name as vaccine_name, pv.date_applied, pv.expiry_date
      FROM pet_vaccines pv
      JOIN vaccines v ON pv.vaccine_id = v.id
      WHERE pv.pet_id = ?
      ORDER BY pv.expiry_date DESC
    ''', [petId]);

    _petVaccines = maps.map((m) => AppliedVaccineModel.fromMap(m)).toList();
    notifyListeners();
  }

  // 3. Aplicar una vacuna a una mascota calculando su vencimiento automático
  Future<void> applyVaccine({
    required int petId,
    required int vaccineId,
    required int validityMonths,
    required DateTime dateApplied,
  }) async {
    final db = await _dbHelper.database;
    
    // Calculamos la fecha de expiración sumando los meses de validez (ej. 12 meses)
    final expiryDate = DateTime(
      dateApplied.year,
      dateApplied.month + validityMonths,
      dateApplied.day,
    );

    await db.insert('pet_vaccines', {
      'pet_id': petId,
      'vaccine_id': vaccineId,
      'date_applied': dateApplied.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
    });

    await loadVaccinesForPet(petId);
  }

  // 4. Eliminar del historial una vacuna aplicada
  Future<void> removeAppliedVaccine(int appliedId, int petId) async {
    final db = await _dbHelper.database;
    await db.delete('pet_vaccines', where: 'id = ?', whereArgs: [appliedId]);
    await loadVaccinesForPet(petId);
  }
}