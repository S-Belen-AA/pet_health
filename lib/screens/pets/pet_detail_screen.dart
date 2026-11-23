import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_health/models/pet_model.dart';
import 'package:pet_health/providers/pet_provider.dart';
import 'package:pet_health/screens/pets/pet_form_screen.dart';
import 'package:pet_health/widgets/glass_card.dart';

class PetDetailScreen extends StatefulWidget {
  final PetModel pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  late PetModel _pet;
  bool _loadingHistory = true;
  var _vaccines = [];
  var _dewormings = [];
  var _visits = [];

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _loadAllHistory();
  }

  Future<void> _loadAllHistory() async {
    final petId = _pet.id;
    if (petId == null) {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _loadingHistory = true);
    }

    final provider = Provider.of<PetProvider>(context, listen: false);
    dynamic rawVaccines = [];
    dynamic rawDewormings = [];
    dynamic rawVisits = [];

    try {
      rawVaccines = await provider.getVaccinesForPet(petId);
    } catch (e) {
      debugPrint('Error cargando vacunas: $e');
    }

    try {
      rawDewormings = await provider.getDewormingsForPet(petId);
    } catch (e) {
      debugPrint('Error cargando desparasitaciones: $e');
    }

    try {
      rawVisits = await provider.getVetVisitsForPet(petId);
    } catch (e) {
      debugPrint('Error cargando consultas: $e');
    }

    if (!mounted) return;
    setState(() {
      _vaccines = _normalizeRows(rawVaccines);
      _dewormings = _normalizeRows(rawDewormings);
      _visits = _normalizeRows(rawVisits);
      _loadingHistory = false;
    });
  }

  _normalizeRows(dynamic raw) {
    final result = [];
    if (raw != null) {
      for (final item in raw) {
        if (item is Map) {
          final normalized = {};
          item.forEach((k, v) {
            normalized[k.toString()] = v;
          });
          result.add(normalized);
        }
      }
    }
    return result;
  }

  String _formatDateEs(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _pickDateForController(TextEditingController controller) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(controller.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1995, 1, 1),
      lastDate: DateTime(2040, 12, 31),
    );
    if (picked != null) {
      final normalized = DateTime(picked.year, picked.month, picked.day)
          .toIso8601String()
          .split('T')
          .first;
      controller.text = normalized;
    }
  }

  Future<void> _openAddVaccineModal() async {
    final petId = _pet.id;
    if (petId == null) return;

    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    final nextDueCtrl = TextEditingController();
    final clinicCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrar Vacuna',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la vacuna *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateCtrl,
                readOnly: true,
                onTap: () => _pickDateForController(dateCtrl),
                decoration: const InputDecoration(
                  labelText: 'Fecha de aplicación (YYYY-MM-DD) *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nextDueCtrl,
                readOnly: true,
                onTap: () => _pickDateForController(nextDueCtrl),
                decoration: const InputDecoration(
                  labelText: 'Próxima dosis (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: clinicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Clínica o veterinario (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        dateCtrl.text.trim().isEmpty) {
                      return;
                    }
                    await Provider.of<PetProvider>(context, listen: false)
                        .addVaccineRecord(
                      petId: petId,
                      vaccineName: nameCtrl.text,
                      dateApplied: dateCtrl.text.trim(),
                      nextDueDate: nextDueCtrl.text.trim().isEmpty
                          ? null
                          : nextDueCtrl.text.trim(),
                      providerOrClinic: clinicCtrl.text,
                      notes: notesCtrl.text,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadAllHistory();
                  },
                  child: const Text('Guardar Vacuna'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddDewormingModal() async {
    final petId = _pet.id;
    if (petId == null) return;

    final productCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    final nextDueCtrl = TextEditingController();
    final clinicCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrar Desparasitación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: productCtrl,
                decoration: const InputDecoration(
                  labelText: 'Producto administrado *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateCtrl,
                readOnly: true,
                onTap: () => _pickDateForController(dateCtrl),
                decoration: const InputDecoration(
                  labelText: 'Fecha de aplicación *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nextDueCtrl,
                readOnly: true,
                onTap: () => _pickDateForController(nextDueCtrl),
                decoration: const InputDecoration(
                  labelText: 'Próxima fecha (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: clinicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Clínica o veterinario (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (productCtrl.text.trim().isEmpty ||
                        dateCtrl.text.trim().isEmpty) {
                      return;
                    }
                    await Provider.of<PetProvider>(context, listen: false)
                        .addDewormingRecord(
                      petId: petId,
                      productName: productCtrl.text,
                      dateApplied: dateCtrl.text.trim(),
                      nextDueDate: nextDueCtrl.text.trim().isEmpty
                          ? null
                          : nextDueCtrl.text.trim(),
                      providerOrClinic: clinicCtrl.text,
                      notes: notesCtrl.text,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadAllHistory();
                  },
                  child: const Text('Guardar Desparasitación'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddVisitModal() async {
    final petId = _pet.id;
    if (petId == null) return;

    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    final reasonCtrl = TextEditingController();
    final clinicCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    final treatmentCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrar Consulta Veterinaria',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                readOnly: true,
                onTap: () => _pickDateForController(dateCtrl),
                decoration: const InputDecoration(
                  labelText: 'Fecha de consulta *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la visita *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: clinicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Clínica o veterinario (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: obsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: treatmentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tratamientos o indicaciones (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (reasonCtrl.text.trim().isEmpty ||
                        dateCtrl.text.trim().isEmpty) {
                      return;
                    }
                    await Provider.of<PetProvider>(context, listen: false)
                        .addVetVisitRecord(
                      petId: petId,
                      visitDate: dateCtrl.text.trim(),
                      reason: reasonCtrl.text,
                      clinicOrVet: clinicCtrl.text,
                      observations: obsCtrl.text,
                      treatment: treatmentCtrl.text,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadAllHistory();
                  },
                  child: const Text('Guardar Consulta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitsCard() {
    final items = <Widget>[];
    for (final v in _visits) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${v['visit_date']} — ${v['reason']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (v['clinic_or_vet'] != null)
                Text('Clínica / Vet: ${v['clinic_or_vet']}'),
              if (v['observations'] != null)
                Text('Observaciones: ${v['observations']}'),
              if (v['treatment'] != null)
                Text('Tratamiento: ${v['treatment']}'),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de Atenciones Veterinarias',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              'Todavía no hay consultas registradas para esta mascota. Puedes agregar una con el botón "Registrar consulta".',
            )
          else
            ...items,
        ],
      ),
    );
  }

  Widget _buildVaccinesCard() {
    final items = <Widget>[];
    for (final vac in _vaccines) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${vac['vaccine_name'] ?? 'Vacuna'} (${vac['date_applied']})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (vac['next_due_date'] != null)
                Text('Próxima dosis: ${vac['next_due_date']}'),
              if (vac['provider_or_clinic'] != null)
                Text('Clínica / Vet: ${vac['provider_or_clinic']}'),
              if (vac['notes'] != null)
                Text('Observaciones: ${vac['notes']}'),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vacunas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('Sin vacunas registradas todavía.')
          else
            ...items,
        ],
      ),
    );
  }

  Widget _buildDewormingsCard() {
    final items = <Widget>[];
    for (final dew in _dewormings) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dew['product_name']} (${dew['date_applied']})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (dew['next_due_date'] != null)
                Text('Próxima fecha: ${dew['next_due_date']}'),
              if (dew['provider_or_clinic'] != null)
                Text('Clínica / Vet: ${dew['provider_or_clinic']}'),
              if (dew['notes'] != null)
                Text('Observaciones: ${dew['notes']}'),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desparasitaciones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('Sin desparasitaciones registradas todavía.')
          else
            ...items,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final birth = _pet.parsedBirthDate;
    final nextBday = _pet.nextBirthdayDate;
    final daysLeft = _pet.daysUntilBirthday;
    final upcomingAge = _pet.upcomingAgeYears;
    final estLabel = _pet.isBirthDateEstimated ? 'Estimada' : 'Exacta';

    return Scaffold(
      appBar: AppBar(
        title: Text(_pet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar mascota',
            onPressed: () async {
              final updated = await Navigator.push<PetModel>(
                context,
                MaterialPageRoute(
                  builder: (_) => PetFormScreen(initialPet: _pet),
                ),
              );
              if (updated != null && mounted) {
                setState(() => _pet = updated);
              }
            },
          ),
        ],
      ),
      body: _loadingHistory
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _pet.morph_emoji ??
                                (_pet.species == 'Perro' ? '🐕' : '🐈'),
                            style: const TextStyle(fontSize: 38),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pet.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_pet.species}${_pet.breed != null ? ' • ${_pet.breed}' : ''}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Sexo: ${_pet.sex ?? 'No registrado'}'),
                      Text('Peso: ${_pet.weight} kg'),
                      Text('Edad actual: ${_pet.formattedAge}'),
                      if (birth != null)
                        Text(
                          'Fecha de nacimiento: ${_formatDateEs(birth)} ($estLabel)',
                        ),
                      if (nextBday != null &&
                          daysLeft != null &&
                          upcomingAge != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Próximo cumpleaños ($estLabel): ${_formatDateEs(nextBday)} — faltan $daysLeft días (cumplirá $upcomingAge ${upcomingAge == 1 ? 'año' : 'años'})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openAddVaccineModal,
                      icon: const Icon(Icons.vaccines),
                      label: const Text('Registrar vacuna'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openAddDewormingModal,
                      icon: const Icon(Icons.medication),
                      label: const Text('Registrar desparasitación'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openAddVisitModal,
                      icon: const Icon(Icons.medical_services),
                      label: const Text('Registrar consulta'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildVisitsCard(),
                const SizedBox(height: 12),
                _buildVaccinesCard(),
                const SizedBox(height: 12),
                _buildDewormingsCard(),
              ],
            ),
    );
  }
}