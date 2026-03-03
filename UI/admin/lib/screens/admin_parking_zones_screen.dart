import 'package:admin/widgets/admin_dialog_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/city_model.dart';
import '../models/parking_zone_model.dart';
import '../providers/parking_zone_provider.dart';
import '../widgets/common_widgets.dart';

class AdminParkingZonesScreen extends StatefulWidget {
  const AdminParkingZonesScreen({Key? key}) : super(key: key);

  @override
  State<AdminParkingZonesScreen> createState() =>
      _AdminParkingZonesScreenState();
}

class _AdminParkingZonesScreenState extends State<AdminParkingZonesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _nameController = TextEditingController();

  List<City> _allCities = [];
  City? _selectedFilterCity;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCities();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ParkingZoneProvider>(context, listen: false)
            .searchParkingZones(includeSpots: true);
      }
    });
  }

  Future<void> _loadCities() async {
    final cities = await Provider.of<ParkingZoneProvider>(
            context, listen: false)
        .searchCitiesLive();
    if (mounted) setState(() => _allCities = cities);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final p = Provider.of<ParkingZoneProvider>(context, listen: false);
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (p.currentPage < p.totalPages && !_isSearching) {
        p.searchParkingZones(
          name: _nameController.text.isEmpty ? null : _nameController.text,
          cityId: _selectedFilterCity?.id,
          page: p.currentPage + 1,
          includeSpots: true,
        );
      }
    }
  }

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);
    await Provider.of<ParkingZoneProvider>(context, listen: false)
        .searchParkingZones(
      name: _nameController.text.isEmpty ? null : _nameController.text,
      cityId: _selectedFilterCity?.id,
      includeSpots: true,
    );
    setState(() => _isSearching = false);
  }

  void _clearSearch() {
    _nameController.clear();
    setState(() => _selectedFilterCity = null);
    _performSearch();
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
            PageHeader.build(title: 'Parking lokacije'),
            const SizedBox(height: 24),
            _buildSearchContainer(),
            const SizedBox(height: 24),
            Expanded(child: _buildZonesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: SearchContainerStyle.buildDecoration(),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              decoration: SearchFieldDecoration.buildInputDecoration(
                labelText: 'Naziv zone',
                icon: Icons.map_outlined,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Grad filter — LOV lista
          Expanded(
            child: AdminDropdownField<City>(
              value: _selectedFilterCity,
              label: 'Grad',
              icon: Icons.location_city,
              items: _allCities,
              labelBuilder: (c) => c.name,
              onChanged: (c) => setState(() => _selectedFilterCity = c),
            ),
          ),
          const SizedBox(width: 12),
          CommonButtons.buildClearButton(onPressed: _clearSearch),
          const SizedBox(width: 12),
          CommonButtons.buildSearchButton(
              onPressed: _performSearch, isLoading: _isSearching),
          const SizedBox(width: 12),
          CommonButtons.buildAddButton(
              onPressed: _showAddZoneDialog, label: 'Dodaj zonu'),
        ],
      ),
    );
  }

  Widget _buildZonesList() {
    return Consumer<ParkingZoneProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.parkingZones.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.parkingZones.isEmpty) {
          return const Center(child: Text('Nema parking zona'));
        }
        return GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
          ),
          itemCount:
              provider.parkingZones.length + (provider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.parkingZones.length) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildZoneTile(provider.parkingZones[index], provider);
          },
        );
      },
    );
  }

  Widget _buildZoneTile(ParkingZone zone, ParkingZoneProvider provider) {
    final pct = zone.totalSpots > 0
        ? ((zone.totalSpots - zone.availableSpots) / zone.totalSpots) * 100
        : 0.0;
    final statusColor =
        pct < 40 ? Colors.green : pct < 70 ? Colors.orange : Colors.red;

    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zone.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(zone.address,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AdminStatusBadge(
                  label: zone.isActive ? 'AKTIVNA' : 'NEAKTIVNA',
                  color: zone.isActive ? Colors.green : Colors.red,
                  icon: zone.isActive ? Icons.check_circle : Icons.pause_circle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Stats
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(Icons.local_parking, '${zone.totalSpots}', 'Ukupno'),
                  _stat(Icons.event_available, '${zone.availableSpots}',
                      'Slobodno'),
                  _stat(Icons.accessible, '${zone.disabledSpots}', 'Invalidi'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Occupancy
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Popunjenost',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                Text('${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: zone.totalSpots > 0
                    ? (zone.totalSpots - zone.availableSpots) / zone.totalSpots
                    : 0,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 16),
            // ── Prices
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _priceInfo(
                    Icons.access_time, 'Cijena/sat', '${zone.pricePerHour} KM'),
                _priceInfo(Icons.wb_sunny, 'Dnevna', '${zone.dailyRate} KM'),
              ],
            ),
            const SizedBox(height: 16),
            // ── Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditZoneDialog(zone, provider),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: const Text('UREDI',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSpotsDialog(zone, provider),
                    icon: const Icon(Icons.grid_view_rounded, size: 16),
                    label: const Text('MJESTA', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimary,
                      side: const BorderSide(color: kPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleZoneActive(zone, provider),
                    icon: Icon(
                        zone.isActive
                            ? Icons.lock_outline
                            : Icons.lock_open_outlined,
                        size: 16),
                    label: Text(zone.isActive ? 'DEAKTIVIRAJ' : 'AKTIVIRAJ',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          zone.isActive ? Colors.red : Colors.green,
                      side: BorderSide(
                          color: zone.isActive ? Colors.red : Colors.green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: kPrimary),
        const SizedBox(height: 4),
        Text(value,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _priceInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(width: 6),
        Text(value,
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  void _showAddZoneDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddZoneDialog(
        allCities: _allCities,
        onConfirm: (data) async {
          final p = Provider.of<ParkingZoneProvider>(context, listen: false);
          final ok = await p.createParkingZone(
            name: data['name'],
            description: data['desc'],
            address: data['addr'],
            city: data['city'],
            latitude: data['lat'],
            longitude: data['lon'],
            pricePerHour: data['price'],
            dailyRate: data['daily'],
          );
          if (mounted) AdminSnackBar.show(context, 'Zona je kreirana', ok);
        },
      ),
    );
  }

  void _showEditZoneDialog(ParkingZone zone, ParkingZoneProvider provider) {
    showDialog(
      context: context,
      builder: (_) => _EditZoneDialog(zone: zone, provider: provider),
    );
  }

  void _showSpotsDialog(ParkingZone zone, ParkingZoneProvider provider) {
    showDialog(
      context: context,
      builder: (_) => _SpotsGridDialog(zone: zone, provider: provider),
    );
  }

  void _toggleZoneActive(ParkingZone zone, ParkingZoneProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AdminConfirmDialog(
        title: zone.isActive ? 'Deaktiviraj zonu?' : 'Aktiviraj zonu?',
        message: zone.isActive
            ? 'Zona će biti deaktivirana i neće biti vidljiva korisnicima.'
            : 'Zona će biti aktivirana i vidljiva korisnicima.',
        confirmLabel: 'Potvrdi',
        confirmColor: zone.isActive ? Colors.red : Colors.green,
        onConfirm: () async {
          final ok = await provider.updateParkingZone(
            zoneId: zone.id,
            name: null, description: null, address: null,
            pricePerHour: null, dailyRate: null,
            isActive: !zone.isActive,
          );
          if (mounted) {
            AdminSnackBar.show(
              context,
              zone.isActive ? 'Zona je deaktivirana' : 'Zona je aktivirana',
              ok,
            );
          }
        },
      ),
    );
  }
}

// ─── Add Zone Dialog ──────────────────────────────────────────────────────────

class _AddZoneDialog extends StatefulWidget {
  final List<City> allCities;
  final Future<void> Function(Map<String, dynamic>) onConfirm;

  const _AddZoneDialog(
      {required this.allCities, required this.onConfirm});

  @override
  State<_AddZoneDialog> createState() => _AddZoneDialogState();
}

class _AddZoneDialogState extends State<_AddZoneDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _dailyCtrl = TextEditingController();

  City? _selectedCity;
  LatLng? _pickedLocation;
  bool _isLoading = false;
  int _step = 0; // 0=forma, 1=mapa

  static const _sarajevo = LatLng(43.8563, 18.4131);
  final _mapController = MapController();

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _addrCtrl.dispose();
    _priceCtrl.dispose(); _dailyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 640,
        height: _step == 1 ? 600 : null,
        child: Column(
          mainAxisSize: _step == 0 ? MainAxisSize.min : MainAxisSize.max,
          children: [
            AdminDialogHeader(
              icon: _step == 0
                  ? Icons.add_location_alt_outlined
                  : Icons.map_outlined,
              title: _step == 0 ? 'Nova parking zona' : 'Odaberi lokaciju na mapi',
            ),
            if (_step == 0) _buildForm(),
            if (_step == 1) _buildMapPicker(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: AdminFormField(
                  controller: _nameCtrl,
                  label: 'Naziv zone',
                  icon: Icons.local_parking),
            ),
            const SizedBox(width: 12),
            // GRAD — LOV lista iz API-ja
            Expanded(
              child: AdminDropdownField<City>(
                value: _selectedCity,
                label: 'Grad',
                icon: Icons.location_city,
                items: widget.allCities,
                labelBuilder: (c) => c.name,
                onChanged: (c) => setState(() => _selectedCity = c),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          AdminFormField(
              controller: _addrCtrl,
              label: 'Adresa',
              icon: Icons.pin_drop_outlined),
          const SizedBox(height: 12),
          AdminFormField(
              controller: _descCtrl,
              label: 'Opis (opcionalno)',
              icon: Icons.notes,
              maxLines: 2),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: AdminFormField(
                  controller: _priceCtrl,
                  label: 'Cijena/sat (KM)',
                  icon: Icons.access_time,
                  keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminFormField(
                  controller: _dailyCtrl,
                  label: 'Dnevna cijena (KM)',
                  icon: Icons.wb_sunny_outlined,
                  keyboardType: TextInputType.number),
            ),
          ]),
          const SizedBox(height: 16),
          // Lokacija picker dugme
          GestureDetector(
            onTap: () => setState(() => _step = 1),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _pickedLocation != null
                    ? kPrimary.withOpacity(0.06)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _pickedLocation != null ? kPrimary : Colors.grey[300]!,
                  width: _pickedLocation != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _pickedLocation != null
                        ? Icons.check_circle
                        : Icons.add_location_alt_outlined,
                    color: _pickedLocation != null ? kPrimary : Colors.grey[500],
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _pickedLocation != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Lokacija odabrana',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kPrimary)),
                              Text(
                                'Lat: ${_pickedLocation!.latitude.toStringAsFixed(6)}, '
                                'Lng: ${_pickedLocation!.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          )
                        : const Text('Klikni za odabir lokacije na mapi',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF9CA3AF))),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPicker() {
    return Expanded(
      child: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _pickedLocation ?? _sarajevo,
            initialZoom: 14,
            onTap: (_, point) => setState(() => _pickedLocation = point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.parkify.admin',
            ),
            if (_pickedLocation != null)
              MarkerLayer(markers: [
                Marker(
                  point: _pickedLocation!,
                  width: 48,
                  height: 48,
                  child: const Icon(Icons.location_pin,
                      color: kPrimary, size: 48),
                ),
              ]),
          ],
        ),
        // Uputa
        Positioned(
          top: 12, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 8)
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 16, color: kPrimary),
                  SizedBox(width: 6),
                  Text('Klikni na mapu da odabereš lokaciju',
                      style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
        // Koordinate
        if (_pickedLocation != null)
          Positioned(
            bottom: 12, left: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 8)
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: kSuccess, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Lat: ${_pickedLocation!.latitude.toStringAsFixed(6)}, '
                    'Lng: ${_pickedLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _pickedLocation = null),
                    child: const Text('Poništi',
                        style: TextStyle(color: kDanger)),
                  ),
                ],
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildFooter() {
    return AdminDialogFooter(
      children: _step == 1
          ? [
              TextButton.icon(
                onPressed: () => setState(() => _step = 0),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Nazad na formu'),
              ),
              const SizedBox(width: 12),
              AdminPrimaryButton(
                label: 'Potvrdi lokaciju',
                icon: Icons.check,
                enabled: _pickedLocation != null,
                onPressed: () => setState(() => _step = 0),
              ),
            ]
          : [
              const AdminCancelButton(),
              const SizedBox(width: 12),
              AdminPrimaryButton(
                label: _isLoading ? 'Kreiranje...' : 'Kreiraj zonu',
                icon: Icons.add,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AdminSnackBar.error(context, 'Naziv je obavezan.'); return;
    }
    if (_selectedCity == null) {
      AdminSnackBar.error(context, 'Odaberi grad.'); return;
    }
    if (_addrCtrl.text.trim().isEmpty) {
      AdminSnackBar.error(context, 'Adresa je obavezna.'); return;
    }
    if (_pickedLocation == null) {
      AdminSnackBar.error(context, 'Odaberi lokaciju na mapi.'); return;
    }
    if (double.tryParse(_priceCtrl.text) == null) {
      AdminSnackBar.error(context, 'Unesite ispravnu cijenu po satu.'); return;
    }
    setState(() => _isLoading = true);
    Navigator.pop(context);
    await widget.onConfirm({
      'name': _nameCtrl.text.trim(),
      'desc': _descCtrl.text.trim(),
      'addr': _addrCtrl.text.trim(),
      'city': _selectedCity!.name,
      'lat': _pickedLocation!.latitude,
      'lon': _pickedLocation!.longitude,
      'price': double.parse(_priceCtrl.text),
      'daily': double.tryParse(_dailyCtrl.text),
    });
  }
}

// ─── Edit Zone Dialog ──────────────────────────────────────────────────────────

class _EditZoneDialog extends StatefulWidget {
  final ParkingZone zone;
  final ParkingZoneProvider provider;
  const _EditZoneDialog({required this.zone, required this.provider});

  @override
  State<_EditZoneDialog> createState() => _EditZoneDialogState();
}

class _EditZoneDialogState extends State<_EditZoneDialog> {
  late final _nameCtrl  = TextEditingController(text: widget.zone.name);
  late final _addrCtrl  = TextEditingController(text: widget.zone.address);
  late final _priceCtrl = TextEditingController(text: widget.zone.pricePerHour.toString());
  late final _dailyCtrl = TextEditingController(text: widget.zone.dailyRate.toString());
  late final _descCtrl  = TextEditingController(text: widget.zone.description ?? '');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _addrCtrl.dispose(); _priceCtrl.dispose();
    _dailyCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdminDialogHeader(
                icon: Icons.edit_outlined, title: 'Uredi parking zonu'),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                AdminFormField(controller: _nameCtrl, label: 'Naziv', icon: Icons.local_parking),
                const SizedBox(height: 12),
                AdminFormField(controller: _addrCtrl, label: 'Adresa', icon: Icons.pin_drop_outlined),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: AdminFormField(controller: _priceCtrl, label: 'Cijena/sat (KM)', icon: Icons.access_time, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: AdminFormField(controller: _dailyCtrl, label: 'Dnevna cijena (KM)', icon: Icons.wb_sunny_outlined, keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                AdminFormField(controller: _descCtrl, label: 'Opis', icon: Icons.notes, maxLines: 2),
              ]),
            ),
            AdminDialogFooter(children: [
              const AdminCancelButton(),
              const SizedBox(width: 12),
              AdminPrimaryButton(
                label: _isLoading ? 'Sprema...' : 'Spremi',
                icon: Icons.save_outlined,
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final ok = await widget.provider.updateParkingZone(
      zoneId: widget.zone.id,
      name: _nameCtrl.text, description: _descCtrl.text,
      address: _addrCtrl.text,
      pricePerHour: double.tryParse(_priceCtrl.text),
      dailyRate: double.tryParse(_dailyCtrl.text),
      isActive: null,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      AdminSnackBar.show(context, 'Zona je ažurirana', ok);
      if (ok) Navigator.pop(context);
    }
  }
}

// ─── Spots Grid Dialog ─────────────────────────────────────────────────────────

class _SpotsGridDialog extends StatefulWidget {
  final ParkingZone zone;
  final ParkingZoneProvider provider;
  const _SpotsGridDialog({required this.zone, required this.provider});

  @override
  State<_SpotsGridDialog> createState() => _SpotsGridDialogState();
}

class _SpotsGridDialogState extends State<_SpotsGridDialog> {
  @override
  Widget build(BuildContext context) {
    final spots = widget.zone.spots ?? [];
    final maxRow = spots.isEmpty ? 1 : spots.map((s) => s.rowNumber ?? 1).reduce((a, b) => a > b ? a : b);
    final maxCol = spots.isEmpty ? 1 : spots.map((s) => s.columnNumber ?? 1).reduce((a, b) => a > b ? a : b);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminDialogHeader(
                icon: Icons.grid_view_rounded,
                title: 'Mapa mjesta: ${widget.zone.name}'),
            Flexible(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: spots.isNotEmpty
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: maxCol.clamp(1, 10),
                            childAspectRatio: 1.4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: maxRow * maxCol,
                          itemBuilder: (context, index) {
                            final row = (index ~/ maxCol) + 1;
                            final col = (index % maxCol) + 1;
                            final spot = spots.cast<dynamic>().firstWhere(
                              (s) => s.rowNumber == row && s.columnNumber == col,
                              orElse: () => null,
                            );
                            if (spot == null) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                              );
                            }
                            return _buildSpotItem(spot);
                          },
                        )
                      : const Center(child: Text('Zona nema definisanih mjesta.')),
                ),
              ),
            ),
            AdminDialogFooter(children: [
              ElevatedButton.icon(
                onPressed: _showAddSpotDialog,
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Dodaj mjesto', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, elevation: 0),
              ),
              const Spacer(),
              const AdminCancelButton(label: 'Zatvori'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotItem(dynamic spot) {
    Color baseColor = Colors.green;
    IconData icon = Icons.directions_car;
    if (spot.type == 2) { baseColor = Colors.blue; icon = Icons.accessible; }
    else if (spot.type == 3) { baseColor = Colors.orange; icon = Icons.umbrella; }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: () => _showEditSpotDialog(spot),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: baseColor, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: baseColor, size: 24),
                const SizedBox(height: 2),
                FittedBox(
                  child: Text(spot.spotCode ?? '',
                      style: TextStyle(
                          color: baseColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10)),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -4, right: -4,
          child: GestureDetector(
            onTap: () => _showToggleSpotDialog(spot),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: spot.isAvailable ? Colors.red : Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                spot.isAvailable ? Icons.lock_outline : Icons.lock_open_outlined,
                color: Colors.white, size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSpotDialog() {
    final rowCtrl = TextEditingController();
    final colCtrl = TextEditingController();
    int typeVal = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AdminDialogHeader(icon: Icons.add, title: 'Dodaj parking mjesto'),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    AdminFormField(controller: rowCtrl, label: 'Red', icon: Icons.table_rows_outlined, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    AdminFormField(controller: colCtrl, label: 'Kolona', icon: Icons.view_column_outlined, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    AdminDropdownField<int>(
                      value: typeVal,
                      label: 'Tip mjesta',
                      icon: Icons.category_outlined,
                      items: const [1, 2],
                      labelBuilder: (v) => v == 1 ? 'Regular' : 'Invalidsko',
                      onChanged: (v) => ss(() => typeVal = v ?? 1),
                    ),
                  ]),
                ),
                AdminDialogFooter(children: [
                  const AdminCancelButton(),
                  const SizedBox(width: 12),
                  AdminPrimaryButton(
                    label: 'Dodaj',
                    icon: Icons.add,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final ok = await widget.provider.createParkingSpot(
                        parkingZoneId: widget.zone.id,
                        type: typeVal,
                        rowNumber: int.tryParse(rowCtrl.text),
                        columnNumber: int.tryParse(colCtrl.text),
                        isAvailable: true,
                      );
                      if (mounted) AdminSnackBar.show(context, ok ? 'Mjesto dodano' : 'Greška', ok);
                    },
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditSpotDialog(dynamic spot) {
    final rowCtrl = TextEditingController(text: spot.rowNumber?.toString());
    final colCtrl = TextEditingController(text: spot.columnNumber?.toString());
    int typeVal = (spot.type >= 1 && spot.type <= 3) ? spot.type : 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AdminDialogHeader(icon: Icons.edit_outlined, title: 'Uredi parking mjesto'),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    AdminFormField(controller: rowCtrl, label: 'Red', icon: Icons.table_rows_outlined, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    AdminFormField(controller: colCtrl, label: 'Kolona', icon: Icons.view_column_outlined, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    AdminDropdownField<int>(
                      value: typeVal,
                      label: 'Tip mjesta',
                      icon: Icons.category_outlined,
                      items: const [1, 2],
                      labelBuilder: (v) => v == 1 ? 'Regular' : 'Invalidsko',
                      onChanged: (v) => ss(() => typeVal = v ?? 1),
                    ),
                  ]),
                ),
                AdminDialogFooter(children: [
                  const AdminCancelButton(),
                  const SizedBox(width: 12),
                  AdminPrimaryButton(
                    label: 'Spremi',
                    icon: Icons.save_outlined,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final ok = await widget.provider.updateParkingSpot(
                        spotId: spot.id, spotCode: spot.spotCode,
                        isAvailable: spot.isAvailable, type: typeVal,
                        rowNumber: int.tryParse(rowCtrl.text),
                        columnNumber: int.tryParse(colCtrl.text),
                      );
                      if (mounted) AdminSnackBar.show(context, 'Mjesto ažurirano', ok);
                    },
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showToggleSpotDialog(dynamic spot) {
    showDialog(
      context: context,
      builder: (_) => AdminConfirmDialog(
        title: spot.isAvailable ? 'Deaktiviraj mjesto?' : 'Aktiviraj mjesto?',
        message: spot.isAvailable
            ? 'Mjesto će biti deaktivirano.'
            : 'Mjesto će biti aktivirano.',
        confirmLabel: 'Potvrdi',
        confirmColor: spot.isAvailable ? Colors.red : Colors.green,
        onConfirm: () async {
          final ok = await widget.provider.toggleParkingSpotActive(
              spotId: spot.id, isAvailable: !spot.isAvailable);
          if (mounted) AdminSnackBar.show(context, 'Mjesto ažurirano', ok);
        },
      ),
    );
  }
}