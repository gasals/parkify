import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
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

  static String _messageFromBody(
    String body, {
    String fallback = 'Došlo je do greške.',
  }) {
    if (body.isEmpty) return fallback;

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is String && error.isNotEmpty) return error;

        final message = decoded['message'];
        if (message is String && message.isNotEmpty) return message;

        final title = decoded['title'];
        if (title is String && title.isNotEmpty) return title;

        final errors = decoded['errors'];
        if (errors is Map<String, dynamic>) {
          final messages = <String>[];

          errors.forEach((_, value) {
            if (value is List) {
              messages.addAll(value.whereType<String>());
            } else if (value is String && value.isNotEmpty) {
              messages.add(value);
            }
          });

          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }
      }

      if (decoded is String && decoded.isNotEmpty) {
        return decoded;
      }
    } catch (_) {
      if (body.isNotEmpty) return body;
    }

    return fallback;
  }

  static String _messageFromError(Object error, String fallback) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? fallback : message;
  }

  static Never _throwWithMessage(Object error, String fallback) {
    throw Exception(_messageFromError(error, fallback));
  }

  static Future<Map<String, dynamic>> _handleResponse(
    http.Response response,
  ) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
        _messageFromBody(response.body, fallback: 'Neautorizovan pristup'),
      );
    }

    throw Exception(
      _messageFromBody(response.body, fallback: 'Greška: ${response.statusCode}'),
    );
  }

  static Future<Uint8List> _handleBytesResponse(
    http.Response response, {
    String fallback = 'Greška pri preuzimanju fajla.',
  }) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.bodyBytes;
    }

    throw Exception(_messageFromBody(response.body, fallback: fallback));
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
      Uri.parse(
        endpoint,
      ).replace(queryParameters: params.isNotEmpty ? params : null);

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppUrls.users}/login'),
            headers: _getHeaders(),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.login error: $e');
      _throwWithMessage(e, 'Login greška');
    }
  }

  static Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('${AppUrls.users}/$userId'), headers: _getHeaders())
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.getUserById error: $e');
      _throwWithMessage(e, 'Greška pri preuzimanju korisnika');
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
            Uri.parse('${AppUrls.users}/$userId'),
            headers: _getHeaders(),
            body: jsonEncode({
              'password': password,
              'passwordConfirm': passwordConfirm,
            }),
          )
          .timeout(_timeout);

      await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.changePassword error: $e');
      _throwWithMessage(e, 'Greška pri promjeni lozinke');
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
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {
          'username': username,
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
        },
      );

      final response = await http
          .get(_buildUri(AppUrls.users, params), headers: _getHeaders())
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.searchUsers error: $e');
      _throwWithMessage(e, 'Greška pri pretrazi korisnika');
    }
  }

  static Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int pageSize = 1000,
  }) async {
    try {
      final params = await _buildQueryParams(page: page, pageSize: pageSize);
      final response = await http
          .get(_buildUri(AppUrls.users, params), headers: _getHeaders())
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.getAllUsers error: $e');
      _throwWithMessage(e, 'Greška pri preuzimanju korisnika');
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
            }),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.createUser error: $e');
      _throwWithMessage(e, 'Greška pri kreiranju korisnika');
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
      log('Admin ApiService.updateUser error: $e');
      _throwWithMessage(e, 'Greška pri ažuriranju korisnika');
    }
  }

  static Future<Map<String, dynamic>> toggleUserActive({
    required int userId,
    required bool isActive,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.users}/$userId'),
            headers: _getHeaders(),
            body: jsonEncode({'isActive': isActive}),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.toggleUserActive error: $e');
      _throwWithMessage(e, 'Greška pri promjeni statusa');
    }
  }

  static Future<Map<String, dynamic>> getAllCities({
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final params = await _buildQueryParams(page: page, pageSize: pageSize);
      final response = await http
          .get(_buildUri(AppUrls.cities, params), headers: _getHeaders())
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.getAllCities error: $e');
      _throwWithMessage(e, 'Greška pri preuzimanju gradova');
    }
  }

  static Future<Map<String, dynamic>> getCityById({required int cityId}) async {
    try {
      final response = await http
          .get(Uri.parse('${AppUrls.cities}/$cityId'), headers: _getHeaders())
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.getCityById error: $e');
      _throwWithMessage(e, 'Greška pri preuzimanju grada');
    }
  }

  static Future<Map<String, dynamic>> searchCities({String? name}) async {
    try {
      final params = await _buildQueryParams(
        pageSize: 1000,
        filters: {'name': name},
      );
      final response = await http
          .get(_buildUri(AppUrls.cities, params), headers: _getHeaders())
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.searchCities error: $e');
      _throwWithMessage(e, 'Greška pri pretrazi gradova');
    }
  }

  static Future<Map<String, dynamic>> createCity({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.cities),
            headers: _getHeaders(),
            body: jsonEncode({
              'name': name,
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.createCity error: $e');
      _throwWithMessage(e, 'Greška pri kreiranju grada');
    }
  }

  static Future<Map<String, dynamic>> updateCity({
    required int cityId,
    String? name,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;

      final response = await http
          .put(
            Uri.parse('${AppUrls.cities}/$cityId'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.updateCity error: $e');
      _throwWithMessage(e, 'Greška pri ažuriranju grada');
    }
  }

  static Future<void> deleteCity(int cityId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${AppUrls.cities}/$cityId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);
      await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.deleteCity error: $e');
      _throwWithMessage(e, 'Greška pri brisanju grada');
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
      log('Admin ApiService.searchZones error: $e');
      _throwWithMessage(e, 'Greška pri pretrazi parking zona');
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
      log('Admin ApiService.createZone error: $e');
      _throwWithMessage(e, 'Greška pri kreiranju zone');
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
      log('Admin ApiService.updateZone error: $e');
      _throwWithMessage(e, 'Greška pri ažuriranju zone');
    }
  }

  static Future<void> deleteParkingZone(int zoneId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${AppUrls.parkingZones}/$zoneId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.deleteZone error: $e');
      _throwWithMessage(e, 'Greška pri brisanju zone');
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
      log('Admin ApiService.addSpot error: $e');
      _throwWithMessage(e, 'Greška pri dodavanju spota');
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
      log('Admin ApiService.updateSpot error: $e');
      _throwWithMessage(e, 'Greška pri ažuriranju spota');
    }
  }

  static Future<void> deleteParkingSpot(int spotId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${AppUrls.parkingSpots}/$spotId'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.deleteSpot error: $e');
      _throwWithMessage(e, 'Greška pri brisanju mjesta');
    }
  }

  static Future<Map<String, dynamic>> toggleParkingSpotActive({
    required int spotId,
    required bool isAvailable,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.parkingSpots}/$spotId'),
            headers: _getHeaders(),
            body: jsonEncode({'isAvailable': isAvailable}),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.toggleSpotActive error: $e');
      _throwWithMessage(e, 'Greška pri promjeni statusa spota');
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
      final params = await _buildQueryParams(
        page: page,
        pageSize: pageSize,
        filters: {
          'userId': userId,
          'parkingZoneId': parkingZoneId,
          'status': status,
        },
      );

      final response = await http
          .get(_buildUri(AppUrls.reservations, params), headers: _getHeaders())
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.searchReservations error: $e');
      _throwWithMessage(e, 'Greška pri pretrazi rezervacija');
    }
  }

  static Future<Uint8List> downloadReservationReportPdf({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await http
          .get(
            _buildUri('${AppUrls.reservations}/report/pdf', {
              if (from != null) 'from': from.toIso8601String(),
              if (to != null) 'to': to.toIso8601String(),
            }),
            headers: _getHeaders(),
          )
          .timeout(_timeout);
      return await _handleBytesResponse(
        response,
        fallback: 'Greška pri preuzimanju operativnog izvještaja.',
      );
    } catch (e) {
      log('Admin ApiService.downloadReservationReportPdf error: $e');
      _throwWithMessage(e, 'Greška pri preuzimanju operativnog izvještaja');
    }
  }

  static Future<Uint8List> downloadFinanceReportPdf({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await http
          .get(
            _buildUri('${AppUrls.reservations}/report/finance/pdf', {
              if (from != null) 'from': from.toIso8601String(),
              if (to != null) 'to': to.toIso8601String(),
            }),
            headers: _getHeaders(),
          )
          .timeout(_timeout);
      return await _handleBytesResponse(
        response,
        fallback: 'Greška pri preuzimanju finansijskog izvještaja.',
      );
    } catch (e) {
      log('Admin ApiService.downloadFinanceReportPdf error: $e');
      _throwWithMessage(e, 'Greška pri preuzimanju finansijskog izvještaja');
    }
  }

  static Future<Map<String, dynamic>> updateReservationStatus(
    int reservationId,
    int status,
  ) async {
    try {
      var data = {'status': status};
      final response = await http
          .put(
            Uri.parse('${AppUrls.reservations}/$reservationId'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.updateReservationStatus error: $e');
      _throwWithMessage(e, 'Greška pri ažuriranju statusa');
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
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      log('Admin ApiService.checkIn error: $e');
      _throwWithMessage(e, 'Greška pri check-in-u');
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
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      _throwWithMessage(e, 'Greška pri check-out-u');
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
          'userId': userId,
          'isRead': isRead,
        },
      );

      final response = await http
          .get(_buildUri(AppUrls.notifications, params), headers: _getHeaders())
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      _throwWithMessage(e, 'Greška pri učitavanju notifikacija');
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
      _throwWithMessage(e, 'Greška pri slanju notifikacije');
    }
  }

  static Future<void> sendNotificationToAll(Map<String, dynamic> body) async {
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
      _throwWithMessage(e, 'Greška pri slanju notifikacija svima');
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
      _throwWithMessage(e, 'Greška pri označavanju notifikacije');
    }
  }
}
