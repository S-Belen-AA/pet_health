import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_health/models/pet_model.dart';
import 'package:pet_health/providers/pet_provider.dart';
import 'package:pet_health/widgets/glass_card.dart';

class PetFormScreen extends StatefulWidget {
  final PetModel? initialPet;

  const PetFormScreen({super.key, this.initialPet});

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
  String _morphEmoji = 'animalitos/perros/Chihuahua.png';
  final String _activityLevel = 'Moderado';
  final String _bodyCondition = 'Ideal';

  // Razas habituales y reconocibles en hogares de Chile
  final List<String> _dogBreeds = [
    'Chihuahua',
    'Pastor Alemán',
    'Labrador Retriever',
    'Golden Retriever',
    'Poodle / Caniche',
    'Bulldog Francés',
    'Bulldog Inglés',
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
    'Pitbull / American bully',
    'Pastor de Shetland',
    'Akita Inu',
    'Samoyedo',
    'Dálmata',
    'Shih Tzu',
    'Maltés',
    'Bichón Frisé',
    'Galgo / Whippet',
  ];

  // Variantes por raza cuando existe más de un PNG en animalitos/perros/
  final Map<String, List<String>> _breedVariants = const {
    'Chihuahua': [
      'animalitos/perros/Chihuahua.png',
      'animalitos/perros/Chihuahua 2.png',
      'animalitos/perros/Chihuahua 3.png',
    ],
    'Pastor Alemán': [
      'animalitos/perros/Pastor Alemán.png',
      'animalitos/perros/Pastor Alemán 2.png',
    ],
    'Labrador Retriever': [
      'animalitos/perros/Labrador Retriever.png',
      'animalitos/perros/Labrador Retriever 2.png',
    ],
    'Poodle / Caniche': [
      'animalitos/perros/Poodle grande.png',
      'animalitos/perros/Poodle grande 2.png',
    ],
    'Husky Siberiano': [
      'animalitos/perros/Husky Siberiano.png',
      'animalitos/perros/Husky Siberiano 2.png',
      'animalitos/perros/Husky Siberiano 3.png',
    ],
    'Shih Tzu': [
      'animalitos/perros/Shih Tzu.png',
      'animalitos/perros/Shih Tzu 2.png',
    ],
  };

  // PNGs numerados de perros mestizos en animalitos/perros/
  final List<String> _quiltroAssets = const [
    'animalitos/perros/2.png',
    'animalitos/perros/3.png',
    'animalitos/perros/5.png',
    'animalitos/perros/6.png',
    'animalitos/perros/7.png',
    'animalitos/perros/8.png',
    'animalitos/perros/9.png',
    'animalitos/perros/10.png',
    'animalitos/perros/11.png',
    'animalitos/perros/12.png',
    'animalitos/perros/13.png',
    'animalitos/perros/14.png',
  ];

  // PNGs 1.png a 28.png de gatos en animalitos/gatos/
  final List<String> _catAssets = List.generate(
    28,
    (index) => 'animalitos/gatos/${index + 1}.png',
  );

  List<String> _variantsForBreed(String breed) {
    return _breedVariants[breed] ?? [_singleAssetForBreed(breed)];
  }

  String _singleAssetForBreed(String breed) {
    switch (breed) {
      case 'Chihuahua':
        return 'animalitos/perros/Chihuahua.png';
      case 'Pastor Alemán':
        return 'animalitos/perros/Pastor Alemán.png';
      case 'Labrador Retriever':
        return 'animalitos/perros/Labrador Retriever.png';
      case 'Golden Retriever':
        return 'animalitos/perros/Golden Retriever.png';
      case 'Poodle / Caniche':
        return 'animalitos/perros/Poodle grande.png';
      case 'Bulldog Francés':
        return 'animalitos/perros/Bulldog Francés.png';
      case 'Bulldog Inglés':
        return 'animalitos/perros/Bulldog Inglés.png';
      case 'Pug / Carlino':
        return 'animalitos/perros/Pug.png';
      case 'Salchicha (Dachshund)':
        return 'animalitos/perros/Salchicha.png';
      case 'Beagle':
        return 'animalitos/perros/Beagle.png';
      case 'Cocker Spaniel':
        return 'animalitos/perros/Cocker Spaniel.png';
      case 'Bóxer':
        return 'animalitos/perros/Bóxer.png';
      case 'Schnauzer':
        return 'animalitos/perros/Schnauzer.png';
      case 'Border Collie':
        return 'animalitos/perros/Border Collie.png';
      case 'Yorkshire Terrier':
        return 'animalitos/perros/Yorkshire Terrier.png';
      case 'Jack Russell Terrier':
        return 'animalitos/perros/Jack Russell Terrier.png';
      case 'Husky Siberiano':
        return 'animalitos/perros/Husky Siberiano.png';
      case 'Rottweiler':
        return 'animalitos/perros/Rottweiler.png';
      case 'Pitbull / American bully':
        return 'animalitos/perros/Pitbull.png';
      case 'Pastor de Shetland':
        return 'animalitos/perros/Pastor de Shetland.png';
      case 'Akita Inu':
        return 'animalitos/perros/Akita Inu.png';
      case 'Samoyedo':
        return 'animalitos/perros/Samoyedo.png';
      case 'Dálmata':
        return 'animalitos/perros/Dálmata.png';
      case 'Shih Tzu':
        return 'animalitos/perros/Shih Tzu.png';
      case 'Maltés':
        return 'animalitos/perros/Maltés.png';
      case 'Bichón Frisé':
        return 'animalitos/perros/Bichón Frisé.png';
      case 'Galgo / Whippet':
        return 'animalitos/perros/Greyhound.png';
      default:
        return 'animalitos/perros/2.png';
    }
  }

