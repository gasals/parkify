import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/parking_zone_model.dart';
import '../providers/parking_zone_provider.dart';
import '../screens/parking_details_screen.dart';

class MapsScreen extends StatefulWidget {
  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

enum BottomSheetState { closed, info }

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  List<ParkingZone> _filteredZones = [];
  ParkingZone? _selectedZone;
  BottomSheetState _sheetState = BottomSheetState.closed;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const LatLng _initialCenter = LatLng(43.8578333, 18.4230758);

  @override
  void initState() {
    super.initState();
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
          snippet: '${zone.pricePerHour}KM/h',
        ),
        onTap: () {
          setState(() {
            _selectedZone = zone;
            _sheetState = BottomSheetState.info;
          });
        },
      );
    }).toSet();
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

              if (_selectedZone != null && _sheetState == BottomSheetState.info)
                _buildBottomSheet(context),
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
                      ],
                    ),
                    Text(
                      '${_selectedZone!.pricePerHour}KM/h',
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
                        });
                      },
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoPanel(context),
            ],
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
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ParkingDetailsScreen(parkingZone: _selectedZone!),
                  ),
                );

                setState(() {
                  _sheetState = BottomSheetState.closed;
                  _selectedZone = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Odaberite mjesto',
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
}