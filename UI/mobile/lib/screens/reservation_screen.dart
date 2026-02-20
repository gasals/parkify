import 'package:flutter/material.dart';
import 'package:mobile/providers/payment_provider.dart';
import 'package:mobile/services/navigation_service.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/parking_zone_model.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';

class ReservationScreen extends StatefulWidget {
  final ParkingZone parkingZone;
  final ParkingSpot parkingSpot;

  const ReservationScreen({
    Key? key,
    required this.parkingZone,
    required this.parkingSpot,
  }) : super(key: key);

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  late DateTime _startTime;
  late double _durationHours;
  late DateTime _endTime;
  String _reservationCode = '';
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().add(const Duration(hours: 1));
    _durationHours = 1;
    _endTime = _startTime.add(Duration(hours: _durationHours.toInt()));
  }

  double get _calculatedPrice => widget.parkingZone.pricePerHour * _durationHours;

  void _updateEndTime() {
    setState(() {
      _endTime = _startTime.add(Duration(
        hours: _durationHours.toInt(),
        minutes: ((_durationHours - _durationHours.toInt()) * 60).toInt(),
      ));
    });
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );

    if (picked != null) {
      setState(() {
        _startTime = DateTime(
          _startTime.year,
          _startTime.month,
          _startTime.day,
          picked.hour,
          picked.minute,
        );
        _updateEndTime();
      });
    }
  }

  Future<void> _makeReservation(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

    try {
      final reservationData = {
        'userId': authProvider.user!.id,
        'parkingZoneId': widget.parkingZone.id,
        'parkingSpotId': widget.parkingSpot.id,
        'reservationStart': _startTime.toIso8601String(),
        'reservationEnd': _endTime.toIso8601String(),
        'requiresDisabledSpot': false,
      };

      final reservation = await reservationProvider.createReservation(reservationData);

      if (reservation.id == 0) {
        throw Exception('Greška pri kreiranju rezervacije');
      }

      final payment = await paymentProvider.createPayment(
        reservationId: reservation.id,
        userId: authProvider.user!.id,
        amount: _calculatedPrice,
      );

      if (payment.id == 0) {
        throw Exception('Greška pri kreiranju plaćanja');
      }

      final paymentSuccess = await paymentProvider.presentPaymentSheet(
        clientSecret: payment.clientSecret,
      );

      if (!paymentSuccess) {
        throw Exception('Plaćanje je otkazano');
      }

      final confirmed = await paymentProvider.confirmPayment(
        paymentId: payment.id,
      );

      if (confirmed) {
        setState(() {
          _reservationCode = payment.paymentCode;
          _isConfirmed = true;
        });
      } else {
        throw Exception('Plaćanje nije potvrđeno');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConfirmed) {
      return _buildConfirmedScreen(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezerviši mjesto'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.parkingZone.name} - ${widget.parkingSpot.spotCode}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Vrijeme početka',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectStartTime(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.access_time, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Procjena trajanja',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_durationHours.toStringAsFixed(1)}h',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_calculatedPrice.toStringAsFixed(2)}KM',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: _durationHours,
                      onChanged: (value) {
                        setState(() {
                          _durationHours = value;
                          _updateEndTime();
                        });
                      },
                      min: 0.5,
                      max: 24,
                      divisions: 47,
                      label: '${_durationHours.toStringAsFixed(1)}h',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Završetak: ${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Consumer2<ReservationProvider, PaymentProvider>(
                  builder: (context, reservationProvider, paymentProvider, _) {
                    final isLoading =
                        reservationProvider.isLoading || paymentProvider.isLoading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : () => _makeReservation(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: isLoading
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
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmedScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervacija potvrđena'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Plaćanje uspješno!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'QR kod za unos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _reservationCode.substring(0, 8).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kod: $_reservationCode',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildDetailRow('Parking', widget.parkingZone.name),
              _buildDetailRow('Mjesto', widget.parkingSpot.spotCode),
              _buildDetailRow(
                'Početak',
                '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
              ),
              _buildDetailRow(
                'Trajanje',
                '${_durationHours.toStringAsFixed(1)}h',
              ),
              _buildDetailRow(
                'Cijena',
                '${_calculatedPrice.toStringAsFixed(2)}KM',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _startNavigation();
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text(
                    'Kreni na parking',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                  ),
                  child: Text(
                    'Nazad na mapu',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startNavigation() {
    NavigationService.startNavigation(
      destinationLat: widget.parkingZone.latitude,
      destinationLng: widget.parkingZone.longitude,
      destinationName: widget.parkingZone.name,
    ).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
