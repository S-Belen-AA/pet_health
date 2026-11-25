class VaccineOption {
  final String name;
  final bool repeatsInLife;
  final int defaultIntervalDays;
  final String scheduleSummary;

  const VaccineOption({
    required this.name,
    required this.repeatsInLife,
    required this.defaultIntervalDays,
    required this.scheduleSummary,
  });
}

class VaccineProtocolService {
  static const List<VaccineOption> dogVaccines = [
    VaccineOption(
      name: 'Séxtuple / Óctuple',
      repeatsInLife: true,
      defaultIntervalDays: 365,
      scheduleSummary: 'Serie inicial en cachorros y refuerzo anual (12 meses).',
    ),
    VaccineOption(
      name: 'Antirrábica',
      repeatsInLife: true,
      defaultIntervalDays: 365,
      scheduleSummary: 'Obligatoria en Chile; refuerzo/vigencia anual (12 meses).',
    ),
    VaccineOption(
      name: 'KC (Bordetella / Tos de las perreras)',
      repeatsInLife: true,
      defaultIntervalDays: 365,
      scheduleSummary: 'Refuerzo anual (12 meses) según exposición y sociabilidad.',
    ),
    VaccineOption(
      name: 'Antigiardia',
      repeatsInLife: true,
      defaultIntervalDays: 365,
      scheduleSummary: 'Refuerzo anual (12 meses) según riesgo y criterio veterinario.',
    ),
  ];

  static const List<VaccineOption> catVaccines = [
    VaccineOption(
      name: 'Triple Felina',
      repeatsInLife: true,
      defaultIntervalDays: 365,
      scheduleSummary: 'Serie inicial en gatitos y refuerzo anual (12 meses).',
    ),
    VaccineOption(
      name: 'Antirrábica',
      repeatsInLife: true,
      defaultIntervalDays: 365,
      scheduleSummary: 'Refuerzo/vigencia anual (12 meses) según esquema veterinario.',
    ),
    VaccineOption(
      name: 'Leucemia Felina (FeLV)',
      repeatsInLife: true,
      defaultIntervalDays: 365,
      scheduleSummary: 'Requiere test previo; refuerzo anual (12 meses) según riesgo.',
    ),
  ];

  static List<VaccineOption> optionsForSpecies(String species) {
    if (species.toLowerCase().contains('gato') ||
        species.toLowerCase().contains('felin')) {
      return catVaccines;
    }
    return dogVaccines;
  }

  static VaccineOption optionByName(String species, String? name) {
    final list = optionsForSpecies(species);
    if (name == null || name.trim().isEmpty) {
      return list.first;
    }
    return list.firstWhere(
      (item) => item.name.toLowerCase() == name.trim().toLowerCase(),
      orElse: () => VaccineOption(
        name: name.trim(),
        repeatsInLife: true,
        defaultIntervalDays: 365,
        scheduleSummary: 'Control periódico según indicación veterinaria.',
      ),
    );
  }

  static DateTime? calculateExpirationDate({
    required String species,
    required String vaccineName,
    required DateTime dateApplied,
    bool isPrimarySeriesBooster = false,
  }) {
    final option = optionByName(species, vaccineName);
    if (!option.repeatsInLife) return null;

    final daysToAdd = isPrimarySeriesBooster ? 28 : option.defaultIntervalDays;
    return DateTime(dateApplied.year, dateApplied.month, dateApplied.day)
        .add(Duration(days: daysToAdd));
  }
}