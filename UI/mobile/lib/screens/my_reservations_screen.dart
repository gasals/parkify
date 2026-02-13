import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/reservation_model.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';

class MyReservationsScreen extends StatefulWidget {
  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? 0;
      
      Provider.of<ReservationProvider>(context, listen: false)
          .getUserReservations(userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje rezervacije'),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<ReservationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nemaš rezervacije',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kreiraj prvu rezervaciju na mapi',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.reservations.length,
            itemBuilder: (context, index) {
              final reservation = provider.reservations[index];
              return _buildReservationCard(context, reservation);
            },
          );
        },
      ),
    );
  }

  Widget _buildReservationCard(
      BuildContext context, Reservation reservation) {
    final statusColor = _getStatusColor(reservation.status);
    final statusText = reservation.getStatusText();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kod: ${reservation.reservationCode}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${reservation.finalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Vrijeme početka',
                    '${reservation.reservationStart.hour.toString().padLeft(2, '0')}:${reservation.reservationStart.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Vrijeme završetka',
                    '${reservation.reservationEnd.hour.toString().padLeft(2, '0')}:${reservation.reservationEnd.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Trajanje',
                    '${reservation.durationInHours}h',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/reservation-details',
                        arguments: reservation,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Detalji',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (reservation.status == 1 || reservation.status == 2)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelReservation(context, reservation),
                      child: const Text('Otkaži'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _cancelReservation(
      BuildContext context, Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkaži rezervaciju?'),
        content: Text(
          'Jeste li sigurni da želite da otažete rezervaciju ${reservation.reservationCode}?',
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Ne'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider =
                  Provider.of<ReservationProvider>(context, listen: false);
              final success =
                  await provider.cancelReservation(reservation.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rezervacija je otkazana'),
                  ),
                );
              }
            },
            child: const Text('Otkaži'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.grey;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
