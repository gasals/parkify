import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_urls.dart';

class ApiService {
  static String? _username;
  static String? _password;

  static Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    
    if (_username != null && _password != null) {
      final credentials = '$_username:$_password';
      final encoded = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encoded';
    }
    
    return headers;
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final credentials = '$username:$password';
      final encoded = base64Encode(utf8.encode(credentials));
      
      final response = await http.post(
        Uri.parse('${AppUrls.login}?username=$username&password=$password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $encoded',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _username = username;
        _password = password;
        return data;
      } else {
        throw Exception('Prijava nije uspjela: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse(AppUrls.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Registracija nije uspjela');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static void logout() {
    _username = null;
    _password = null;
  }

  static Future<Map<String, dynamic>> getParkingZones({
    int page = 1,
    int pageSize = 10,
    bool includeSpots = true,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${AppUrls.parkingZones}?page=$page&pageSize=$pageSize&includeSpots=$includeSpots'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju parking zona: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> getParkingZoneById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AppUrls.parkingZones}/$id'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju parking zone');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> createReservation(Map<String, dynamic> reservationData) async {
    try {
      final response = await http.post(
        Uri.parse(AppUrls.reservations),
        headers: _getHeaders(),
        body: jsonEncode(reservationData),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri kreiranju rezervacije');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserReservations({
    required int userId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${AppUrls.reservations}?userId=$userId&page=$page&pageSize=$pageSize'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju rezervacija');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> cancelReservation(int reservationId) async {
    try {
      final response = await http.put(
        Uri.parse('${AppUrls.reservations}/$reservationId'),
        headers: _getHeaders(),
        body: jsonEncode({'status': 5}),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri otkazivanju rezervacije');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserNotifications({
    required int userId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${AppUrls.notifications}?userId=$userId&page=$page&pageSize=$pageSize'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju notifikacija');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> createReview(Map<String, dynamic> reviewData) async {
    try {
      final response = await http.post(
        Uri.parse(AppUrls.reviews),
        headers: _getHeaders(),
        body: jsonEncode(reviewData),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri kreiranju recenzije');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> getZoneReviews({
    required int parkingZoneId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${AppUrls.reviews}?parkingZoneId=$parkingZoneId&page=$page&pageSize=$pageSize'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju recenzija');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }
}