import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_health/models/pet_model.dart';
import 'package:pet_health/models/vaccine_model.dart';
import 'package:pet_health/providers/vaccine_provider.dart';
import 'package:pet_health/widgets/glass_card.dart';

class PetVaccinesScreen extends StatefulWidget {
  final PetModel pet;

  const PetVaccinesScreen({super.key, required this.pet});

  @override
  State<PetVaccinesScreen> createState() => _PetVaccinesScreenState();
}

class _PetVaccinesScreenState extends State<PetVaccinesScreen> {
  @override
  void initState() {
    super.initState();
    // Cargamos el historial de vacunas de esta mascota y el catálogo filtrado por su especie al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vaccineProvider = Provider.of<VaccineProvider>(context, listen: false);
      vaccineProvider.loadVaccinesForPet(widget.pet.id!);
      vaccineProvider.loadCatalogForSpecies(widget.pet.species);
    });
  }

  // Diálogo para seleccionar y aplicar una vacuna del catálogo
  void _showApplyVaccineModal(BuildContext context) {
    final vaccineProvider = Provider.of<VaccineProvider>(context, listen: false);
    VaccineModel? selectedVaccine = vaccineProvider.catalogVaccines.isNotEmpty
        ? vaccineProvider.catalogVaccines.first
        : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Aplicar Vacuna a ${widget.pet.name} 💉'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              if (vaccineProvider.catalogVaccines.isEmpty) {
                return const Text('No hay vacunas disponibles para esta especie.');
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selecciona la vacuna del catálogo chileno:'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<VaccineModel>(
                    value: selectedVaccine,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: vaccineProvider.catalogVaccines.map((vac) {
                      return DropdownMenuItem(
                        value: vac,
                        child: Text('${vac.name} (${vac.validityMonths} meses)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedVaccine = val;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedVaccine == null
                  ? null
                  : () {
                      vaccineProvider.applyVaccine(
                        petId: widget.pet.id!,
                        vaccineId: selectedVaccine!.id!,
                        validityMonths: selectedVaccine!.validityMonths,
                        dateApplied: DateTime.now(),
                      );
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('¡Vacuna ${selectedVaccine!.name} aplicada con éxito!')),
                      );
                    },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaccineProvider = Provider.of<VaccineProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cartilla: ${widget.pet.name} ${widget.pet.morph_emoji ?? "🐾"}'),
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
        child: Column(
          children: [
            // Cabecera con datos de la mascota
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassCard(
                child: Row(
                  children: [
                    Text(widget.pet.morph_emoji ?? '🐶', style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.pet.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${widget.pet.species} • ${widget.pet.breed ?? "Quiltro"} • ${widget.pet.weight} kg'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Listado de vacunas aplicadas e historial
            Expanded(
              child: vaccineProvider.petVaccines.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: GlassCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.vaccines, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'Sin vacunas registradas en la cartilla.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Presiona el botón "+" abajo para registrar la aplicación de una vacuna.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: vaccineProvider.petVaccines.length,
                      itemBuilder: (context, index) {
                        final applied = vaccineProvider.petVaccines[index];
                        final isActive = applied.status == 'Activa';

                        return GlassCard(
                          child: ListTile(
                            leading: Icon(
                              isActive ? Icons.verified_rounded : Icons.warning_amber_rounded,
                              color: isActive ? Colors.green : Colors.orangeAccent,
                              size: 32,
                            ),
                            title: Text(
                              applied.vaccineName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Aplicada: ${applied.dateApplied.substring(0, 10)}\nVence: ${applied.expiryDate.substring(0, 10)}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(
                                    applied.status,
                                    style: TextStyle(
                                      color: isActive ? Colors.green.shade900 : Colors.orange.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: isActive ? Colors.green.shade100 : Colors.orange.shade100,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    vaccineProvider.removeAppliedVaccine(applied.id, widget.pet.id!);
                                  },
                                  tooltip: 'Eliminar registro',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplyVaccineModal(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add_task, color: Colors.black87),
        label: const Text('Aplicar Vacuna', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }
}