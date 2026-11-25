import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_health/providers/pet_provider.dart';
import 'package:pet_health/screens/pets/pet_list_screen.dart';
import 'package:pet_health/widgets/glass_card.dart';
import 'package:pet_health/screens/pets/pet_form_screen.dart';
import 'package:pet_health/screens/vaccines/pet_vaccines_screen.dart';
import 'package:pet_health/screens/calculator/pet_calculator_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PetProvider()..loadPets()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetHealth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const PetListScreen(),
    );
  }
}

class PetHomeScreen extends StatelessWidget {
  const PetHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final petProvider = Provider.of<PetProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐾 PetHealth - Panel Principal'),
        actions: [
          // Botón rápido para abrir la calculadora nutricional general
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PetCalculatorScreen(),
                ),
              );
            },
            tooltip: 'Calculadora de Alimentos',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFA3E4D7), Color(0xFFF7F9F6)],
          ),
        ),
        child: Column(
          children: [
            // Resumen superior
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mascotas Registradas:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Chip(
                      label: Text(
                        '${petProvider.pets.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),

            // Listado de Mascotas con acceso directo a módulos
            Expanded(
              child: petProvider.pets.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: GlassCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('🐶🐱', style: TextStyle(fontSize: 40)),
                              SizedBox(height: 12),
                              Text(
                                'Aún no tienes mascotas registradas.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Presiona el botón "+" abajo para registrar la primera ficha.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: petProvider.pets.length,
                      itemBuilder: (context, index) {
                        final pet = petProvider.pets[index];
                        return GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Text(
                                  pet.morph_emoji ?? '🐶',
                                  style: const TextStyle(fontSize: 32),
                                ),
                                title: Text(
                                  pet.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  '${pet.species} • ${pet.breed ?? "Quiltro"} • ${pet.weight} kg',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    petProvider.deletePet(pet.id!);
                                  },
                                  tooltip: 'Eliminar ficha',
                                ),
                              ),
                              const Divider(height: 16),
                              // Botones de acción rápida en la tarjeta
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PetVaccinesScreen(pet: pet),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.vaccines, size: 18),
                                    label: const Text('Cartilla Vacunas'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PetCalculatorScreen(initialPet: pet),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.restaurant, size: 18),
                                    label: const Text('Porción Diaria'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PetFormScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.black87),
        label: const Text(
          'Añadir Mascota',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}