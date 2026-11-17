class VaccineModel {
  final int? id;
  final String name;
  final String species; // 'Perro', 'Gato', 'Ambos'
  final int validityMonths; // Duración típica (ej. 12 meses)

  VaccineModel({
    this.id,
    required this.name,
    required this.species,
    required this.validityMonths,
  });

  factory VaccineModel.fromMap(Map<String, dynamic> map) {
    return VaccineModel(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      validityMonths: map['validity_months'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'validity_months': validityMonths,
    };
  }
}