import 'package:flutter/foundation.dart';
import 'package:pet_health/database/database_helper.dart';
import 'package:pet_health/models/pet_model.dart';

class PetProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final List<PetModel> _pets = [];
  bool _isLoading = false;
  String? _lastError;

  List<PetModel> get pets => List.unmodifiable(_pets);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  String? _cleanOptional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  loadPets() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final db = await _dbHelper.database;
      final rows = await db.query('pets', orderBy: 'id DESC');
      _pets
        ..clear()
        ..addAll(rows.map((row) => PetModel.fromMap(row)));
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  addPet(PetModel pet) async {
    final db = await _dbHelper.database;
    final id = await db.insert('pets', pet.toMap());
    _pets.insert(0, pet.copyWith(id: id));
    notifyListeners();
  }

  updatePet(PetModel pet) async {
    if (pet.id == null) return;
    final db = await _dbHelper.database;
    await db.update(
      'pets',
      pet.toMap(),
      where: 'id = ?',
      whereArgs: [pet.id],
    );
    final idx = _pets.indexWhere((p) => p.id == pet.id);
    if (idx != -1) {
      _pets[idx] = pet;
    }
    notifyListeners();
  }

  deletePet(int id) async {
    final db = await _dbHelper.database;
    await db.delete('pets', where: 'id = ?', whereArgs: [id]);
    _pets.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // --- Vacunas ---
  getVaccinesForPet(int petId) async {
    final db = await _dbHelper.database;
    return db.query(
      'pet_vaccines',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'date_applied DESC, id DESC',
    );
  }

  addVaccineRecord({
    required int petId,
    required String vaccineName,
    required String dateApplied,
    String? nextDueDate,
    String? providerOrClinic,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('pet_vaccines', {
      'pet_id': petId,
      'vaccine_id': null,
      'vaccine_name': vaccineName.trim(),
      'date_applied': dateApplied,
      'next_due_date': nextDueDate,
      'expiry_date': nextDueDate,
      'provider_or_clinic': _cleanOptional(providerOrClinic),
      'notes': _cleanOptional(notes),
    });
    notifyListeners();
  }

  // --- Desparasitaciones ---
  getDewormingsForPet(int petId) async {
    final db = await _dbHelper.database;
    return db.query(
      'dewormings',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'date_applied DESC, id DESC',
    );
  }

  addDewormingRecord({
    required int petId,
    required String productName,
    required String dateApplied,
    String? nextDueDate,
    String? providerOrClinic,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('dewormings', {
      'pet_id': petId,
      'product_name': productName.trim(),
      'date_applied': dateApplied,
      'next_due_date': nextDueDate,
      'provider_or_clinic': _cleanOptional(providerOrClinic),
      'notes': _cleanOptional(notes),
    });
    notifyListeners();
  }

  // --- Consultas veterinarias ---
  getVetVisitsForPet(int petId) async {
    final db = await _dbHelper.database;
    return db.query(
      'vet_visits',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'visit_date DESC, id DESC',
    );
  }

  addVetVisitRecord({
    required int petId,
    required String visitDate,
    required String reason,
    String? clinicOrVet,
    String? observations,
    String? treatment,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('vet_visits', {
      'pet_id': petId,
      'visit_date': visitDate,
      'reason': reason.trim(),
      'clinic_or_vet': _cleanOptional(clinicOrVet),
      'observations': _cleanOptional(observations),
      'treatment': _cleanOptional(treatment),
    });
    notifyListeners();
  }
}