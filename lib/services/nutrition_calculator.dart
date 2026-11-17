import 'dart:math';
import 'package:pet_health/models/pet_model.dart';

class NutritionResult {
  final double rer;
  final double mer;
  final int dailyGrams;
  final String recommendation;

  NutritionResult({
    required this.rer,
    required this.mer,
    required this.dailyGrams,
    required this.recommendation,
  });
}

class NutritionCalculator {
  static NutritionResult calculateFood(PetModel pet) {
    // 1. Cálculo del RER (Resting Energy Requirement) -> 70 * (peso ^ 0.75)
    double weight = pet.weight;
    if (weight <= 0) weight = 1.0; // Evitar errores con pesos nulos o 0
    
    // Se añade .toDouble() para convertir el resultado 'num' de pow() a 'double'
    double rer = 70 * pow(weight, 0.75).toDouble();
    double factor = 1.6; // Factor base por defecto para adultos castrados/mantenimiento

    // 2. Asignación del factor MER según especie y nivel de actividad
    if (pet.species == 'Perro') {
      switch (pet.activity_level) {
        case 'Bajo':
          factor = 1.2; // Perros senior o sedentarios
          break;
        case 'Moderado':
          factor = 1.6; // Perros adultos con paseo diario normal
          break;
        case 'Alto':
          factor = 2.0; // Perros muy activos / de trabajo
          break;
        default:
          factor = 1.6;
      }
      // Ajuste por condición corporal
      if (pet.body_condition == 'Sobrepeso') factor -= 0.2;
      if (pet.body_condition == 'Delgado') factor += 0.2;
    } else {
      // Gatos
      switch (pet.activity_level) {
        case 'Bajo':
          factor = 1.0; // Gatos indoor sedentarios
          break;
        case 'Moderado':
          factor = 1.2; // Gatos adultos estándar
          break;
        case 'Alto':
          factor = 1.4; // Gatos con mucha actividad exterior/juego
          break;
        default:
          factor = 1.2;
      }
      if (pet.body_condition == 'Sobrepeso') factor -= 0.15;
      if (pet.body_condition == 'Delgado') factor += 0.2;
    }

    // 3. Cálculo de las Kilocalorías de Mantenimiento (MER)
    double mer = rer * factor;

    // 4. Conversión a gramos de alimento diario 
    // (Asumiendo un alimento comercial estándar de alta calidad con ~3,500 kcal por kg, es decir, 3.5 kcal por gramo)
    int dailyGrams = (mer / 3.5).round();

    // 5. Generar recomendación clínica personalizada
    String recommendation = 'Porción recomendada dividida en 2 raciones diarias (mañana y noche). '
        'Ajusta la cantidad si notas cambios en el peso de ${pet.name}.';

    return NutritionResult(
      rer: rer,
      mer: mer,
      dailyGrams: dailyGrams,
      recommendation: recommendation,
    );
  }
}