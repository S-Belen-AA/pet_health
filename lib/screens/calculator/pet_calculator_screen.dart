import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_health/models/pet_model.dart';
import 'package:pet_health/providers/pet_provider.dart';
import 'package:pet_health/services/nutrition_calculator.dart';
import 'package:pet_health/widgets/glass_card.dart';

class PetCalculatorScreen extends StatefulWidget {
  final PetModel? initialPet;

  const PetCalculatorScreen({super.key, this.initialPet});

  @override
  State<PetCalculatorScreen> createState() => _PetCalculatorScreenState();
}

class _PetCalculatorScreenState extends State<PetCalculatorScreen> {
  PetModel? _selectedPet;
  String _activityLevel = 'Moderado';
  String _bodyCondition = 'Ideal';

  @override
  void initState() {
    super.initState();
    final pets = Provider.of<PetProvider>(context, listen: false).pets;
    if (widget.initialPet != null) {
      _selectedPet = widget.initialPet;
      _activityLevel = widget.initialPet!.activity_level ?? 'Moderado';
      _bodyCondition = widget.initialPet!.body_condition ?? 'Ideal';
    } else if (pets.isNotEmpty) {
      _selectedPet = pets.first;
      _activityLevel = pets.first.activity_level ?? 'Moderado';
      _bodyCondition = pets.first.body_condition ?? 'Ideal';
    }
  }

  Widget _buildPetLeading(PetModel pet) {
    final value = pet.morph_emoji;
    if (value != null && value.startsWith('animalitos/')) {
      return Image.asset(
        value,
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text(
          pet.species == 'Perro' ? '🐕' : '🐈',
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    return Text(
      value ?? (pet.species == 'Perro' ? '🐕' : '🐈'),
      style: const TextStyle(fontSize: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = Provider.of<PetProvider>(context);
    final pets = petProvider.pets;

    final PetModel? activeSelectedPet = _selectedPet != null
        ? pets.firstWhere(
            (p) => p.id == _selectedPet!.id && p.name == _selectedPet!.name,
            orElse: () => pets.isNotEmpty ? pets.first : _selectedPet!,
          )
        : (pets.isNotEmpty ? pets.first : null);

    // Si hay una mascota seleccionada, calculamos sus porciones en tiempo real
    NutritionResult? result;
    if (activeSelectedPet != null) {
      // Creamos una copia temporal con los estados ajustados en la vista
      final tempPet = PetModel(
        id: activeSelectedPet.id,
        name: activeSelectedPet.name,
        species: activeSelectedPet.species,
        breed: activeSelectedPet.breed,
        weight: activeSelectedPet.weight,
        age: activeSelectedPet.age,
        activity_level: _activityLevel,
        body_condition: _bodyCondition,
        createdAt: activeSelectedPet.createdAt,
        morph_emoji: activeSelectedPet.morph_emoji,
      );
      result = NutritionCalculator.calculateFood(tempPet);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Nutricional'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF1F4037), const Color(0xFF121212)]
                : [const Color(0xFFA3E4D7), const Color(0xFFF7F9F6)],
          ),
        ),
        child: pets.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.calculate_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No hay mascotas registradas para calcular porciones.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Registra al menos una mascota en el menú principal.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de Mascota
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seleccionar Mascota', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<PetModel>(
                            value: activeSelectedPet,
                            isExpanded: true,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: pets.map((pet) {
                              return DropdownMenuItem(
                                value: pet,
                                child: Row(
                                  children: [
                                    _buildPetLeading(pet),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        pet.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedPet = val;
                                if (val != null) {
                                  _activityLevel = val.activity_level ?? 'Moderado';
                                  _bodyCondition = val.body_condition ?? 'Ideal';
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Ajustes de Actividad y Condición Corporal
                    if (activeSelectedPet != null) ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Parámetros Metabólicos', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _activityLevel,
                              decoration: const InputDecoration(labelText: 'Nivel de Actividad', border: OutlineInputBorder()),
                              items: ['Bajo', 'Moderado', 'Alto'].map((lvl) {
                                return DropdownMenuItem(value: lvl, child: Text(lvl));
                              }).toList(),
                              onChanged: (val) => setState(() => _activityLevel = val!),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _bodyCondition,
                              decoration: const InputDecoration(labelText: 'Condición Corporal', border: OutlineInputBorder()),
                              items: ['Delgado', 'Ideal', 'Sobrepeso'].map((cond) {
                                return DropdownMenuItem(value: cond, child: Text(cond));
                              }).toList(),
                              onChanged: (val) => setState(() => _bodyCondition = val!),
                            ),
                          ],
                        ),
                      ),

                      // Tarjeta de Resultados Nutricionales Exactos
                      if (result != null) ...[
                        const SizedBox(height: 10),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                '📊 Ración Diaria Recomendada',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${result.dailyGrams} gramos',
                                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('de alimento seco al día', style: TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text('RER: ${result.rer.toStringAsFixed(0)} kcal'),
                                  Text('MER: ${result.mer.toStringAsFixed(0)} kcal/día'),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                result.recommendation,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}