class PetModel {
  final int? id;
  final String name;
  final String species; // 'Perro' o 'Gato'
  final String? sex; // 'Macho', 'Hembra' o null si no registrado
  final String? breed; // Raza o 'Quiltro / Mestizo'
  final int? is_quiltro; // 1 (sí) o 0 (no)
  final String? size; // 'Pequeño', 'Mediano', 'Grande'
  final String? coat_length; // 'Corto', 'Mediano', 'Largo'
  final String? morph_emoji; // Emoji descriptivo (ej. 🐕, 🐈)
  final double weight; // En kg
  final int age; // Edad total estimada/guardada en meses
  final String? birthDate; // Fecha de nacimiento en formato ISO (YYYY-MM-DD...)
  final bool isBirthDateEstimated; // true = estimada, false = exacta
  final String? activity_level; // 'Bajo', 'Moderado', 'Alto'
  final String? body_condition; // 'Delgado', 'Ideal', 'Sobrepeso'
  final String createdAt;

  PetModel({
    this.id,
    required this.name,
    required this.species,
    this.sex,
    this.breed,
    this.is_quiltro,
    this.size,
    this.coat_length,
    this.morph_emoji,
    required this.weight,
    required this.age,
    this.birthDate,
    this.isBirthDateEstimated = false,
    this.activity_level,
    this.body_condition,
    required this.createdAt,
  });

  DateTime? get parsedBirthDate {
    if (birthDate == null || birthDate!.trim().isEmpty) return null;
    return DateTime.tryParse(birthDate!.trim());
  }

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
    return '$yearLabel y$monthLabel';
  }

  DateTime? get nextBirthdayDate {
    final birth = parsedBirthDate;
    if (birth == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int targetDay = birth.day;
    if (birth.month == 2 && birth.day == 29 && !_isLeapYear(now.year)) {
      targetDay = 28;
    }

    DateTime candidate = DateTime(now.year, birth.month, targetDay);
    if (candidate.isBefore(today)) {
      final nextYear = now.year + 1;
      int nextYearDay = birth.day;
      if (birth.month == 2 && birth.day == 29 && !_isLeapYear(nextYear)) {
        nextYearDay = 28;
      }
      candidate = DateTime(nextYear, birth.month, nextYearDay);
    }
    return candidate;
  }

  int? get daysUntilBirthday {
    final nextBday = nextBirthdayDate;
    if (nextBday == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextBday.difference(today).inDays;
  }

  int? get upcomingAgeYears {
    final nextBday = nextBirthdayDate;
    final birth = parsedBirthDate;
    if (nextBday == null || birth == null) return null;
    final years = nextBday.year - birth.year;
    return years < 1 ? 1 : years;
  }

  String? get birthdayAlertMessage {
    final days = daysUntilBirthday;
    if (days == null) return null;

    final tag = isBirthDateEstimated ? ' (estimado)' : '';
    if (days == 0) {
      return '🎉 ¡Hoy es el cumpleaños$tag de$name!';
    }
    if (days == 1) {
      return '🎂 ¡Mañana es el cumpleaños$tag de$name!';
    }
    if (days <= 30) {
      return '🎈 Faltan $days días para el cumpleaños$tag de$name.';
    }
    return null;
  }

  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  PetModel copyWith({
    int? id,
    String? name,
    String? species,
    String? sex,
    String? breed,
    int? is_quiltro,
    String? size,
    String? coat_length,
    String? morph_emoji,
    double? weight,
    int? age,
    String? birthDate,
    bool? isBirthDateEstimated,
    String? activity_level,
    String? body_condition,
    String? createdAt,
  }) {
    return PetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      sex: sex ?? this.sex,
      breed: breed ?? this.breed,
      is_quiltro: is_quiltro ?? this.is_quiltro,
      size: size ?? this.size,
      coat_length: coat_length ?? this.coat_length,
      morph_emoji: morph_emoji ?? this.morph_emoji,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      birthDate: birthDate ?? this.birthDate,
      isBirthDateEstimated: isBirthDateEstimated ?? this.isBirthDateEstimated,
      activity_level: activity_level ?? this.activity_level,
      body_condition: body_condition ?? this.body_condition,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory PetModel.fromMap(Map<String, dynamic> map) {
    final rawWeight = map['weight'];
    final parsedWeight = rawWeight is num
        ? rawWeight.toDouble()
        : double.tryParse(rawWeight.toString().replaceAll(',', '.')) ?? 0.0;

    final rawEstimated = map['is_birth_date_estimated'];
    final estimatedBool = rawEstimated is int
        ? rawEstimated == 1
        : rawEstimated is bool
            ? rawEstimated
            : false;

    return PetModel(
      id: map['id'] as int?,
      name: (map['name'] ?? '') as String,
      species: (map['species'] ?? 'Perro') as String,
      sex: map['sex'] as String?,
      breed: map['breed'] as String?,
      is_quiltro: map['is_quiltro'] as int?,
      size: map['size'] as String?,
      coat_length: map['coat_length'] as String?,
      morph_emoji: map['morph_emoji'] as String?,
      weight: parsedWeight,
      age: (map['age'] ?? 0) as int,
      birthDate: map['birth_date'] as String?,
      isBirthDateEstimated: estimatedBool,
      activity_level: map['activity_level'] as String?,
      body_condition: map['body_condition'] as String?,
      createdAt: (map['created_at'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'species': species,
      'sex': sex,
      'breed': breed,
      'is_quiltro': is_quiltro,
      'size': size,
      'coat_length': coat_length,
      'morph_emoji': morph_emoji,
      'weight': weight,
      'age': totalMonths,
      'birth_date': birthDate,
      'is_birth_date_estimated': isBirthDateEstimated ? 1 : 0,
      'activity_level': activity_level,
      'body_condition': body_condition,
      'created_at': createdAt,
    };
  }
}