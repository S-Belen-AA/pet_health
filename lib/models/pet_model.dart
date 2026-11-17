class PetModel {
  final int? id;
  final String name;
  final String species; // 'Perro' o 'Gato'
  final String? breed; // Raza o 'Quiltro'
  final int? is_quiltro; // 1 (sí) o 0 (no)
  final String? size; // 'Pequeño', 'Mediano', 'Grande'
  final String? coat_length; // 'Corto', 'Mediano', 'Largo'
  final String? morph_emoji; // Emoji descriptivo (ej. 🐕, 🐈, 🦁)
  final double weight; // En kg
  final int age; // En meses o años
  final String? activity_level; // 'Bajo', 'Moderado', 'Alto'
  final String? body_condition; // 'Delgado', 'Ideal', 'Sobrepeso'
  final String createdAt;

  PetModel({
    this.id,
    required this.name,
    required this.species,
    this.breed,
    this.is_quiltro,
    this.size,
    this.coat_length,
    this.morph_emoji,
    required this.weight,
    required this.age,
    this.activity_level,
    this.body_condition,
    required this.createdAt,
  });

  // Convertir un Map (de SQLite) a un Objeto PetModel
  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      breed: map['breed'],
      is_quiltro: map['is_quiltro'],
      size: map['size'],
      coat_length: map['coat_length'],
      morph_emoji: map['morph_emoji'],
      weight: map['weight'],
      age: map['age'],
      activity_level: map['activity_level'],
      body_condition: map['body_condition'],
      createdAt: map['created_at'],
    );
  }

  // Convertir un Objeto PetModel a un Map (para insertar/actualizar en SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'is_quiltro': is_quiltro,
      'size': size,
      'coat_length': coat_length,
      'morph_emoji': morph_emoji,
      'weight': weight,
      'age': age,
      'activity_level': activity_level,
      'body_condition': body_condition,
      'created_at': createdAt,
    };
  }
}