import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_health/models/pet_model.dart';
import 'package:pet_health/providers/pet_provider.dart';
import 'package:pet_health/screens/calculator/pet_calculator_screen.dart';
import 'package:pet_health/screens/pets/pet_detail_screen.dart';
import 'package:pet_health/screens/pets/pet_form_screen.dart';
import 'package:pet_health/widgets/glass_card.dart';

class PetListScreen extends StatelessWidget {
  const PetListScreen({super.key});

  Widget _buildPetAvatar(PetModel pet) {
    final value = pet.morph_emoji;
    if (value != null && value.startsWith('animalitos/')) {
      return SizedBox(
        width: 42,
        height: 42,
        child: Image.asset(
          value,
          width: 42,
          height: 42,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              pet.species == 'Perro' ? '🐕' : '🐈',
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 42,
      height: 42,
      child: Center(
        child: Text(
          value ?? (pet.species == 'Perro' ? '🐕' : '🐈'),
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integrantes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Calculadora nutricional',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PetCalculatorScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PetFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva mascota'),
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, _) {
          if (petProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (petProvider.pets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Aún no tienes perros ni gatos registrados.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PetFormScreen()),
                          );
                        },
                        icon: const Icon(Icons.pets),
                        label: const Text('Registrar primera mascota'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: petProvider.pets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final pet = petProvider.pets[index];
              final estText = pet.isBirthDateEstimated ? ' (fecha estimada)' : '';
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PetDetailScreen(pet: pet),
                    ),
                  );
                },
                child: GlassCard(
                  child: Row(
                    children: [
                      _buildPetAvatar(pet),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${pet.species}${pet.breed != null ? ' • ${pet.breed}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Edad: ${pet.formattedAge}$estText • ${pet.weight} kg',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}