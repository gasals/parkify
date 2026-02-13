import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/parking_zone_model.dart';
import '../providers/parking_zone_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';

class MapsScreen extends StatefulWidget {
  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

enum BottomSheetState { closed, info, spots, reservation, confirmed }

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  List<ParkingZone> _filteredZones = [];
  ParkingZone? _selectedZone;
  ParkingSpot? _selectedSpot;
  BottomSheetState _sheetState = BottomSheetState.closed;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late DateTime _startTime;
  late DateTime _endTime;
  bool _requiresDisabledSpot = false;
  double _calculatedPrice = 0;
  String _reservationCode = '';

  static const LatLng _initialCenter = LatLng(43.8578333, 18.4230758);

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().add(const Duration(hours: 1));
    _endTime = _startTime.add(const Duration(hours: 1));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ParkingZoneProvider>(context, listen: false);
      provider.getParkingZones().then((_) {
        setState(() {
          _filteredZones = provider.parkingZones;
        });
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterZones(List<ParkingZone> zones) {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredZones = zones;
      } else {
        final query = _searchQuery.toLowerCase();
        _filteredZones = zones.where((zone) {
          return zone.name.toLowerCase().contains(query) ||
              zone.address.toLowerCase().contains(query) ||
              zone.city.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Set<Marker> _buildMarkers() {
    return _filteredZones.map((zone) {
      final isSelected = _selectedZone?.id == zone.id;
      return Marker(
        markerId: MarkerId(zone.id.toString()),
        position: LatLng(zone.latitude, zone.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: zone.name,
          snippet: '\$${zone.pricePerHour}/sat',
        ),
        onTap: () {
          setState(() {
            _selectedZone = zone;
            _sheetState = BottomSheetState.info;
            _selectedSpot = null;
          });
        },
      );
    }).toSet();
  }

  void _calculatePrice() {
    if (_selectedZone == null) return;
    final duration = _endTime.difference(_startTime);
    final hours = duration.inHours + (duration.inMinutes % 60 > 0 ? 1 : 0);
    setState(() {
      _calculatedPrice = hours * _selectedZone!.pricePerHour;
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = DateTime(
            _startTime.year,
            _startTime.month,
            _startTime.day,
            picked.hour,
            picked.minute,
          );
          if (_startTime.isAfter(_endTime)) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        } else {
          _endTime = DateTime(
            _endTime.year,
            _endTime.month,
            _endTime.day,
            picked.hour,
            picked.minute,
          );
        }
        _calculatePrice();
      });
    }
  }

  void _makeReservation(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reservationProvider =
        Provider.of<ReservationProvider>(context, listen: false);

    final reservationData = {
      'userId': authProvider.user!.id,
      'parkingZoneId': _selectedZone!.id,
      'parkingSpotId': _selectedSpot!.id,
      'reservationStart': _startTime.toIso8601String(),
      'reservationEnd': _endTime.toIso8601String(),
      'requiresDisabledSpot': _requiresDisabledSpot
    };

    final success = await reservationProvider.createReservation(reservationData);

    if (success) {
      _reservationCode =
          'CPA-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      setState(() => _sheetState = BottomSheetState.confirmed);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reservationProvider.errorMessage ?? 'Greška pri rezervaciji'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ParkingZoneProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.parkingZones.isEmpty) {
            return Center(child: Text(AppStrings.noData));
          }

          if (_filteredZones.isEmpty && _searchQuery.isEmpty) {
            _filteredZones = provider.parkingZones;
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _initialCenter,
                  zoom: 13,
                ),
                markers: _buildMarkers(),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),

              Positioned(
                top: 100,
                left: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Upišite lokaciju...',
                      prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _filterZones(provider.parkingZones);
                              },
                              child: Icon(Icons.close, color: AppColors.textSecondary),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _filterZones(provider.parkingZones);
                    },
                  ),
                ),
              ),

              if (_searchQuery.isNotEmpty && _filteredZones.isNotEmpty)
                Positioned(
                  top: 150,
                  left: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          _filteredZones.length > 5 ? 5 : _filteredZones.length,
                      itemBuilder: (context, index) {
                        final zone = _filteredZones[index];
                        return ListTile(
                          leading: Icon(Icons.location_on,
                              color: AppColors.primary, size: 18),
                          title: Text(
                            zone.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${zone.city}, ${zone.address}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            _searchController.text = zone.name;
                            setState(() {
                              _selectedZone = zone;
                              _sheetState = BottomSheetState.info;
                              _selectedSpot = null;
                              _searchQuery = '';
                            });
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLng(
                                LatLng(zone.latitude, zone.longitude),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

              if (_selectedZone != null) _buildBottomSheet(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < -10) {
            if (_sheetState == BottomSheetState.info) {
              setState(() => _sheetState = BottomSheetState.spots);
            }
          } else if (details.delta.dy > 10) {
            if (_sheetState == BottomSheetState.spots) {
              setState(() => _sheetState = BottomSheetState.info);
            } else if (_sheetState == BottomSheetState.reservation) {
              setState(() => _sheetState = BottomSheetState.spots);
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedZone!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedSpot != null)
                            Text(
                              _selectedSpot!.spotCode,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '\$${_selectedZone!.pricePerHour}/sat',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _sheetState = BottomSheetState.closed;
                            _selectedZone = null;
                            _selectedSpot = null;
                          });
                        },
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_sheetState == BottomSheetState.info)
                  _buildInfoPanel(context)
                else if (_sheetState == BottomSheetState.spots)
                  _buildSpotsPanel(context)
                else if (_sheetState == BottomSheetState.reservation)
                  _buildReservationPanel(context)
                else if (_sheetState == BottomSheetState.confirmed)
                  _buildConfirmedPanel(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${_selectedZone!.address}, ${_selectedZone!.city}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip(
                '${_selectedZone!.totalSpots}',
                'Slobodnih mjesta',
              ),
              _buildInfoChip(
                '${_selectedZone!.disabledSpots}',
                'Invalidska',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _sheetState = BottomSheetState.spots);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Detalji parkinga',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSpotsPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dostupnih mjesta: 5',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          if (_selectedZone!.spots != null && _selectedZone!.spots!.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 0.9,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: _selectedZone!.spots!.length,
              itemBuilder: (context, index) {
                final spot = _selectedZone!.spots![index];
                final isSelected = _selectedSpot?.id == spot.id;
                final isAvailable = spot.isAvailable;

                return GestureDetector(
                  onTap: isAvailable
                      ? () {
                          setState(() {
                            _selectedSpot = spot;
                            _sheetState = BottomSheetState.reservation;
                            _calculatePrice();
                          });
                        }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isAvailable
                              ? Colors.white
                              : AppColors.surfaceVariant,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : isAvailable
                                ? AppColors.border
                                : AppColors.textTertiary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_parking,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : isAvailable
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          spot.spotCode.split('-').last,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : isAvailable
                                    ? AppColors.textPrimary
                                    : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          Text(
            'Rezerviraj mjesto za drugi termin',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedSpot != null
                  ? () {
                      setState(() => _sheetState = BottomSheetState.reservation);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Nastavi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReservationPanel(BuildContext context) {
    final duration = _endTime.difference(_startTime);
    final durationText = '${duration.inHours}h';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${durationText} - ${_calculatedPrice.toStringAsFixed(0)}KM',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Procjena trajanja',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _buildTimeSelector(
            'Vrijeme početka',
            _startTime,
            () => _selectTime(context, true),
          ),
          const SizedBox(height: 12),
          _buildTimeSelector(
            'Vrijeme završetka',
            _endTime,
            () => _selectTime(context, false),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.wheelchair_pickup, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Parking za invalide')),
              Switch(
                value: _requiresDisabledSpot,
                onChanged: (v) => setState(() => _requiresDisabledSpot = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Consumer<ReservationProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () => _makeReservation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Rezerviši mjesto',
                          style: TextStyle(color: Colors.white),
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildConfirmedPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Super! Završio si sa parkingom',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rezervisano mjesto: ${_selectedZone!.name}, ${_selectedSpot!.spotCode}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'QR',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ID: $_reservationCode',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Vrijeme početka', '${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}'),
          _buildDetailRow('Vrijeme završetka', '${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}'),
          _buildDetailRow('Parking sesija', '${_endTime.difference(_startTime).inHours}h'),
          _buildDetailRow('Ukupno', '\$${_calculatedPrice.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _sheetState = BottomSheetState.closed;
                  _selectedZone = null;
                  _selectedSpot = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Izvrši plaćanje',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(
    String label,
    DateTime time,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(Icons.access_time, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
