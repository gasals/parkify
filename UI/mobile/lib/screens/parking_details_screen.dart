import 'package:flutter/material.dart';
import 'package:mobile/providers/parking_zone_provider.dart';
import 'package:mobile/screens/reservation_screen.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/parking_zone_model.dart';

class ParkingDetailsScreen extends StatefulWidget {
  final ParkingZone parkingZone;

  const ParkingDetailsScreen({Key? key, required this.parkingZone})
    : super(key: key);

  @override
  State<ParkingDetailsScreen> createState() => _ParkingDetailsScreenState();
}

class _ParkingDetailsScreenState extends State<ParkingDetailsScreen> {
  ParkingSpot? _selectedSpot;

  List<ParkingSpot> _getSortedSpots() {
    if (widget.parkingZone.spots == null) return [];
    final sorted = List<ParkingSpot>.from(widget.parkingZone.spots!);
    sorted.sort((a, b) {
      final rowCompare = a.rowNumber.compareTo(b.rowNumber);
      if (rowCompare != 0) return rowCompare;
      return a.columnNumber.compareTo(b.columnNumber);
    });
    return sorted;
  }

  int _getMaxColumn(List<ParkingSpot> spots) {
    return spots.map((s) => s.columnNumber).reduce((a, b) => a > b ? a : b);
  }

  int _getMaxRow(List<ParkingSpot> spots) {
    return spots.map((s) => s.rowNumber).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final sortedSpots = _getSortedSpots();

    if (sortedSpots.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.parkingZone.name),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: Text("Nema mjesta")),
      );
    }

    final maxColumn = _getMaxColumn(sortedSpots);
    final maxRow = _getMaxRow(sortedSpots);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parkingZone.name),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.parkingZone.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.parkingZone.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.parkingZone.pricePerHour}KM/h',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const Text(
                'Raspored mjesta',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: List.generate(maxRow, (rowIndex) {
                    final rowNumber = rowIndex + 1;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: List.generate(maxColumn, (colIndex) {
                          final columnNumber = colIndex + 1;

                          final spot = sortedSpots.firstWhere(
                            (s) =>
                                s.rowNumber == rowNumber &&
                                s.columnNumber == columnNumber,
                            orElse: () => ParkingSpot(
                              id: -1,
                              parkingZoneId: 0,
                              spotCode: '',
                              rowNumber: rowNumber,
                              columnNumber: columnNumber,
                              type: 0,
                              isAvailable: false,
                              isCovered: false,
                            ),
                          );

                          if (spot.id == -1) {
                            return Container(
                              width: 50,
                              height: 50,
                              margin: const EdgeInsets.all(4),
                              color: Colors.grey[200],
                            );
                          }

                          final isSelected = _selectedSpot?.id == spot.id;
                          final isAvailable = spot.isAvailable;
                          final isDisabled = spot.type == 2;
                          final isCovered = spot.isCovered;

                          return GestureDetector(
                            onTap: isAvailable
                                ? () {
                                    setState(() {
                                      _selectedSpot = spot;
                                    });
                                  }
                                : null,
                            child: Container(
                              width: 50,
                              height: 50,
                              margin: const EdgeInsets.all(4),
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
                                    isDisabled
                                        ? Icons.wheelchair_pickup
                                        : isCovered
                                        ? Icons.roofing
                                        : Icons.local_parking,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : isAvailable
                                        ? AppColors.primary
                                        : AppColors.textTertiary,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    spot.spotCode,
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
                        }),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 32),

              if (_selectedSpot != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Odabrano mjesto: ${_selectedSpot!.spotCode}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ReservationScreen(
                                parkingZone: widget.parkingZone,
                                parkingSpot: _selectedSpot!,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Nastavi',
                          style: TextStyle(
                            color: Colors.white,
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
      ),
    );
  }
}
