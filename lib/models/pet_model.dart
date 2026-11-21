class PetModel {
  final int? id;
  final String name;
  final String species; // 'Perro' o 'Gato'
  final String? breed; // Raza o 'Quiltro / Mestizo'
  final int? is_quiltro; // 1 (sí) o 0 (no)
  final String? size; // 'Pequeño', 'Mediano', 'Grande'
  final String? coat_length; // 'Corto', 'Mediano', 'Largo'
  final String? morph_emoji; // Emoji descriptivo (ej. 🐕, 🐈)
  final double weight; // En kg
  final int age; // Edad total estimada/guardada en meses (compatibilidad)
  final String? birthDate; // Fecha de nacimiento en formato ISO (YYYY-MM-DD...)
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
    this.birthDate,
    this.activity_level,
    this.body_condition,
    required this.createdAt,
  });

  /// Intenta parsear [birthDate] de forma segura.
  DateTime? get parsedBirthDate {
    if (birthDate == null || birthDate!.trim().isEmpty) return null;
    return DateTime.tryParse(birthDate!.trim());
  }

  /// Calcula la edad total en meses a partir de [birthDate] si existe;
  /// de lo contrario, usa el campo [age] guardado.
  int get totalMonths {
    final birth = parsedBirthDate;
    if (birth == null) {
      return age < 0 ? 0 : age;
    }

    final now = DateTime.now();
    int months = (now.year - birth.year) * 12 + (now.month - birth.month);
    if (now.day < birth.day) {
      months -= 1;
    }
    return months < 0 ? 0 : months;
  }

  int get ageYears => totalMonths ~/ 12;

  int get ageMonthsRemainder => totalMonths % 12;

  /// Texto legible de edad, ej.: "2 años y 3 meses", "8 meses" o "1 año".
  String get formattedAge {
    final years = ageYears;
    final months = ageMonthsRemainder;

    if (years == 0) {
      return months == 1 ? '1 mes' : '$months meses';
    }

    final yearLabel = years == 1 ? '1 año' : '$years años';
    if (months == 0) {
      return yearLabel;
    }
    final monthLabel = months == 1 ? '1 mes' : '$months meses';
    return '$yearLabel y $monthLabel';
  }

  /// Días que faltan para el próximo cumpleaños (0 = hoy es su cumpleaños).
  /// Retorna `null` si no hay fecha de nacimiento registrada.
  int? get daysUntilBirthday {
    final birth = parsedBirthDate;
    if (birth == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Manejo seguro para nacidos el 29 de febrero en años no bisiestos
    int targetDay = birth.day;
    if (birth.month == 2 && birth.day == 29 && !_isLeapYear(now.year)) {
      targetDay = 28;
    }

    DateTime nextBirthday = DateTime(now.year, birth.month, targetDay);
    if (nextBirthday.isBefore(today)) {
      final nextYear = now.year + 1;
      int nextYearDay = birth.day;
      if (birth.month == 2 && birth.day == 29 && !_isLeapYear(nextYear)) {
        nextYearDay = 28;
      }
      nextBirthday = DateTime(nextYear, birth.month, nextYearDay);
    }

    return nextBirthday.difference(today).inDays;
  }

  /// Devuelve un aviso si hoy es el cumpleaños o faltan 30 días o menos.
  String? get birthdayAlertMessage {
    final days = daysUntilBirthday;
    if (days == null) return null;

    if (days == 0) {
      return '🎉 ¡Hoy es el cumpleaños de $name! Celebren juntos.';
    }
    if (days == 1) {
      return '🎂 ¡Mañana es el cumpleaños de $name!';
    }
    if (days <= 30) {
      return '🎈 Faltan $days días para el cumpleaños de $name.';
    }
    return null;
  }

  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  // Convertir un Map (de SQLite) a un Objeto PetModel
  factory PetModel.fromMap(Map<String, dynamic> map) {
    final rawWeight = map['weight'];
    final parsedWeight = rawWeight is num
        ? rawWeight.toDouble()
        : double.tryParse(rawWeight.toString().replaceAll(',', '.')) ?? 0.0;

    return PetModel(
      id: map['id'] as int?,
      name: (map['name'] ?? '') as String,
      species: (map['species'] ?? 'Perro') as String,
      breed: map['breed'] as String?,
      is_quiltro: map['is_quiltro'] as int?,
      size: map['size'] as String?,
      coat_length: map['coat_length'] as String?,
      morph_emoji: map['morph_emoji'] as String?,
      weight: parsedWeight,
      age: (map['age'] ?? 0) as int,
      birthDate: map['birth_date'] as String?,
      activity_level: map['activity_level'] as String?,
      body_condition: map['body_condition'] as String?,
      createdAt: (map['created_at'] ?? '') as String,
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
      'age': totalMonths,
      'birth_date': birthDate,
      'activity_level': activity_level,
      'body_condition': body_condition,
      'created_at': createdAt,
    };
  }
}