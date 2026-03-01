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
      headers['ngrok-skip-browser-warning'] = 'true';
    }

    return headers;
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final credentials = '$username:$password';
      final encoded = base64Encode(utf8.encode(credentials));

      final response = await http
          .post(
            Uri.parse('${AppUrls.login}?username=$username&password=$password'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Basic $encoded',
            },
          )
          .timeout(Duration(seconds: 10));

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

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.register),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(userData),
          )
          .timeout(Duration(seconds: 10));

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
      final response = await http
          .get(
            Uri.parse(
              '${AppUrls.parkingZones}?page=$page&pageSize=$pageSize&includeSpots=$includeSpots',
            ),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Greška pri učitavanju parking zona: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> getParkingZoneById(int id) async {
    try {
      final response = await http
          .get(Uri.parse('${AppUrls.parkingZones}/$id'), headers: _getHeaders())
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju parking zone');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> updateParkingZone({
    required int zoneId,
    required String? name,
    required String? description,
    required String? address,
    required double? pricePerHour,
    required double? dailyRate,
    required bool? isActive,
  }) async {
    try {
      var data = {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (address != null) 'address': address,
        if (pricePerHour != null) 'pricePerHour': pricePerHour,
        if (dailyRate != null) 'dailyRate': dailyRate,
        if (isActive != null) 'isActive': isActive,
      };

      var response = await http
          .put(
            Uri.parse('${AppUrls.parkingZones}/$zoneId'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri ažuriranju parking zone');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> createParkingSpot({
    required int parkingZoneId,
    required int type,
    required int? rowNumber,
    required int? columnNumber,
    required bool isAvailable,
  }) async {
    try {
      var data = {
        'parkingZoneId': parkingZoneId,
        'type': type,
        'rowNumber': rowNumber,
        'columnNumber': columnNumber,
        'isAvailable': isAvailable,
      };

      var response = await http
          .post(
            Uri.parse('${AppUrls.baseUrl}/parkingspots'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri kreiranju parking spota');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> updateParkingSpot({
    required int spotId,
    required String? spotCode,
    required int? type,
    required int? rowNumber,
    required int? columnNumber,
    required bool? isAvailable,
    bool? isActive,
  }) async {
    try {
      var data = {
        if (spotCode != null) 'spotCode': spotCode,
        if (type != null) 'type': type,
        if (rowNumber != null) 'rowNumber': rowNumber,
        if (columnNumber != null) 'columnNumber': columnNumber,
        if (isAvailable != null) 'isAvailable': isAvailable,
      };

      var response = await http
          .put(
            Uri.parse('${AppUrls.baseUrl}/parkingspots/$spotId'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri ažuriranju parking spota');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<bool> deleteParkingSpot(int spotId) async {
    try {
      var response = await http
          .delete(
            Uri.parse('${AppUrls.baseUrl}/parkingspots/$spotId'),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Greška pri brisanju parking spota');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> createReservation(
    Map<String, dynamic> reservationData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.reservations),
            headers: _getHeaders(),
            body: jsonEncode(reservationData),
          )
          .timeout(Duration(seconds: 10));

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
      final response = await http
          .get(
            Uri.parse(
              '${AppUrls.reservations}?userId=$userId&page=$page&pageSize=$pageSize',
            ),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju rezervacija');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> getAllReservations({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.reservations}?page=$page&pageSize=$pageSize'),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju rezervacija');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> updateReservationStatus(
    int reservationId,
    int status,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.reservations}/$reservationId'),
            headers: _getHeaders(),
            body: jsonEncode({'status': status}),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri ažuriranju statusa rezervacije');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> checkInReservation(
    int reservationId,
  ) async {
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
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri check-in-u');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> checkOutReservation(
    int reservationId,
  ) async {
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
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri check-out-u');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> cancelReservation(
    int reservationId,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.reservations}/$reservationId'),
            headers: _getHeaders(),
            body: jsonEncode({'status': 5}),
          )
          .timeout(Duration(seconds: 10));

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
      final response = await http
          .get(
            Uri.parse(
              '${AppUrls.notifications}?userId=$userId&page=$page&pageSize=$pageSize',
            ),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju notifikacija');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> createReview(
    Map<String, dynamic> reviewData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.reviews),
            headers: _getHeaders(),
            body: jsonEncode(reviewData),
          )
          .timeout(Duration(seconds: 10));

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
      final response = await http
          .get(
            Uri.parse(
              '${AppUrls.reviews}?parkingZoneId=$parkingZoneId&page=$page&pageSize=$pageSize',
            ),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju recenzija');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> createPayment({
    required int reservationId,
    required int userId,
    required double amount,
  }) async {
    try {
      var data = {
        'reservationId': reservationId,
        'userId': userId,
        'amount': amount,
        'currency': 'bam',
      };

      var response = await http
          .post(
            Uri.parse('${AppUrls.payments}/create-with-intent'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri kreiranju plaćanja');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> confirmPayment({
    required int paymentId,
  }) async {
    try {
      var response = await http
          .put(
            Uri.parse('${AppUrls.payments}/$paymentId/confirm'),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri potvrdi plaćanja');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserPayments({
    required int userId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      var response = await http
          .get(
            Uri.parse(
              '${AppUrls.payments}?userId=$userId&page=$page&pageSize=$pageSize',
            ),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju plaćanja');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> refundPayment({
    required int paymentId,
    required String reason,
  }) async {
    try {
      var data = {'reason': reason};

      var response = await http
          .put(
            Uri.parse('${AppUrls.payments}/$paymentId/refund'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri vraćanju plaćanja');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserPreference({
    required int userId,
  }) async {
    try {
      var response = await http
          .get(
            Uri.parse('${AppUrls.preferences}/user/$userId'),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju preference');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUserPreferences({
    required int userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      var response = await http
          .put(
            Uri.parse('${AppUrls.preferences}/user/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(preferences),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri ažuriranju preference');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> updatePreference({
    required int userId,
    required Map<String, dynamic> preferenceData,
  }) async {
    try {
      var response = await http
          .put(
            Uri.parse('${AppUrls.preferences}/user/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(preferenceData),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri ažuriranju preference');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> getAllCities({
    int page = 1,
    int pageSize = 1000,
  }) async {
    try {
      var response = await http
          .get(
            Uri.parse('${AppUrls.cities}?page=$page&pageSize=$pageSize'),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Greška pri učitavanju gradova: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> getCityById({required int cityId}) async {
    try {
      var response = await http
          .get(Uri.parse('${AppUrls.cities}/$cityId'), headers: _getHeaders())
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju grada: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    required String? email,
    required String? firstName,
    required String? lastName,
    required String? address,
    required String? city,
  }) async {
    try {
      var data = {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'address': address,
        'city': city,
      };

      var response = await http
          .put(
            Uri.parse('${AppUrls.baseUrl}/users/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Greška pri ažuriranju korisnika: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<bool> changePassword({
    required int userId,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      var data = {'password': password, 'passwordConfirm': passwordConfirm};

      var response = await http
          .put(
            Uri.parse('${AppUrls.baseUrl}/users/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Greška pri promjeni lozinke: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> toggleUserActive({
    required int userId,
    required bool isActive,
  }) async {
    try {
      var data = {'isActive': isActive};

      var response = await http
          .put(
            Uri.parse('${AppUrls.baseUrl}/users/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri promjeni statusa korisnika');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.baseUrl}/users?page=$page&pageSize=$pageSize'),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška pri učitavanju korisnika');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<Map<String, dynamic>> searchReservations({
    int? userId,
    int? parkingZoneId,
    int? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (userId != null) {
        queryParams['userId'] = userId.toString();
      }
      if (parkingZoneId != null) {
        queryParams['parkingZoneId'] = parkingZoneId.toString();
      }
      if (status != null) {
        queryParams['status'] = status.toString();
      }

      final uri = Uri.parse(
        AppUrls.reservations,
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Greška pri pretrazi rezervacija: $e');
    }
  }

  static Future<Map<String, dynamic>> searchUsers({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (username != null && username.trim().isNotEmpty) {
        queryParams['username'] = username.trim();
      }
      if (email != null && email.trim().isNotEmpty) {
        queryParams['email'] = email.trim();
      }
      if (firstName != null && firstName.trim().isNotEmpty) {
        queryParams['firstName'] = firstName.trim();
      }
      if (lastName != null && lastName.trim().isNotEmpty) {
        queryParams['lastName'] = lastName.trim();
      }

      final uri = Uri.parse(
        AppUrls.users,
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        throw Exception('Greška: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Greška pri pretrazi korisnika: $e');
    }
  }

  static Future<Map<String, dynamic>> searchParkingZones({
    String? name,
    int? cityId,
    int page = 1,
    int pageSize = 20,
    bool includeSpots = true,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'includeSpots': includeSpots.toString(),
      };

      if (name != null && name.trim().isNotEmpty) {
        queryParams['name'] = name.trim();
      }
      if (cityId != null) {
        queryParams['cityId'] = cityId.toString();
      }

      final uri = Uri.parse(
        AppUrls.parkingZones,
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška: ${response.statusCode}');
      }
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
      final body = {
        'name': name,
        'description': description,
        'address': address,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'pricePerHour': pricePerHour,
        'dailyRate': dailyRate ?? 0,
        'isActive': false,
      };

      final response = await http
          .post(
            Uri.parse('${AppUrls.baseUrl}/parkingzones'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Greška pri kreiranju zone: $e');
    }
  }

  static Future<Map<String, dynamic>> toggleParkingSpotActive({
    required int spotId,
    required bool isAvailable,
  }) async {
    try {
      final body = {'isAvailable': isAvailable};

      final response = await http
          .put(
            Uri.parse('${AppUrls.baseUrl}/parkingspots/$spotId'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Greška pri updateanju: $e');
    }
  }

  static Future<List<dynamic>> searchParkingZonesList({String? name}) async {
    try {
      final queryParams = <String, String>{'pageSize': '1000'};

      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }

      final uri = Uri.parse(
        '${AppUrls.baseUrl}/parkingzones',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['results'] ?? [];
      } else {
        throw Exception('Greška pri pretrazi zona');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<List<dynamic>> getAllUsersList() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.baseUrl}/users?pageSize=1000'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['results'] ?? [];
      } else {
        throw Exception('Greška pri preuzimanju korisnika');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<List<dynamic>> searchUsersList({
    String? username,
    String? email,
  }) async {
    try {
      final queryParams = <String, String>{'pageSize': '1000'};

      if (username != null && username.isNotEmpty) {
        queryParams['username'] = username;
      }
      if (email != null && email.isNotEmpty) {
        queryParams['email'] = email;
      }

      final uri = Uri.parse(
        '${AppUrls.baseUrl}/users',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['results'] ?? [];
      } else {
        throw Exception('Greška pri pretrazi korisnika');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<List<dynamic>> getAllParkingZonesList() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppUrls.baseUrl}/parkingzones?pageSize=1000'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['results'] ?? [];
      } else {
        throw Exception('Greška pri preuzimanju zona');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }

  static Future<List<dynamic>> searchParkingZonesListForReservation({
    String? name,
  }) async {
    try {
      final queryParams = <String, String>{'pageSize': '1000'};

      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }

      final uri = Uri.parse(
        '${AppUrls.baseUrl}/parkingzones',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['results'] ?? [];
      } else {
        throw Exception('Greška pri pretrazi zona');
      }
    } catch (e) {
      throw Exception('Greška: $e');
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
      final body = {
        'username': username,
        'email': email,
        'password': password,
        'passwordConfirm': passwordConfirm,
        'firstName': firstName,
        'lastName': lastName,
        'address': address ?? '',
        'city': city ?? '',
      };

      final response = await http
          .post(
            Uri.parse(AppUrls.register),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Greška: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Greška pri kreiranju korisnika: $e');
    }
  }

  static Future<List<dynamic>> searchCitiesList({String? name}) async {
    try {
      final queryParams = <String, String>{'pageSize': '1000'};

      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }

      final uri = Uri.parse(
        AppUrls.cities,
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['results'] ?? [];
      } else {
        throw Exception('Greška pri pretrazi gradova');
      }
    } catch (e) {
      throw Exception('Greška: $e');
    }
  }
}
