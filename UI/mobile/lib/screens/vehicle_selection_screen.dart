import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle_model.dart';
import '../providers/vehicle_provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';

class VehicleSelectionScreen extends StatefulWidget {
  @override
  _VehicleSelectionScreenState createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'A':
        return Icons.motorcycle;
      case 'B':
        return Icons.directions_car;
      case 'C':
        return Icons.local_shipping;
      case 'D':
        return Icons.directions_bus;
      default:
        return Icons.directions_car;
    }
  }

  void _showVehicleFormSheet({Vehicle? vehicle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => VehicleFormSheet(vehicle: vehicle),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<VehicleProvider>(
          context,
          listen: false,
        ).fetchUserVehicles(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Odaberite vozilo"),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.vehicles.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.vehicles.isEmpty) {
            debugPrint('VehicleSelectionScreen error: ${provider.errorMessage}');
            return const Center(child: Text("Došlo je do greške pri učitavanju vozila."));
          }

          if (provider.vehicles.isEmpty) {
            return Center(
              child: Text("Nemate dodanih vozila.\nPritisnite + da dodate."),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Odaberite vozilo za trenutnu sesiju parkiranja",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = provider.vehicles[index];
                    final isSelected =
                        provider.selectedVehicle?.id == vehicle.id;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: isSelected ? 4 : 1,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: isSelected
                            ? BorderSide(color: AppColors.primary, width: 2)
                            : BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      child: ListTile(
                        leading: Icon(
                          _getIconForCategory(vehicle.category),
                          color: isSelected ? AppColors.primary : Colors.grey,
                          size: 30,
                        ),
                        title: Text(
                          vehicle.licensePlate,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          "${vehicle.model} - ${vehicle.category}",
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.grey),
                              onPressed: () =>
                                  _showVehicleFormSheet(vehicle: vehicle),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey,
                            ),
                          ],
                        ),
                        onTap: () {
                          provider.selectVehicle(vehicle);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVehicleFormSheet(),
        child: Icon(Icons.add),
        backgroundColor: AppColors.primary,
        tooltip: 'Dodaj vozilo',
      ),
    );
  }
}

class VehicleFormSheet extends StatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormSheet({Key? key, this.vehicle}) : super(key: key);

  @override
  State<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _licensePlateController;
  late TextEditingController _modelController;
  late String _category;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _licensePlateController = TextEditingController(
      text: widget.vehicle?.licensePlate ?? '',
    );
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _category = widget.vehicle?.category ?? 'A';
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.vehicle != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Uredi vozilo' : 'Dodaj novo vozilo',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: Navigator.of(context).pop,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _licensePlateController,
                decoration: InputDecoration(
                  labelText: 'Registracija (npr. A00-K-000)',
                  prefixIcon: const Icon(
                    Icons.directions_car,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Unesite registraciju' : null,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: 'Model (npr. VW Golf)',
                  prefixIcon: const Icon(
                    Icons.settings,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Unesite model' : null,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                items: ['A', 'B', 'C', 'D']
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
                decoration: InputDecoration(
                  labelText: 'Kategorija',
                  prefixIcon: const Icon(
                    Icons.category,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : Navigator.of(context).pop,
                      child: const Text('Otkaži'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              isEditing ? 'Spremi' : 'Dodaj',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final vehicleProvider = Provider.of<VehicleProvider>(
        context,
        listen: false,
      );

      bool success = false;
      if (widget.vehicle == null) {
        success = await vehicleProvider.addVehicle(
          userId: authProvider.user!.id,
          licensePlate: _licensePlateController.text,
          category: _category,
          model: _modelController.text,
        );
      } else {
        success = await vehicleProvider.updateVehicle(
          vehicleId: widget.vehicle!.id,
          userId: authProvider.user!.id,
          licensePlate: _licensePlateController.text,
          category: _category,
          model: _modelController.text,
        );
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.vehicle == null ? 'Vozilo dodano' : 'Vozilo ažurirano',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Greška pri spremanju'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('VehicleSelectionScreen._submitForm error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Došlo je do greške. Pokušajte ponovno.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
