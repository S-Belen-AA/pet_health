import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_health/providers/pet_provider.dart';
import 'package:pet_health/screens/pets/pet_detail_screen.dart';
import 'package:pet_health/screens/pets/pet_form_screen.dart';
import 'package:pet_health/widgets/glass_card.dart';

class PetListScreen extends StatelessWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Mascotas 🐾'),
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
                      Text(
                        pet.morph_emoji ?? (pet.species == 'Perro' ? '🐕' : '🐈'),
                        style: const TextStyle(fontSize: 34),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            Text('${pet.species}${pet.breed != null ? ' • ${pet.breed}' : ''}'),
                            Text('Edad: ${pet.formattedAge}$estText • ${pet.weight} kg'),
                          ],
                        ),
                      ),
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