  Widget _buildPetAppearanceImage(String value, {required double size}) {
    if (value.startsWith('animalitos/')) {
      return Image.asset(
        value,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.pets, size: size * 0.8),
      );
    }
    return Text(
      value,
      style: TextStyle(fontSize: size * 0.85),
      textAlign: TextAlign.center,
    );
  }

  Future<void> _openAssetPicker({
    required String title,
    required List<String> assets,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final assetPath = assets[index];
                    final isCurrent = _morphEmoji == assetPath;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(sheetContext, assetPath),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: _buildPetAppearanceImage(assetPath, size: 64),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _morphEmoji = selected;
      });
    }
  }

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

  Widget _buildEmojiSection() {
    if (_species == 'Perro' && !_isQuiltro) {
      final variants = _variantsForBreed(_selectedBreed);
      final hasMultipleVariants = variants.length > 1;

      if (hasMultipleVariants) {
        return GlassCard(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Apariencia',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _openAssetPicker(
                    title: 'Selecciona apariencia',
                    assets: variants,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPetAppearanceImage(_morphEmoji, size: 64),
                      const SizedBox(height: 6),
                      const Text('Seleccionar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return GlassCard(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Apariencia',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _buildPetAppearanceImage(_morphEmoji, size: 76),
            ],
          ),
        ),
      );
    }

    if (_species == 'Perro' && _isQuiltro) {
      return GlassCard(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Apariencia',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _openAssetPicker(
                  title: 'Selecciona apariencia',
                  assets: _quiltroAssets,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPetAppearanceImage(_morphEmoji, size: 64),
                    const SizedBox(height: 6),
                    const Text('Seleccionar'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Apariencia',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _openAssetPicker(
                title: 'Selecciona apariencia',
                assets: _catAssets,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPetAppearanceImage(_morphEmoji, size: 68),
                  const SizedBox(height: 6),
                  const Text('Seleccionar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewMonths = !_useManualAgeFallback && _birthDate != null
        ? _calculateMonthsFromBirthDate(_birthDate!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rellenar Formulario'),
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
                          if (_species == 'Perro') {
                            _morphEmoji = _isQuiltro
                                ? _quiltroAssets.first
                                : _singleAssetForBreed(_selectedBreed);
                          } else {
                            _morphEmoji = _catAssets.first;
                          }
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _useManualAgeFallback ? 'Edad' : 'Fecha de nacimiento',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                      OutlinedButton(
                        onPressed: _pickBirthDate,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          _birthDate == null
                              ? 'Seleccionar fecha'
                              : _formatDateEs(_birthDate!),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mestizo'),
                          Switch(
                            value: _isQuiltro,
                            onChanged: (val) {
                              setState(() {
                                _isQuiltro = val;
                                if (!_isQuiltro) {
                                  _morphEmoji = _singleAssetForBreed(_selectedBreed);
                                } else {
                                  _morphEmoji = _quiltroAssets.first;
                                }
                              });
                            },
                          ),
                        ],
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
                          items: _dogBreeds.map((breed) {
                            return DropdownMenuItem(value: breed, child: Text(breed));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedBreed = val;
                                _morphEmoji = _singleAssetForBreed(val);
                              });
                            }
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
              _buildEmojiSection(),
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
                          'Guardar',
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