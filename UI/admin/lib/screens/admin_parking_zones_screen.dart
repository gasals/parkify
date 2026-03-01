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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ParkingZoneProvider>(context, listen: false)
            .getParkingZones(includeSpots: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<ParkingZoneProvider>(context, listen: false);
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (provider.currentPage < provider.totalPages) {
        provider.getParkingZones(
          page: provider.currentPage + 1,
          includeSpots: true,
        );
      }
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      final provider = Provider.of<ParkingZoneProvider>(context, listen: false);
      await provider.getParkingZones(includeSpots: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parking lokacije',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pretraga po nazivu...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _performSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Traži'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer<ParkingZoneProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.parkingZones.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.parkingZones.isEmpty) {
                    return const Center(child: Text('Nema parking zona'));
                  }

                  final filteredZones = provider.parkingZones
                      .where((zone) => zone.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();

                  return GridView.builder(
                    controller: _scrollController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: filteredZones.length +
                        (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredZones.length) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final zone = filteredZones[index];
                      return _buildZoneTile(zone, provider);
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

  Widget _buildZoneTile(ParkingZone zone, ParkingZoneProvider provider) {
    final percentage = zone.totalSpots > 0
        ? (zone.availableSpots / zone.totalSpots) * 100
        : 0.0;

    Color statusColor = Colors.green;
    if (percentage < 20) {
      statusColor = Colors.red;
    } else if (percentage < 50) {
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
                          const Icon(Icons.location_on, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              zone.address,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  _buildMiniStat(Icons.directions_car, '${zone.availableSpots}/${zone.totalSpots}', 'Slobodno'),
                  _buildMiniStat(Icons.umbrella, '${zone.coveredSpots}', 'Natkriveno'),
                  _buildMiniStat(Icons.accessible, '${zone.disabledSpots}', 'Invalidi'),
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
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: zone.totalSpots > 0 ? zone.availableSpots / zone.totalSpots : 0,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildPriceInfo(Icons.access_time, 'Sat:', '${zone.pricePerHour} KM'),
                const SizedBox(width: 16),
                _buildPriceInfo(Icons.wb_sunny, 'Dan:', '${zone.dailyRate} KM'),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditZoneDialog(zone, provider),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('UREDI', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSpotsDialog(zone, provider),
                    icon: const Icon(Icons.grid_view_rounded, size: 14),
                    label: const Text('SPOTOVI', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _toggleZoneActive(zone, provider),
                style: TextButton.styleFrom(
                  foregroundColor: zone.isActive ? Colors.red : Colors.green,
                ),
                child: Text(
                  zone.isActive ? 'DEAKTIVIRAJ ZONU' : 'AKTIVIRAJ ZONU',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildPriceInfo(IconData icon, String label, String price) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(width: 4),
        Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showEditZoneDialog(ParkingZone zone, ParkingZoneProvider provider) async {
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
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Naziv')),
              const SizedBox(height: 12),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Adresa')),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cijena/sat (BAM)')),
              const SizedBox(height: 12),
              TextField(controller: dailyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Dnevna cijena (BAM)')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Opis'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Otkaži')),
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
                    content: Text(success ? 'Zona je ažurirana' : 'Greška pri ažuriranju'),
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
      builder: (context) =>
          _SpotsGridDialog(zone: zone, provider: provider),
    );
  }

  void _toggleZoneActive(ParkingZone zone, ParkingZoneProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          zone.isActive ? 'Deaktiviraj zonu?' : 'Aktiviraj zonu?',
        ),
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
}

class _SpotsGridDialog extends StatefulWidget {
  final ParkingZone zone;
  final ParkingZoneProvider provider;

  const _SpotsGridDialog({
    required this.zone,
    required this.provider,
  });

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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAddSpotDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Dodaj spot'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                    style: TextStyle(color: baseColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: () => _showDeleteSpotDialog(spot),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 10),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSpotDialog() {
    final rowCtrl = TextEditingController();
    final colCtrl = TextEditingController();
    int typeVal = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Dodaj spot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: rowCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Red')),
              const SizedBox(height: 12),
              TextField(controller: colCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kolona')),
              const SizedBox(height: 12),
              DropdownButton<int>(
                value: typeVal,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Regular')),
                  DropdownMenuItem(value: 1, child: Text('Invalidsko')),
                  DropdownMenuItem(value: 2, child: Text('Pokriveno')),
                ],
                onChanged: (v) => setState(() => typeVal = v ?? 0),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Otkaži')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await widget.provider.createParkingSpot(
                  parkingZoneId: widget.zone.id,
                  type: typeVal,
                  rowNumber: int.tryParse(rowCtrl.text),
                  columnNumber: int.tryParse(colCtrl.text),
                  isAvailable: true,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Spot dodan' : 'Greška'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
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
              TextField(controller: rowCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Red')),
              const SizedBox(height: 12),
              TextField(controller: colCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kolona')),
              const SizedBox(height: 12),
              DropdownButton<int>(
                value: typeVal,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Regular')),
                  DropdownMenuItem(value: 2, child: Text('Invalidsko')),
                  DropdownMenuItem(value: 3, child: Text('Pokriveno')),
                ],
                onChanged: (v) => setState(() => typeVal = v ?? 1),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Otkaži')),
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

  void _showDeleteSpotDialog(dynamic spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši spot?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ne')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await widget.provider.deleteParkingSpot(spot.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Spot obrisan' : 'Greška'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Da'),
          ),
        ],
      ),
    );
  }
}