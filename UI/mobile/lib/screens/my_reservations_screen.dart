import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/reservation_model.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({Key? key}) : super(key: key);

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? 0;

      if (mounted) {
        Provider.of<ReservationProvider>(context, listen: false)
            .getUserReservations(
          userId: userId,
          page: _currentPage,
        );
      }
    });
  }

  void _onScroll() async {
    if (!_scrollController.hasClients) return;

    final provider =
        Provider.of<ReservationProvider>(context, listen: false);

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        provider.hasMore) {
      _isFetchingMore = true;
      _currentPage++;

      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);

      await provider.getUserReservations(
        userId: authProvider.user?.id ?? 0,
        page: _currentPage,
      );

      _isFetchingMore = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
          if (provider.isLoading && provider.reservations.isEmpty) {
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
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/home');
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Idi na mapu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: provider.hasMore
                ? provider.reservations.length + 1
                : provider.reservations.length,
            itemBuilder: (context, index) {
              if (index < provider.reservations.length) {
                final reservation = provider.reservations[index];
                return _buildReservationCard(context, reservation);
              } else {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
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
    final statusIcon = _getStatusIcon(reservation.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kod: ${reservation.reservationCode}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: statusColor),
                            const SizedBox(width: 5),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${reservation.finalPrice.toStringAsFixed(2)}KM',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${reservation.durationInHours}h',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRowWithIcon(
                    Icons.access_time,
                    'Početak',
                    '${reservation.reservationStart.hour.toString().padLeft(2, '0')}:${reservation.reservationStart.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRowWithIcon(
                    Icons.schedule,
                    'Završetak',
                    '${reservation.reservationEnd.hour.toString().padLeft(2, '0')}:${reservation.reservationEnd.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRowWithIcon(
                    Icons.timelapse,
                    'Trajanje',
                    '${reservation.durationInHours} sati',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [

                const SizedBox(width: 8),
                if (reservation.status == 1 || reservation.status == 2)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _cancelReservation(context, reservation),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Otkaži',
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRowWithIcon(
      IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _cancelReservation(
      BuildContext context, Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkaži rezervaciju?'),
        content: Text(
          'Jeste li sigurni da želite otkazati rezervaciju ${reservation.reservationCode}?',
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

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.schedule;
      case 2:
        return Icons.check_circle;
      case 3:
        return Icons.done_all;
      case 4:
        return Icons.cancel;
      case 5:
        return Icons.close;
      default:
        return Icons.help;
    }
  }
}