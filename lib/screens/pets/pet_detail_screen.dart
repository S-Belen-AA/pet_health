import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:pet_health/models/pet_model.dart';
import 'package:pet_health/providers/pet_provider.dart';
import 'package:pet_health/screens/pets/pet_form_screen.dart';
import 'package:pet_health/services/vaccine_protocol_service.dart';
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
  bool _isDeleting = false;
  bool _isExportingPdf = false;
  var _vaccines = [];
  var _dewormings = [];
  var _visits = [];

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _loadAllHistory();
  }

  Widget _buildPetAvatar(PetModel pet, {required double size}) {
    final value = pet.morph_emoji;
    if (value != null && value.startsWith('animalitos/')) {
      return Image.asset(
        value,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text(
          pet.species == 'Perro' ? '🐕' : '🐈',
          style: TextStyle(fontSize: size * 0.8),
        ),
      );
    }

    return Text(
      value ?? (pet.species == 'Perro' ? '🐕' : '🐈'),
      style: TextStyle(fontSize: size * 0.8),
    );
  }

  Future<void> _confirmAndDeletePet() async {
    if (_isDeleting || _pet.id == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar mascota'),
          content: Text(
            '¿Seguro que deseas eliminar a ${_pet.name} de forma permanente?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final petName = _pet.name;
      await Provider.of<PetProvider>(context, listen: false).deletePet(_pet.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$petName fue eliminada.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _vaccineExpiryStatusText(String? isoDate) {
    if (isoDate == null || isoDate.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(isoDate.trim());
    if (parsed == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(parsed.year, parsed.month, parsed.day);
    final diffDays = expiry.difference(today).inDays;

    if (diffDays < 0) {
      return 'Vencida';
    } else if (diffDays <= 30) {
      return 'Próxima a vencer';
    }
    return 'Vigente';
  }

  Color _vaccineExpiryStatusColor(String status) {
    switch (status) {
      case 'Vencida':
        return Colors.red.shade700;
      case 'Próxima a vencer':
        return Colors.orange.shade800;
      default:
        return Colors.green.shade700;
    }
  }

  Future<Uint8List> _buildMedicalPdfBytes() async {
    final doc = pw.Document();
    final birth = _pet.parsedBirthDate;
    final nextBday = _pet.nextBirthdayDate;
    final daysLeft = _pet.daysUntilBirthday;
    final upcomingAge = _pet.upcomingAgeYears;
    final estLabel = _pet.isBirthDateEstimated ? 'Estimada' : 'Exacta';

    final profileLines = <String>[
      'Nombre: ${_pet.name}',
      'Especie: ${_pet.species}',
      if (_pet.breed != null) 'Raza / Tipo: ${_pet.breed}',
      'Sexo: ${_pet.sex ?? 'No registrado'}',
      'Peso: ${_pet.weight} kg',
      'Edad actual: ${_pet.formattedAge}',
      if (birth != null)
        'Fecha de nacimiento: ${_formatDateEs(birth)} ($estLabel)',
      if (nextBday != null && daysLeft != null && upcomingAge != null)
        'Proximo cumpleanos ($estLabel): ${_formatDateEs(nextBday)} — faltan $daysLeft dias (cumplira $upcomingAge ${upcomingAge == 1 ? 'ano' : 'anos'})',
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'Ficha Medica Veterinaria — ${_pet.name}',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Emitido el ${_formatDateEs(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Divider(height: 20),
          pw.Text(
            'Datos de la Mascota',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...profileLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(line, style: const pw.TextStyle(fontSize: 11)),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Historial de Atenciones Veterinarias',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (_visits.isEmpty)
            pw.Text(
              'Sin consultas registradas.',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            )
          else
            ..._visits.map(
              (v) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${v['visit_date']} — ${v['reason']}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (v['clinic_or_vet'] != null)
                      pw.Text(
                        'Clinica / Vet: ${v['clinic_or_vet']}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (v['observations'] != null)
                      pw.Text(
                        'Observaciones: ${v['observations']}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (v['treatment'] != null)
                      pw.Text(
                        'Tratamiento: ${v['treatment']}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),
            ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Vacunas',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (_vaccines.isEmpty)
            pw.Text(
              'Sin vacunas registradas.',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            )
          else
            ..._vaccines.map((vac) {
              final expDate =
                  (vac['expiry_date'] ?? vac['next_due_date'])?.toString();
              final expStatus = _vaccineExpiryStatusText(expDate);
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${vac['vaccine_name'] ?? 'Vacuna'} (Aplicada: ${vac['date_applied']})',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (expDate != null && expDate.isNotEmpty)
                      pw.Text(
                        'Fecha de expiracion / refuerzo: $expDate${expStatus.isNotEmpty ? ' ($expStatus)' : ''}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (vac['provider_or_clinic'] != null)
                      pw.Text(
                        'Clinica / Vet: ${vac['provider_or_clinic']}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (vac['notes'] != null)
                      pw.Text(
                        'Observaciones: ${vac['notes']}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              );
            }),
          pw.SizedBox(height: 14),
          pw.Text(
            'Desparasitaciones',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (_dewormings.isEmpty)
            pw.Text(
              'Sin desparasitaciones registradas.',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            )
          else
            ..._dewormings.map(
              (dew) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${dew['product_name']} (${dew['date_applied']})',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (dew['next_due_date'] != null)
                      pw.Text(
                        'Proxima fecha: ${dew['next_due_date']}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (dew['provider_or_clinic'] != null)
                      pw.Text(
                        'Clinica / Vet: ${dew['provider_or_clinic']}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (dew['notes'] != null)
                      pw.Text(
                        'Observaciones: ${dew['notes']}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _exportAndSharePdf() async {
    if (_isExportingPdf) return;
    setState(() => _isExportingPdf = true);

    try {
      final bytes = await _buildMedicalPdfBytes();
      final safeName = _pet.name
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      final fileName =
          'ficha_${safeName.isEmpty ? 'mascota' : safeName}.pdf';

      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar o compartir el PDF: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
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

  String _toIsoDateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')
        .first;
  }

  Future<void> _pickDateForController(
    TextEditingController controller, {
    VoidCallback? onDatePicked,
  }) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(controller.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1995, 1, 1),
      lastDate: DateTime(2040, 12, 31),
    );
    if (picked != null) {
      controller.text = _toIsoDateOnly(picked);
      onDatePicked?.call();
    }
  }

  Future<void> _openAddVaccineModal() async {
    final petId = _pet.id;
    if (petId == null) return;

    final options = VaccineProtocolService.optionsForSpecies(_pet.species);
    String selectedVaccine = options.first.name;
    bool isPrimarySeriesBooster = _pet.age < 5;

    final now = DateTime.now();
    final dateCtrl = TextEditingController(text: _toIsoDateOnly(now));

    void syncExpirationPreview(
      void Function(void Function()) setModalState,
      TextEditingController nextDueCtrl,
    ) {
      final applied = DateTime.tryParse(dateCtrl.text.trim()) ?? DateTime.now();
      final expiry = VaccineProtocolService.calculateExpirationDate(
        species: _pet.species,
        vaccineName: selectedVaccine,
        dateApplied: applied,
        isPrimarySeriesBooster: isPrimarySeriesBooster,
      );
      setModalState(() {
        nextDueCtrl.text = expiry != null ? _toIsoDateOnly(expiry) : '';
      });
    }

    final initialExpiry = VaccineProtocolService.calculateExpirationDate(
      species: _pet.species,
      vaccineName: selectedVaccine,
      dateApplied: now,
      isPrimarySeriesBooster: isPrimarySeriesBooster,
    );
    final nextDueCtrl = TextEditingController(
      text: initialExpiry != null ? _toIsoDateOnly(initialExpiry) : '',
    );
    final clinicCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final currentOption = VaccineProtocolService.optionByName(
            _pet.species,
            selectedVaccine,
          );

          return Padding(
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
                  Text(
                    'Registrar Vacuna (${_pet.species})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedVaccine,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Vacuna *',
                      border: OutlineInputBorder(),
                    ),
                    items: options.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt.name,
                        child: Text(opt.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      selectedVaccine = val;
                      syncExpirationPreview(setModalState, nextDueCtrl);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentOption.scheduleSummary,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<bool>(
                    value: isPrimarySeriesBooster,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Esquema de dosis',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<bool>(
                        value: false,
                        child: Text('Refuerzo anual / adulto (expira en 12 meses)'),
                      ),
                      DropdownMenuItem<bool>(
                        value: true,
                        child: Text('Serie inicial cachorro / gatito (refuerzo en 28 días)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      isPrimarySeriesBooster = val;
                      syncExpirationPreview(setModalState, nextDueCtrl);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dateCtrl,
                    readOnly: true,
                    onTap: () => _pickDateForController(
                      dateCtrl,
                      onDatePicked: () =>
                          syncExpirationPreview(setModalState, nextDueCtrl),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Fecha de aplicación *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nextDueCtrl,
                    readOnly: true,
                    onTap: () => _pickDateForController(
                      nextDueCtrl,
                      onDatePicked: () => setModalState(() {}),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Fecha de expiración / próximo refuerzo',
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
                        if (selectedVaccine.trim().isEmpty ||
                            dateCtrl.text.trim().isEmpty) {
                          return;
                        }
                        await Provider.of<PetProvider>(context, listen: false)
                            .addVaccineRecord(
                          petId: petId,
                          vaccineName: selectedVaccine,
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
          );
        },
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
      final expDate =
          (vac['expiry_date'] ?? vac['next_due_date'])?.toString();
      final status = _vaccineExpiryStatusText(expDate);

      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${vac['vaccine_name'] ?? 'Vacuna'} (Aplicada: ${vac['date_applied']})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (expDate != null && expDate.isNotEmpty)
                Row(
                  children: [
                    Flexible(
                      child: Text('Expiración / Refuerzo: $expDate'),
                    ),
                    if (status.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• $status',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _vaccineExpiryStatusColor(status),
                        ),
                      ),
                    ],
                  ],
                ),
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
                          _buildPetAvatar(_pet, size: 52),
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isDeleting ? null : _confirmAndDeletePet,
                      icon: _isDeleting
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red.shade600,
                              ),
                            )
                          : const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Eliminar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.08),
                        foregroundColor: Colors.red.shade600,
                        shadowColor: Colors.redAccent.withOpacity(0.2),
                        elevation: 2,
                        side: BorderSide(color: Colors.red.shade300, width: 1.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isExportingPdf ? null : _exportAndSharePdf,
                      style: ElevatedButton.styleFrom(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: _isExportingPdf
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
    );
  }
}