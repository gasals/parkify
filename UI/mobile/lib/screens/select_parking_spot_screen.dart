import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/parking_zone_model.dart';

class SelectParkingSpotScreen extends StatefulWidget {
  final ParkingZone zone;

  const SelectParkingSpotScreen({required this.zone});

  @override
  State<SelectParkingSpotScreen> createState() =>
      _SelectParkingSpotScreenState();
}

class _SelectParkingSpotScreenState extends State<SelectParkingSpotScreen> {
  ParkingSpot? _selectedSpot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odaberi parking mjesto'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.zone.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${widget.zone.pricePerHour}/sat',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedSpot != null)
                    Text(
                      _selectedSpot!.spotCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Dostupnih mjesta: ${widget.zone.totalSpots}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            if (widget.zone.spots != null && widget.zone.spots!.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.zone.spots!.length,
                itemBuilder: (context, index) {
                  final spot = widget.zone.spots![index];
                  final isSelected = _selectedSpot?.id == spot.id;
                  final isAvailable = spot.isAvailable;

                  return GestureDetector(
                    onTap: isAvailable
                        ? () {
                            setState(() => _selectedSpot = spot);
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_parking,
                            size: 20,
                            color: isSelected
                                ? Colors.white
                                : isAvailable
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            spot.spotCode,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
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
              )
            else
              Center(
                child: Text(
                  'Nema dostupnih mjesta',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),

            const SizedBox(height: 24),

            Row(
              children: [
                _buildLegendItem('Dostupno', AppColors.primary),
                const SizedBox(width: 16),
                _buildLegendItem('Zauzeto', AppColors.surfaceVariant),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedSpot != null
                    ? () {
                        Navigator.of(context).pushNamed(
                          '/make-reservation',
                          arguments: {
                            'zone': widget.zone,
                            'spot': _selectedSpot,
                          },
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Nastavi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppColors.border),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
