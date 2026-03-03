import 'package:admin/providers/city_provider.dart';
import 'package:admin/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/parking_zone_provider.dart';
import 'providers/user_provider.dart';
import 'providers/reservation_provider.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_panel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdminDesktopApp());
}

class AdminDesktopApp extends StatelessWidget {
  const AdminDesktopApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ParkingZoneProvider()),
        ChangeNotifierProvider(create: (_) => CityProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Parkify Admin Panel',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
          ),
        ),
        home: _buildHome(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  Widget _buildHome() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return authProvider.isAuthenticated
            ? const AdminPanelScreen()
            : const LoginScreen();
      },
    );
  }
}
