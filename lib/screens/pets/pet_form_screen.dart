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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController(text: '0');
  final TextEditingController _monthsController = TextEditingController(text: '1');

  DateTime? _birthDate = DateTime.now().subtract(const Duration(days: 180));
  bool _useManualAgeFallback = false;

  String _species = 'Perro';
  String _selectedBreed = 'Chihuahua';
  bool _isQuiltro = false;
  bool _isSaving = false;
  String _size = 'Mediano';
  String _coatLength = 'Corto';
  String _morphEmoji = '🐕';
  final String _activityLevel = 'Moderado';
  final String _bodyCondition = 'Ideal';

  // Razas habituales en hogares chilenos
  final List<String> _dogBreeds = [
    'Chihuahua',
    'Pastor Alemán',
    'Labrador Retriever',
    'Golden Retriever',
    'Poodle',
    'Bulldog Francés',
    'Pug / Carlino',
    'Salchicha (Dachshund)',
    'Beagle',
    'Cocker Spaniel',
    'Bóxer',
    'Schnauzer',
    'Border Collie',
    'Yorkshire Terrier',
    'Jack Russell Terrier',
    'Husky Siberiano',
    'Rottweiler',
    'Quiltro / Mestizo',
  ];

  final List<String> _catEmojis = ['🐈', '🐱', '🐈‍⬛', '🐅', '🦁', '😺'];
  final List<String> _dogEmojis = ['🐕', '🐶', '🦮', '🐕‍🦺', '🦊'];

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _yearsController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  double? _parseWeight(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) return null;
    return value;
  }

  int? _parseNonNegativeInt(String raw) {
    if (raw.trim().isEmpty) return 0;
    final value = int.tryParse(raw.trim());
    if (value == null || value < 0) return null;
    return value;
  }

  String _formatDateEs(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  int _calculateMonthsFromBirthDate(DateTime birth) {
    final now = DateTime.now();
    int months = (now.year - birth.year) * 12 + (now.month - birth.month);
    if (now.day < birth.day) {
      months -= 1;
    }
    return months < 0 ? 0 : months;
  }

  String _formatYearsAndMonths(int totalMonths) {
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;
    if (years == 0) {
      return months == 1 ? '1 mes' : '$months meses';
    }
    final yearText = years == 1 ? '1 año' : '$years años';
    if (months == 0) return yearText;
    final monthText = months == 1 ? '1 mes' : '$months meses';
    return '$yearText y $monthText';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? now.subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1995, 1, 1),
      lastDate: now,
      helpText: 'Selecciona la fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _useManualAgeFallback = false;
      });
    }
  }

  Future<void> _savePet() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_useManualAgeFallback && _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una fecha de nacimiento o activa la estimación por edad.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final parsedWeight = _parseWeight(_weightController.text)!;

      int totalAgeInMonths;
      String? birthDateIso;

      if (!_useManualAgeFallback && _birthDate != null) {
        totalAgeInMonths = _calculateMonthsFromBirthDate(_birthDate!);
        birthDateIso = DateTime(
          _birthDate!.year,
          _birthDate!.month,
          _birthDate!.day,
        ).toIso8601String();
      } else {
        final years = _parseNonNegativeInt(_yearsController.text) ?? 0;
        final months = _parseNonNegativeInt(_monthsController.text) ?? 0;
        totalAgeInMonths = (years * 12) + months;
        birthDateIso = null;
      }

      final newPet = PetModel(
        name: _nameController.text.trim(),
        species: _species,
        breed: _species == 'Perro'
            ? (_isQuiltro ? 'Quiltro / Mestizo' : _selectedBreed)
            : 'Felino',
        is_quiltro: _species == 'Perro' ? (_isQuiltro ? 1 : 0) : 0,
        size: _size,
        coat_length: _species == 'Perro' ? _coatLength : null,
        morph_emoji: _morphEmoji,
        weight: parsedWeight,
        age: totalAgeInMonths,
        birthDate: birthDateIso,
        activity_level: _activityLevel,
        body_condition: _bodyCondition,
        createdAt: DateTime.now().toIso8601String(),
      );

      await Provider.of<PetProvider>(context, listen: false).addPet(newPet);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final errorText = e.toString().contains('no column named birth_date')
          ? 'La base de datos local necesita reiniciarse/reinstalarse para aplicar la migración v3. Haz Hot Restart o reinstala la app en pruebas.'
          : 'Error al guardar en SQLite: $e';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorText),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewMonths = !_useManualAgeFallback && _birthDate != null
        ? _calculateMonthsFromBirthDate(_birthDate!)
        : null;

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
                        if (value == null) return;
                        setState(() {
                          _species = value;
                          _morphEmoji = _species == 'Perro' ? '🐕' : '🐈';
                        });
                      },
                    ),
                  ],
                ),
              ),
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
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Ingresa un nombre' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Peso (kg) — ej. 4.5 o 4,5',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || _parseWeight(value) == null) {
                          return 'Ingresa un peso válido mayor a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: Text(
                            'Fecha de nacimiento y edad',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _useManualAgeFallback = !_useManualAgeFallback;
                            });
                          },
                          child: Text(
                            _useManualAgeFallback
                                ? 'Usar fecha exacta'
                                : 'Estimar edad',
                          ),
                        ),
                      ],
                    ),
                    if (!_useManualAgeFallback) ...[
                      OutlinedButton.icon(
                        onPressed: _pickBirthDate,
                        icon: const Icon(Icons.cake),
                        label: Text(
                          _birthDate == null
                              ? 'Seleccionar fecha de nacimiento'
                              : 'Nacimiento: ${_formatDateEs(_birthDate!)}',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      if (previewMonths != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Edad calculada: ${_formatYearsAndMonths(previewMonths)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _yearsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Años',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || _parseNonNegativeInt(value) == null) {
                                  return 'Años inválidos';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _monthsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Meses',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final parsed = _parseNonNegativeInt(value ?? '');
                                if (parsed == null || parsed > 11) {
                                  return 'Entre 0 y 11';
                                }
                                final years = _parseNonNegativeInt(_yearsController.text) ?? 0;
                                if (years == 0 && parsed == 0) {
                                  return 'Indica edad';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
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
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Raza',
                          ),
                          items: _dogBreeds.where((b) => b != 'Quiltro / Mestizo').map((breed) {
                            return DropdownMenuItem(value: breed, child: Text(breed));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedBreed = val);
                          },
                        ),
                      ],
                      if (_isQuiltro) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Características del Quiltro:',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _size,
                                decoration: const InputDecoration(
                                  labelText: 'Tamaño',
                                  border: OutlineInputBorder(),
                                ),
                                items: ['Pequeño', 'Mediano', 'Grande']
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _size = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _coatLength,
                                decoration: const InputDecoration(
                                  labelText: 'Pelo',
                                  border: OutlineInputBorder(),
                                ),
                                items: ['Corto', 'Mediano', 'Largo']
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _coatLength = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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
                              color: isSelected
                                  ? Theme.of(context).primaryColor.withOpacity(0.5)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.green : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 30)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isSaving ? null : _savePet,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Guardar Mascota en SQLite 💾',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}