import 'package:flutter/material.dart';
import 'package:mobile/screens/reservation_screen.dart';
import '../constants/app_colors.dart';
import '../models/parking_zone_model.dart';

class ParkingDetailsScreen extends StatefulWidget {
  final ParkingZone parkingZone;

  const ParkingDetailsScreen({
    Key? key,
    required this.parkingZone,
  }) : super(key: key);

  @override
  State<ParkingDetailsScreen> createState() => _ParkingDetailsScreenState();
}

class _ParkingDetailsScreenState extends State<ParkingDetailsScreen> {
  ParkingSpot? _selectedSpot;

  @override
  Widget build(BuildContext context) {
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
                        '${widget.parkingZone.address}, ${widget.parkingZone.city}',
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${widget.parkingZone.totalSpots}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Slobodno mjesta'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${widget.parkingZone.disabledSpots}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Invalidska mjesta'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Odaberite mjesto',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.parkingZone.spots != null && widget.parkingZone.spots!.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: widget.parkingZone.spots!.length,
                  itemBuilder: (context, index) {
                    final spot = widget.parkingZone.spots![index];
                    final isSelected = _selectedSpot?.id == spot.id;
                    final isAvailable = spot.isAvailable;
                    final isDisabled = spot.type == 2;

                    return GestureDetector(
                      onTap: isAvailable
                          ? () {
                              setState(() {
                                _selectedSpot = spot;
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isDisabled
                                  ? Icons.wheelchair_pickup
                                  : Icons.local_parking,
                              size: 24,
                              color: isSelected
                                  ? Colors.white
                                  : isAvailable
                                      ? AppColors.primary
                                      : AppColors.textTertiary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              spot.spotCode.split('-').last,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
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
                      child: Row(
                        children: [
                          Icon(
                            _selectedSpot!.type == 2
                                ? Icons.wheelchair_pickup
                                : Icons.local_parking,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Odabrano mjesto: ${_selectedSpot!.spotCode}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedSpot!.type == 2)
                                const Text(
                                  'Invalidsko mjesto',
                                  style: TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ],
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
