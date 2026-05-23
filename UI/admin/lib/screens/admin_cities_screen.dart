import 'package:admin/models/city_model.dart';
import 'package:admin/providers/city_provider.dart';
import 'package:admin/widgets/admin_dialog_widgets.dart';
import 'package:admin/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class AdminCitiesScreen extends StatefulWidget {
  const AdminCitiesScreen({super.key});

  @override
  State<AdminCitiesScreen> createState() => _AdminCitiesScreenState();
}

class _AdminCitiesScreenState extends State<AdminCitiesScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CityProvider>().getAllCities(pageSize: 1000);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _isSearching = true);
    await context.read<CityProvider>().getAllCities(pageSize: 1000);
    if (mounted) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _refresh() async {
    _searchController.clear();
    await context.read<CityProvider>().getAllCities(pageSize: 1000);
  }

  Future<void> _openCityDialog({City? city}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CityDialog(city: city),
    );
  }

  Future<void> _deleteCity(City city) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AdminDialogHeader(
                icon: Icons.delete_outline,
                title: 'Obriši grad',
                color: kDanger,
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Da li ste sigurni da želite obrisati grad "${city.name}"?',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              AdminDialogFooter(
                children: [
                  const AdminCancelButton(),
                  const SizedBox(width: 12),
                  AdminPrimaryButton(
                    label: 'Obriši',
                    icon: Icons.delete_outline,
                    color: kDanger,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await context.read<CityProvider>().deleteCity(city.id);
    if (!mounted) return;

    final provider = context.read<CityProvider>();
    SnackBarHelper.showMessage(
      context,
      ok ? 'Grad je obrisan.' : (provider.errorMessage ?? 'Brisanje nije uspjelo.'),
      ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PageHeader.build(title: 'Gradovi'),
                const Spacer(),
                CommonButtons.buildAddButton(
                  onPressed: () => _openCityDialog(),
                  label: 'Dodaj grad',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: SearchContainerStyle.buildDecoration(),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: SearchFieldDecoration.buildInputDecoration(
                        labelText: 'Naziv grada',
                        icon: Icons.location_city_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CommonButtons.buildClearButton(onPressed: _refresh),
                  const SizedBox(width: 12),
                  CommonButtons.buildSearchButton(
                    onPressed: _search,
                    isLoading: _isSearching,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer<CityProvider>(
                builder: (context, provider, _) {
                  final cities = provider.cities.where((city) {
                    final query = _searchController.text.trim().toLowerCase();
                    return query.isEmpty || city.name.toLowerCase().contains(query);
                  }).toList();

                  if (provider.isLoading && cities.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (cities.isEmpty) {
                    return const Center(child: Text('Nema dostupnih gradova.'));
                  }

                  return Container(
                    decoration: SearchContainerStyle.buildDecoration(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: cities.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final city = cities[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: kPrimary.withValues(alpha: 0.1),
                            child: const Icon(Icons.location_city, color: kPrimary),
                          ),
                          title: Text(
                            city.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            'Lat: ${city.latitude.toStringAsFixed(4)} | Lng: ${city.longitude.toStringAsFixed(4)}',
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                tooltip: 'Uredi grad',
                                onPressed: () => _openCityDialog(city: city),
                                icon: const Icon(Icons.edit_outlined, color: kPrimary),
                              ),
                              IconButton(
                                tooltip: 'Obriši grad',
                                onPressed: () => _deleteCity(city),
                                icon: const Icon(Icons.delete_outline, color: kDanger),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityDialog extends StatefulWidget {
  final City? city;

  const _CityDialog({this.city});

  @override
  State<_CityDialog> createState() => _CityDialogState();
}

class _CityDialogState extends State<_CityDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late LatLng _pickedLocation;
  final MapController _mapController = MapController();
  bool _isSaving = false;

  bool get _isEdit => widget.city != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.city?.name ?? '');
    _latitudeController = TextEditingController(
      text: widget.city?.latitude.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.city?.longitude.toString() ?? '',
    );
    _pickedLocation = LatLng(
      widget.city?.latitude ?? 43.8563,
      widget.city?.longitude ?? 18.4131,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

    if (name.length < 2 || latitude == null || longitude == null) {
      SnackBarHelper.showError(context, 'Unesite validan naziv i koordinate grada.');
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<CityProvider>();

    final city = _isEdit
        ? await provider.updateCity(
            cityId: widget.city!.id,
            name: name,
            latitude: latitude,
            longitude: longitude,
          )
        : await provider.createCity(
            name: name,
            latitude: latitude,
            longitude: longitude,
          );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (city == null) {
      SnackBarHelper.showError(
        context,
        provider.errorMessage ?? 'Spremanje grada nije uspjelo.',
      );
      return;
    }

    Navigator.pop(context);
    SnackBarHelper.showSuccess(
      context,
      _isEdit ? 'Grad je ažuriran.' : 'Grad je uspješno kreiran.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminDialogHeader(
              icon: _isEdit ? Icons.edit_location_alt_outlined : Icons.add_location_alt_outlined,
              title: _isEdit ? 'Uredi grad' : 'Dodaj grad',
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  AdminFormField(
                    controller: _nameController,
                    label: 'Naziv grada',
                    icon: Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AdminFormField(
                          controller: _latitudeController,
                          label: 'Latitude',
                          icon: Icons.my_location_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdminFormField(
                          controller: _longitudeController,
                          label: 'Longitude',
                          icon: Icons.explore_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 260,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _pickedLocation,
                          initialZoom: 13,
                          onTap: (_, point) {
                            setState(() {
                              _pickedLocation = point;
                              _latitudeController.text = point.latitude.toStringAsFixed(6);
                              _longitudeController.text = point.longitude.toStringAsFixed(6);
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'parkify.admin',
                          ),
                          MarkerLayer(markers: [
                            Marker(
                              point: _pickedLocation,
                              width: 44,
                              height: 44,
                              child: const Icon(Icons.location_pin, size: 40, color: kPrimary),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: kPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Klikni na mapu da odabereš lokaciju grada.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AdminDialogFooter(
              children: [
                const AdminCancelButton(),
                const SizedBox(width: 12),
                AdminPrimaryButton(
                  label: _isEdit ? 'Sačuvaj izmjene' : 'Kreiraj grad',
                  icon: Icons.save_outlined,
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}