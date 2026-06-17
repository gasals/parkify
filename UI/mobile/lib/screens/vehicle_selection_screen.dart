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
  IconData _getIconForCategory(VehicleCategory category) {
    switch (category) {
      case VehicleCategory.am:
      case VehicleCategory.a1:
      case VehicleCategory.a2:
      case VehicleCategory.a:
        return Icons.motorcycle;
      case VehicleCategory.b:
      case VehicleCategory.be:
        return Icons.directions_car;
      case VehicleCategory.c1:
      case VehicleCategory.c1e:
      case VehicleCategory.c:
      case VehicleCategory.ce:
      case VehicleCategory.f:
      case VehicleCategory.g:
      case VehicleCategory.h:
        return Icons.local_shipping;
      case VehicleCategory.d1:
      case VehicleCategory.d1e:
      case VehicleCategory.d:
      case VehicleCategory.de:
        return Icons.directions_bus;
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
        title: const Text("Odaberite vozilo"),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.vehicles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.vehicles.isEmpty) {
            return const Center(
              child: Text("Došlo je do greške pri učitavanju vozila."),
            );
          }
          if (provider.vehicles.isEmpty) {
            return const Center(
              child: Text("Nemate dodanih vozila.\nPritisnite + da dodate."),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
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
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: isSelected ? 4 : 1,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: isSelected
                            ? BorderSide(color: AppColors.primary, width: 2)
                            : BorderSide(color: Colors.grey.shade300),
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
                          '${vehicle.model} - ${vehicle.categoryLabel}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
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
                        onTap: () => provider.selectVehicle(vehicle),
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
        backgroundColor: AppColors.primary,
        tooltip: 'Dodaj vozilo',
        child: const Icon(Icons.add),
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
  late VehicleCategory _category;
  bool _isLoading = false;

  static final _modelRegex = RegExp(r'^[A-Za-z0-9\s\-\.]{2,50}$');

  @override
  void initState() {
    super.initState();
    _licensePlateController = TextEditingController(
      text: widget.vehicle?.licensePlate ?? '',
    );
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _category = widget.vehicle?.category ?? VehicleCategory.b;
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  String? _validatePlate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Registracija je obavezna';
    if (v.trim().length > 50) {
      return 'Registracija ne smije imati više od 50 znakova';
    }
    return null;
  }

  String? _validateModel(String? v) {
    if (v == null || v.trim().isEmpty) return 'Model vozila je obavezan';
    if (v.trim().length < 2) return 'Model mora imati najmanje 2 znaka';
    if (v.trim().length > 50) return 'Model ne smije imati više od 50 znakova';
    if (!_modelRegex.hasMatch(v.trim())) {
      return 'Model smije sadržavati slova, brojeve, razmak i crticu';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicle != null;
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
                textCapitalization: TextCapitalization.characters,
                enabled: !_isLoading,
                validator: _validatePlate,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Registracija',
                  prefixIcon: const Icon(
                    Icons.directions_car,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _modelController,
                enabled: !_isLoading,
                validator: _validateModel,
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<VehicleCategory>(
                value: _category,
                validator: (v) => v == null ? 'Kategorija je obavezna' : null,
                items: const [
                  DropdownMenuItem(
                    value: VehicleCategory.am,
                    child: Text('AM'),
                  ),
                  DropdownMenuItem(
                    value: VehicleCategory.a1,
                    child: Text('A1'),
                  ),
                  DropdownMenuItem(
                    value: VehicleCategory.a2,
                    child: Text('A2'),
                  ),
                  DropdownMenuItem(value: VehicleCategory.a, child: Text('A')),
                  DropdownMenuItem(value: VehicleCategory.b, child: Text('B')),
                  DropdownMenuItem(
                    value: VehicleCategory.be,
                    child: Text('B E'),
                  ),
                  DropdownMenuItem(
                    value: VehicleCategory.c1,
                    child: Text('C1'),
                  ),
                  DropdownMenuItem(
                    value: VehicleCategory.c1e,
                    child: Text('C1 E'),
                  ),
                  DropdownMenuItem(value: VehicleCategory.c, child: Text('C')),
                  DropdownMenuItem(
                    value: VehicleCategory.ce,
                    child: Text('C E'),
                  ),
                  DropdownMenuItem(
                    value: VehicleCategory.d1,
                    child: Text('D1'),
                  ),
                  DropdownMenuItem(
                    value: VehicleCategory.d1e,
                    child: Text('D1 E'),
                  ),
                  DropdownMenuItem(value: VehicleCategory.d, child: Text('D')),
                  DropdownMenuItem(
                    value: VehicleCategory.de,
                    child: Text('D E'),
                  ),
                  DropdownMenuItem(value: VehicleCategory.f, child: Text('F')),
                  DropdownMenuItem(value: VehicleCategory.g, child: Text('G')),
                  DropdownMenuItem(value: VehicleCategory.h, child: Text('H')),
                ],
                onChanged: _isLoading
                    ? null
                    : (v) => setState(() => _category = v!),
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

      final success = widget.vehicle == null
          ? await vehicleProvider.addVehicle(
              userId: authProvider.user!.id,
              licensePlate: _licensePlateController.text.trim(),
              category: _category,
              model: _modelController.text.trim(),
            )
          : await vehicleProvider.updateVehicle(
              vehicleId: widget.vehicle!.id,
              licensePlate: _licensePlateController.text.trim(),
              category: _category,
              model: _modelController.text.trim(),
            );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (widget.vehicle == null
                        ? 'Vozilo dodano'
                        : 'Vozilo ažurirano')
                  : 'Greška pri spremanju',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) Navigator.pop(context);
      }
    } catch (_) {
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
