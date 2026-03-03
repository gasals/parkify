import 'dart:convert';
import 'package:admin/constants/app_urls.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String? _token;
  static const Duration _timeout = Duration(seconds: 30);

  static void setToken(String token) => _token = token;
  static void logout() => _token = null;

  static Map<String, String> _getHeaders() => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
    'ngrok-skip-browser-warning': 'true',
  };

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Neautorizovan pristup');
    }
    throw Exception('Greška: ${response.statusCode}');
  }

  static Future<Map<String, String>> _buildQueryParams({
    int? page,
    int? pageSize,
    Map<String, dynamic>? filters,
  }) async {
    final params = <String, String>{};

    if (page != null) params['page'] = page.toString();
    if (pageSize != null) params['pageSize'] = pageSize.toString();

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          params[key] = value.toString();
        }
      });
    }

    return params;
  }

  static Uri _buildUri(String endpoint, Map<String, String> params) =>
      Uri.parse(endpoint).replace(queryParameters: params.isNotEmpty ? params : null);

  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppUrls.users}/login?username=$username&password=$password'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Login greška: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.users}/$userId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri preuzimanju korisnika: $e');
    }
  }

  static Future<void> changePassword({
    required int userId,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.users}/$userId/change-password'),
            headers: _getHeaders(),
            body: jsonEncode({'password': password, 'passwordConfirm': passwordConfirm}),
          )
          .timeout(_timeout);

      await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri promjeni lozinke: $e');
    }
  }

  // USERS
  static Future<Map<String, dynamic>> searchUsers({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {'username': username, 'email': email, 'firstName': firstName, 'lastName': lastName},
      );

      final response = await http.get(_buildUri(AppUrls.users, params), headers: _getHeaders()).timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri pretrazi korisnika: $e');
    }
  }

  static Future<Map<String, dynamic>> getAllUsers({int page = 1, int pageSize = 1000}) async {
    try {
      final params = await _buildQueryParams(page: page, pageSize: pageSize);
      final response = await http.get(_buildUri(AppUrls.users, params), headers: _getHeaders()).timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri preuzimanju korisnika: $e');
    }
  }

  static Future<Map<String, dynamic>> createUser({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    required String firstName,
    required String lastName,
    String? address,
    String? city,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.users),
            headers: _getHeaders(),
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
              'passwordConfirm': passwordConfirm,
              'firstName': firstName,
              'lastName': lastName,
              'address': address ?? '',
              'city': city ?? '',
              'isAdmin': true
            }),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri kreiranju korisnika: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? email,
    String? firstName,
    String? lastName,
    String? address,
    String? city,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (email != null) body['email'] = email;
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (address != null) body['address'] = address;
      if (city != null) body['city'] = city;

      final response = await http
          .put(
            Uri.parse('${AppUrls.users}/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri ažuriranju korisnika: $e');
    }
  }

  static Future<Map<String, dynamic>> toggleUserActive({
    required int userId,
    required bool isActive,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${AppUrls.users}/$userId/toggle-active'),
            headers: _getHeaders(),
            body: jsonEncode({'isActive': isActive}),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri promjeni statusa: $e');
    }
  }

  // CITIES
  static Future<Map<String, dynamic>> getAllCities({int page = 1, int pageSize = 100}) async {
    try {
      final params = await _buildQueryParams(page: page, pageSize: pageSize);
      final response = await http.get(_buildUri(AppUrls.cities, params), headers: _getHeaders()).timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri preuzimanju gradova: $e');
    }
  }

  static Future<Map<String, dynamic>> getCityById({required int cityId}) async {
    try {
      final response = await http
          .get(Uri.parse('${AppUrls.cities}/$cityId'), headers: _getHeaders())
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri preuzimanju grada: $e');
    }
  }

  static Future<Map<String, dynamic>> searchCities({String? name}) async {
    try {
      final params = await _buildQueryParams(pageSize: 1000, filters: {'name': name});
      final response = await http.get(_buildUri(AppUrls.cities, params), headers: _getHeaders()).timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri pretrazi gradova: $e');
    }
  }

  // PARKING ZONES
  static Future<Map<String, dynamic>> searchParkingZones({
    String? name,
    int? cityId,
    int page = 1,
    int pageSize = 20,
    bool includeSpots = true,
  }) async {
    try {
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {'name': name, 'cityId': cityId, 'includeSpots': includeSpots},
      );

      final response = await http
          .get(_buildUri(AppUrls.parkingZones, params), headers: _getHeaders())
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri pretrazi parking zona: $e');
    }
  }

  static Future<Map<String, dynamic>> createParkingZone({
    required String name,
    required String description,
    required String address,
    required String city,
    required double latitude,
    required double longitude,
    required double pricePerHour,
    double? dailyRate,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.parkingZones),
            headers: _getHeaders(),
            body: jsonEncode({
              'name': name,
              'description': description,
              'address': address,
              'city': city,
              'latitude': latitude,
              'longitude': longitude,
              'pricePerHour': pricePerHour,
              'dailyRate': dailyRate ?? 0,
              'isActive': false,
            }),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri kreiranju zone: $e');
    }
  }

  static Future<Map<String, dynamic>> updateParkingZone({
    required int zoneId,
    String? name,
    String? description,
    String? address,
    double? pricePerHour,
    double? dailyRate,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (address != null) body['address'] = address;
      if (pricePerHour != null) body['pricePerHour'] = pricePerHour;
      if (dailyRate != null) body['dailyRate'] = dailyRate;
      if (isActive != null) body['isActive'] = isActive;

      final response = await http
          .put(
            Uri.parse('${AppUrls.parkingZones}/$zoneId'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri ažuriranju zone: $e');
    }
  }

  // PARKING SPOTS
  static Future<Map<String, dynamic>> createParkingSpot({
    required int parkingZoneId,
    required int type,
    required int? rowNumber,
    required int? columnNumber,
    required bool isAvailable,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.parkingSpots),
            headers: _getHeaders(),
            body: jsonEncode({
              'parkingZoneId': parkingZoneId,
              'type': type,
              'rowNumber': rowNumber,
              'columnNumber': columnNumber,
              'isAvailable': isAvailable,
            }),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri dodavanju spota: $e');
    }
  }

  static Future<Map<String, dynamic>> updateParkingSpot({
    required int spotId,
    String? spotCode,
    int? type,
    int? rowNumber,
    int? columnNumber,
    bool? isAvailable,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (spotCode != null) body['spotCode'] = spotCode;
      if (type != null) body['type'] = type;
      if (rowNumber != null) body['rowNumber'] = rowNumber;
      if (columnNumber != null) body['columnNumber'] = columnNumber;
      if (isAvailable != null) body['isAvailable'] = isAvailable;

      final response = await http
          .put(
            Uri.parse('${AppUrls.parkingSpots}/$spotId'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri ažuriranju spota: $e');
    }
  }

  static Future<void> deleteParkingSpot(int spotId) async {
    try {
      final response = await http
          .delete(Uri.parse('${AppUrls.parkingSpots}/$spotId'), headers: _getHeaders())
          .timeout(_timeout);

      await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri brisanju spota: $e');
    }
  }

  static Future<Map<String, dynamic>> toggleParkingSpotActive({
    required int spotId,
    required bool isAvailable,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls}/$spotId'),
            headers: _getHeaders(),
            body: jsonEncode({'isAvailable': isAvailable}),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri promjeni statusa spota: $e');
    }
  }

  // RESERVATIONS
  static Future<Map<String, dynamic>> searchReservations({
    int? userId,
    int? parkingZoneId,
    int? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {'userId': userId, 'parkingZoneId': parkingZoneId, 'status': status},
      );

      final response = await http
          .get(_buildUri(AppUrls.reservations, params), headers: _getHeaders())
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri pretrazi rezervacija: $e');
    }
  }

  static Future<Map<String, dynamic>> updateReservationStatus(int reservationId, int status) async {
    try {
      var data = {
        'status': status
      };
      final response = await http
          .put(
            Uri.parse('${AppUrls.reservations}/$reservationId'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri ažuriranju statusa: $e');
    }
  }

  static Future<Map<String, dynamic>> checkInReservation(int reservationId) async {
    try {
      var data = {
        'isCheckedIn': true,
        'checkInTime': DateTime.now().toIso8601String(),
      };
      final response = await http
          .put(
            Uri.parse('${AppUrls.reservations}/$reservationId'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri check-in-u: $e');
    }
  }

  static Future<Map<String, dynamic>> checkOutReservation(int reservationId) async {
    try {
      var data = {
        'isCheckedOut': true,
        'checkOutTime': DateTime.now().toIso8601String(),
      };
      final response = await http
          .put(
            Uri.parse('${AppUrls.reservations}/$reservationId'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri check-out-u: $e');
    }
  }

  static Future<Map<String, dynamic>> getNotifications({
    int? userId,
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {
          if (userId != null) 'userId': userId,
          if (isRead != null) 'isRead': isRead,
        },
      );

      final response = await http
          .get(
            _buildUri(AppUrls.notifications, params),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri učitavanju notifikacija: $e');
    }
  }

  static Future<void> sendNotification(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppUrls.notifications}/send'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri slanju notifikacije: $e');
    }
  }

  static Future<void> sendNotificationToAll(
      Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppUrls.notifications}/send-all'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri slanju notifikacija svima: $e');
    }
  }

  static Future<void> markNotificationRead(int id) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${AppUrls.notifications}/$id/read'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      await _handleResponse(response);
    } catch (e) {
      throw Exception('Greška pri označavanju notifikacije: $e');
    }
  }

  
}
