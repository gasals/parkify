import 'package:admin/screens/admin_notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_reservations_screen.dart';
import 'admin_users_screen.dart';
import 'admin_parking_zones_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedIndex = 0;

  final List<AdminMenuItem> _menuItems = [
    AdminMenuItem(
      icon: Icons.local_parking,
      label: 'Parking zone',
      index: 0,
    ),
    AdminMenuItem(
      icon: Icons.calendar_today,
      label: 'Rezervacije',
      index: 1,
    ),
    AdminMenuItem(
      icon: Icons.people,
      label: 'Korisnici',
      index: 2,
    ),
    AdminMenuItem(
      icon: Icons.notifications,
      label: 'Notifikacije',
      index: 3,
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF6366F1),
      elevation: 0,
      title: const Text(
        'Admin panel',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        const Icon(Icons.notifications, color: Colors.white),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Admin User',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              const Text(
                'System Administrator',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: Colors.grey[100],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  color: Color(0xFF6366F1),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Parkify',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == index;

                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : Colors.grey[600],
                    size: 24,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.grey[700],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: const Color(0xFF6366F1).withOpacity(0.1),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Odjava',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const AdminParkingZonesScreen();
      case 1:
        return const AdminReservationsScreen();
      case 2:
        return const AdminUsersScreen();
      case 3:
        return const AdminNotificationsScreen();
      default:
        return const AdminParkingZonesScreen();
    }
  }
}

class AdminMenuItem {
  final IconData icon;
  final String label;
  final int index;

  AdminMenuItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
