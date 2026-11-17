import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_health/models/pet_model.dart';
import 'package:pet_health/providers/pet_provider.dart';
import 'package:pet_health/widgets/glass_card.dart';

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto y variables de estado del formulario
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String _species = 'Perro'; // 'Perro' o 'Gato'
  String _selectedBreed = 'Pastor Alemán';
  bool _isQuiltro = false;
  String _size = 'Mediano'; // 'Pequeño', 'Mediano', 'Grande'
  String _coatLength = 'Corto'; // 'Corto', 'Mediano', 'Largo'
  String _morphEmoji = '🐕'; // Emoji por defecto
  String _activityLevel = 'Moderado'; // 'Bajo', 'Moderado', 'Alto'
  String _bodyCondition = 'Ideal'; // 'Delgado', 'Ideal', 'Sobrepeso'

  // Listas de apoyo para selecciones en Chile
  final List<String> _dogBreeds = [
    'Pastor Alemán', 'Labrador Retriever', 'Golden Retriever', 
    'Poodle', 'Bulldog Francés', 'Kiltro / Mestizo'
  ];

  final List<String> _catEmojis = ['🐈', '🐱', '🐈‍⬛', '🐅', '🦁', '😺'];
  final List<String> _dogEmojis = ['🐕', '🐶', '🦮', '🐕‍🦺', '🦊'];

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _savePet() {
    if (_formKey.currentState!.validate()) {
      final newPet = PetModel(
        name: _nameController.text.trim(),
        species: _species,
        breed: _isQuiltro ? 'Quiltro / Mestizo' : _selectedBreed,
        is_quiltro: _isQuiltro ? 1 : 0,
        size: _size,
        coat_length: _species == 'Perro' ? _coatLength : null,
        morph_emoji: _morphEmoji,
        weight: double.parse(_weightController.text.trim()),
        age: int.parse(_ageController.text.trim()),
        activity_level: _activityLevel,
        body_condition: _bodyCondition,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Guardamos a través del Provider
      Provider.of<PetProvider>(context, listen: false).addPet(newPet);
      Navigator.pop(context); // Regresamos a la pantalla anterior
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Nueva Mascota 🐾'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. SELECCIÓN DE ESPECIE ---
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Especie', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _species,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: ['Perro', 'Gato'].map((species) {
                        return DropdownMenuItem(
                          value: species,
                          child: Text(species == 'Perro' ? '🐶 Perro' : '🐱 Gato'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _species = value!;
                          _morphEmoji = _species == 'Perro' ? '🐕' : '🐈';
                        });
                      },
                    ),
                  ],
                ),
              ),

              // --- 2. NOMBRE Y DATOS BÁSICOS ---
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Información General', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la mascota',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Ingresa un nombre' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Peso (kg)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || double.tryParse(value) == null ? 'Peso inválido' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Edad (meses)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || int.tryParse(value) == null ? 'Edad inválida' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- 3. CAMPOS CONDICIONALES SEGÚN ESPECIE (RAZA / QUILTRO) ---
              if (_species == 'Perro') ...[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Origen y Raza Canina', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('¿Es Quiltro / Mestizo? 🇨🇱'),
                        value: _isQuiltro,
                        onChanged: (val) {
                          setState(() {
                            _isQuiltro = val;
                          });
                        },
                      ),
                      if (!_isQuiltro) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedBreed,
                          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Raza'),
                          items: _dogBreeds.where((b) => b != 'Kiltro / Mestizo').map((breed) {
                            return DropdownMenuItem(value: breed, child: Text(breed));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedBreed = val!),
                        ),
                      ],
                      if (_isQuiltro) ...[
                        const SizedBox(height: 8),
                        const Text('Características del Quiltro:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _size,
                                decoration: const InputDecoration(labelText: 'Tamaño', border: OutlineInputBorder()),
                                items: ['Pequeño', 'Mediano', 'Grande'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (val) => setState(() => _size = val!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _coatLength,
                                decoration: const InputDecoration(labelText: 'Pelo', border: OutlineInputBorder()),
                                items: ['Corto', 'Mediano', 'Largo'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (val) => setState(() => _coatLength = val!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // --- 4. SELECTOR VISUAL / EMOJI ---
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Avatar / Emoji Morfológico', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: (_species == 'Perro' ? _dogEmojis : _catEmojis).map((emoji) {
                        final isSelected = _morphEmoji == emoji;
                        return GestureDetector(
                          onTap: () => setState(() => _morphEmoji = emoji),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.5) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? Colors.green : Colors.transparent, width: 2),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 30)),
                          ),
                        );
                      }).toList(), // <-- Aquí estaba el .toList() que faltaba corregir
                    ),
                  ],
                ),
              ),

              // --- 5. BOTÓN DE GUARDAR ---
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _savePet,
                  child: const Text('Guardar Mascota en SQLite 💾', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}