import 'package:admin/models/city_model.dart';
import 'package:admin/providers/city_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/parking_zone_model.dart';
import '../providers/parking_zone_provider.dart';

class AdminParkingZonesScreen extends StatefulWidget {
  const AdminParkingZonesScreen({Key? key}) : super(key: key);

  @override
  State<AdminParkingZonesScreen> createState() =>
      _AdminParkingZonesScreenState();
}

class _AdminParkingZonesScreenState extends State<AdminParkingZonesScreen> {
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _citySearchController = TextEditingController();
  bool _isSearching = false;
  List<City> _allCities = [];
  City? _selectedCity;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCities();
        Provider.of<ParkingZoneProvider>(
          context,
          listen: false,
        ).searchParkingZones(includeSpots: true);
      }
    });
  }

  void _loadCities() async {
    final provider = Provider.of<ParkingZoneProvider>(context, listen: false);
    final cities = await provider.searchCitiesList();
    if (mounted) {
      setState(() => _allCities = cities);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _citySearchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<ParkingZoneProvider>(context, listen: false);
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (provider.currentPage < provider.totalPages && !_isSearching) {
        provider.searchParkingZones(
          name: _nameController.text.isEmpty ? null : _nameController.text,
          cityId: _selectedCity?.id,
          page: provider.currentPage + 1,
          includeSpots: true,
        );
      }
    }
  }

  Future<void> _performSearch() async {
    final provider = Provider.of<ParkingZoneProvider>(context, listen: false);

    setState(() => _isSearching = true);

    await provider.searchParkingZones(
      name: _nameController.text.isEmpty ? null : _nameController.text,
      cityId: _selectedCity?.id,
      includeSpots: true,
    );

    setState(() => _isSearching = false);
  }

  void _clearSearch() {
    setState(() {
      _nameController.clear();
      _selectedCity = null;
    });
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
            const Text(
              'Parking lokacije',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSearchField(
                      _nameController,
                      'Naziv zone',
                      Icons.map_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Autocomplete<City>(
                      optionsBuilder: (TextEditingValue value) {
                        if (value.text.isEmpty) {
                          return _allCities;
                        }
                        return _allCities
                            .where(
                              (city) => city.name.toLowerCase().contains(
                                value.text.toLowerCase(),
                              ),
                            )
                            .toList();
                      },
                      onSelected: (City selection) {
                        setState(() {
                          _selectedCity = selection;
                          _citySearchController.text = selection.name;
                        });
                      },
                      displayStringForOption: (City option) => option.name,
                      fieldViewBuilder:
                          (
                            BuildContext context,
                            TextEditingController fieldController,
                            FocusNode fieldFocusNode,
                            VoidCallback onFieldSubmitted,
                          ) {
                            return TextField(
                              controller: fieldController,
                              focusNode: fieldFocusNode,
                              onChanged: (String value) async {
                                if (value.isNotEmpty) {
                                  final provider =
                                      Provider.of<ParkingZoneProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final results = await provider
                                      .searchCitiesList(name: value);
                                  setState(() => _allCities = results);
                                } else {
                                  _loadCities();
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Grad',
                                prefixIcon: const Icon(
                                  Icons.location_city,
                                  size: 20,
                                ),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                  ),
                                ),
                              ),
                            );
                          },
                    ),
                  ),
                  const SizedBox(width: 24),
                  TextButton.icon(
                    onPressed: () {
                      _clearSearch();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Očisti'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSearching ? null : _performSearch,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search, size: 18),
                    label: const Text('Pretraži'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddZoneDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Dodaj zonu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer<ParkingZoneProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.parkingZones.isEmpty)
                    return const Center(child: CircularProgressIndicator());
                  if (provider.parkingZones.isEmpty)
                    return const Center(child: Text('Nema parking zona'));

                  return GridView.builder(
                    controller: _scrollController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.5,
                        ),
                    itemCount:
                        provider.parkingZones.length +
                        (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.parkingZones.length)
                        return const Center(child: CircularProgressIndicator());
                      return _buildZoneTile(
                        provider.parkingZones[index],
                        provider,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }

  Widget _buildZoneTile(ParkingZone zone, ParkingZoneProvider provider) {
    final percentage = zone.totalSpots > 0
        ? ((zone.totalSpots - zone.availableSpots) / zone.totalSpots) * 100
        : 0.0;

    Color statusColor = Colors.red;
    if (percentage < 40) {
      statusColor = Colors.green;
    } else if (percentage < 70) {
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              zone.address,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: zone.isActive
                        ? Colors.green.withOpacity(0.12)
                        : Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        zone.isActive ? Icons.check_circle : Icons.pause_circle,
                        size: 12,
                        color: zone.isActive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        zone.isActive ? 'AKTIVNA' : 'NEAKTIVNA',
                        style: TextStyle(
                          color: zone.isActive ? Colors.green : Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(
                    Icons.local_parking,
                    '${zone.totalSpots}',
                    'Ukupno',
                  ),
                  _buildMiniStat(
                    Icons.event_available,
                    '${zone.availableSpots}',
                    'Slobodno',
                  ),
                  _buildMiniStat(
                    Icons.accessible,
                    '${zone.disabledSpots}',
                    'Invalidi',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Popunjenost',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: zone.totalSpots > 0
                        ? (zone.totalSpots - zone.availableSpots) /
                              zone.totalSpots
                        : 0,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.access_time,
              "Cijena sata:",
              '${zone.pricePerHour} KM',
            ),
            const SizedBox(width: 16),
            _buildInfoRow(
              Icons.wb_sunny,
              'Cijena dana:',
              '${zone.dailyRate} KM',
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditZoneDialog(zone, provider),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: const Text(
                      'UREDI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSpotsDialog(zone, provider),
                    icon: const Icon(Icons.grid_view_rounded, size: 16),
                    label: const Text(
                      'MJESTA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleZoneActive(zone, provider),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: zone.isActive
                          ? Colors.red
                          : Colors.green,
                      side: BorderSide(
                        color: zone.isActive ? Colors.red : Colors.green,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      zone.isActive
                          ? Icons.lock_outline
                          : Icons.lock_open_outlined,
                      size: 16,
                    ),
                    label: Text(
                      zone.isActive ? 'DEAKTIVIRAJ' : 'AKTIVIRAJ',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  void _showEditZoneDialog(
    ParkingZone zone,
    ParkingZoneProvider provider,
  ) async {
    final nameCtrl = TextEditingController(text: zone.name);
    final addrCtrl = TextEditingController(text: zone.address);
    final priceCtrl = TextEditingController(text: zone.pricePerHour.toString());
    final dailyCtrl = TextEditingController(text: zone.dailyRate.toString());
    final descCtrl = TextEditingController(text: zone.description ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uredi parking zonu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Naziv'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Adresa'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cijena/sat (BAM)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dailyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dnevna cijena (BAM)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Opis'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.updateParkingZone(
                zoneId: zone.id,
                name: nameCtrl.text,
                description: descCtrl.text,
                address: addrCtrl.text,
                pricePerHour: double.tryParse(priceCtrl.text),
                dailyRate: double.tryParse(dailyCtrl.text),
                isActive: null,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Zona je ažurirana' : 'Greška pri ažuriranju',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Spremi'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    addrCtrl.dispose();
    priceCtrl.dispose();
    dailyCtrl.dispose();
    descCtrl.dispose();
  }

  void _showSpotsDialog(ParkingZone zone, ParkingZoneProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _SpotsGridDialog(zone: zone, provider: provider),
    );
  }

  void _toggleZoneActive(ParkingZone zone, ParkingZoneProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(zone.isActive ? 'Deaktiviraj zonu?' : 'Aktiviraj zonu?'),
        content: Text(
          zone.isActive
              ? 'Zona će biti deaktivirana'
              : 'Zona će biti aktivirana',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.updateParkingZone(
                zoneId: zone.id,
                name: null,
                description: null,
                address: null,
                pricePerHour: null,
                dailyRate: null,
                isActive: !zone.isActive,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (zone.isActive
                                ? 'Zona je deaktivirana'
                                : 'Zona je aktivirana')
                          : 'Greška pri promjeni',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );
  }

  void _showAddZoneDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final latCtrl = TextEditingController(text: '0');
    final lonCtrl = TextEditingController(text: '0');
    final priceCtrl = TextEditingController();
    final dailyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj novu parking zonu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Naziv'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Opis'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Adresa'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: 'Grad'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: latCtrl,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lonCtrl,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cijena/sat (BAM)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dailyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dnevna cijena (BAM)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<ParkingZoneProvider>(
                context,
                listen: false,
              );
              final success = await provider.createParkingZone(
                name: nameCtrl.text,
                description: descCtrl.text,
                address: addrCtrl.text,
                city: cityCtrl.text,
                latitude: double.tryParse(latCtrl.text) ?? 0,
                longitude: double.tryParse(lonCtrl.text) ?? 0,
                pricePerHour: double.tryParse(priceCtrl.text) ?? 0,
                dailyRate: double.tryParse(dailyCtrl.text),
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Zona je kreirana' : 'Greška pri kreiranju',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Kreiraj'),
          ),
        ],
      ),
    );
  }
}

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
    final maxRow = spots.isEmpty
        ? 1
        : spots.map((s) => s.rowNumber ?? 1).reduce((a, b) => a > b ? a : b);
    final maxCol = spots.isEmpty
        ? 1
        : spots.map((s) => s.columnNumber ?? 1).reduce((a, b) => a > b ? a : b);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mapa: ${widget.zone.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
                              (s) =>
                                  s.rowNumber == row && s.columnNumber == col,
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
                      : const Center(
                          child: Text('Zona nema definisanih mjesta.'),
                        ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAddSpotDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Dodaj mjesto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Zatvori'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotItem(dynamic spot) {
    Color baseColor = Colors.green;
    IconData icon = Icons.directions_car;

    if (spot.type == 1) {
      baseColor = Colors.green;
    } else if (spot.type == 2) {
      baseColor = Colors.blue;
      icon = Icons.accessible;
    } else if (spot.type == 3) {
      baseColor = Colors.orange;
      icon = Icons.umbrella;
    }

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
                  child: Text(
                    spot.spotCode ?? '',
                    style: TextStyle(
                      color: baseColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: GestureDetector(
            onTap: () => _showToggleSpotDialog(spot),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: spot.isAvailable ? Colors.red : Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                spot.isAvailable
                    ? Icons.lock_outline
                    : Icons.lock_open_outlined,
                color: Colors.white,
                size: 12,
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Dodaj spot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rowCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Red'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kolona'),
              ),
              const SizedBox(height: 12),
              DropdownButton<int>(
                value: typeVal,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Regular')),
                  DropdownMenuItem(value: 2, child: Text('Invalidsko'))
                ],
                onChanged: (v) => setState(() => typeVal = v ?? 1),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži'),
            ),
            TextButton(
              onPressed: () async {
                final success = await widget.provider.createParkingSpot(
                  parkingZoneId: widget.zone.id,
                  type: typeVal,
                  rowNumber: int.tryParse(rowCtrl.text),
                  columnNumber: int.tryParse(colCtrl.text),
                  isAvailable: true,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Spot dodan' : 'Greška'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );

                  if (success) {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 500));
                  }
                }
              },
              child: const Text('Dodaj'),
            ),
          ],
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Uredi spot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rowCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Red'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kolona'),
              ),
              const SizedBox(height: 12),
              DropdownButton<int>(
                value: typeVal,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Regular')),
                  DropdownMenuItem(value: 2, child: Text('Invalidsko'))
                ],
                onChanged: (v) => setState(() => typeVal = v ?? 1),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await widget.provider.updateParkingSpot(
                  spotId: spot.id,
                  spotCode: spot.spotCode,
                  isAvailable: spot.isAvailable,
                  type: typeVal,
                  rowNumber: int.tryParse(rowCtrl.text),
                  columnNumber: int.tryParse(colCtrl.text),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Spot ažuriran' : 'Greška'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Spremi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showToggleSpotDialog(dynamic spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          spot.isAvailable ? 'Deaktiviraj mjesto?' : 'Aktiviraj mjesto?',
        ),
        content: Text(
          spot.isAvailable
              ? 'Mjesto će biti deaktivirano'
              : 'Mjesto će biti aktivirano',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await widget.provider.toggleParkingSpotActive(
                spotId: spot.id,
                isAvailable: !spot.isAvailable,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Mjesto je ažurirano' : 'Greška'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );
  }
}
