import 'package:flutter/material.dart';
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

  Widget _buildSheetContainer({required Widget child}) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildGrid(List<ParkingSpot> sortedSpots, int maxColumn, int maxRow) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(maxRow, (rowIndex) {
              final rowNumber = rowIndex + 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                        type: ParkingSpotType.regular.value,
                        isAvailable: false,
                      ),
                    );

                    if (spot.id == -1) {
                      return Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }

                    final isSelected = _selectedSpot?.id == spot.id;
                    final isAvailable = spot.isAvailable;
                    final isDisabled =
                        spot.type == ParkingSpotType.disabled.value;

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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedSpots = _getSortedSpots();
    final screen = MediaQuery.of(context).size;
    final sheetHeight = screen.height * 0.82;

    if (sortedSpots.isEmpty) {
      return _buildSheetContainer(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.parkingZone.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text('Nema dostupnog rasporeda mjesta.'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Zatvori'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxColumn = _getMaxColumn(sortedSpots);
    final maxRow = _getMaxRow(sortedSpots);
    return _buildSheetContainer(
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
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
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.parkingZone.pricePerHour}KM/h',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Odaberite mjesto',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildGrid(sortedSpots, maxColumn, maxRow)),
              const SizedBox(height: 12),
              if (_selectedSpot != null)
                Container(
                  width: double.infinity,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Otkaži'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedSpot == null
                          ? null
                          : () => Navigator.of(context).pop(_selectedSpot),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Nastavi',
                        style: TextStyle(color: Colors.white),
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
