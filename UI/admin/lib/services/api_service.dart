import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:admin/constants/app_urls.dart';
import 'package:admin/models/api_models.dart';
import 'package:admin/models/city_model.dart';
import 'package:admin/models/notification_model.dart';
import 'package:admin/models/parking_spot_model.dart';
import 'package:admin/models/parking_zone_model.dart';
import 'package:admin/models/request_models.dart';
import 'package:admin/models/reservation_model.dart';
import 'package:admin/models/user_model.dart';
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

      if (decoded is Map) {
        final decodedMap = decoded.cast<String, Object?>();
        final error = decodedMap['error'];
        if (error is String && error.isNotEmpty) return error;

        final message = decodedMap['message'];
        if (message is String && message.isNotEmpty) return message;

        final title = decodedMap['title'];
        if (title is String && title.isNotEmpty) return title;

        final errors = decodedMap['errors'];
        if (errors is Map) {
          final messages = <String>[];

          errors.cast<Object?, Object?>().forEach((_, value) {
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

  static Map<String, Object?> _parseJsonMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }

    throw Exception('Neispravan format server odgovora.');
  }

  static Future<Map<String, Object?>> _handleObjectResponse(
    http.Response response,
  ) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) {
        return <String, Object?>{};
      }

      return _parseJsonMap(response.body);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
        _messageFromBody(response.body, fallback: 'Neautorizovan pristup'),
      );
    }

    throw Exception(
      _messageFromBody(response.body, fallback: 'Greška: ${response.statusCode}'),
    );
  }

  static Future<T> _handleModelResponse<T>(
    http.Response response,
    T Function(Map<String, Object?> json) fromJson,
  ) async {
    final json = await _handleObjectResponse(response);
    return fromJson(json);
  }

  static Future<PagedResponse<T>> _handlePagedResponse<T>(
    http.Response response,
    T Function(Map<String, Object?> json) fromJson,
  ) async {
    final json = await _handleObjectResponse(response);
    return PagedResponse<T>.fromJson(json, fromJson);
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
    Map<String, Object?>? filters,
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

  static Future<AuthSession> login(
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

      return await _handleModelResponse(response, AuthSession.fromJson);
    } catch (e) {
      log('Admin ApiService.login error: $e');
      _throwWithMessage(e, 'Login greška');
    }
  }

  static Future<User> getUserById(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('${AppUrls.users}/$userId'), headers: _getHeaders())
          .timeout(_timeout);
      return await _handleModelResponse(response, User.fromJson);
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

      await _handleObjectResponse(response);
    } catch (e) {
      log('Admin ApiService.changePassword error: $e');
      _throwWithMessage(e, 'Greška pri promjeni lozinke');
    }
  }

  static Future<PagedResponse<User>> searchUsers({
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
      return await _handlePagedResponse(response, User.fromJson);
    } catch (e) {
      log('Admin ApiService.searchUsers error: $e');
      _throwWithMessage(e, 'Greška pri pretrazi korisnika');
    }
  }

  static Future<PagedResponse<User>> getAllUsers({
    int page = 1,
    int pageSize = 1000,
  }) async {
    try {
      final params = await _buildQueryParams(page: page, pageSize: pageSize);
      final response = await http
          .get(_buildUri(AppUrls.users, params), headers: _getHeaders())
          .timeout(_timeout);
      return await _handlePagedResponse(response, User.fromJson);
    } catch (e) {
      log('Admin ApiService.getAllUsers error: $e');
      _throwWithMessage(e, 'Greška pri preuzimanju korisnika');
    }
  }

  static Future<User> createUser(UserCreateRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.users),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, User.fromJson);
    } catch (e) {
      log('Admin ApiService.createUser error: $e');
      _throwWithMessage(e, 'Greška pri kreiranju korisnika');
    }
  }

  static Future<User> updateUser({
    required int userId,
    required UserUpdateRequestDto request,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.users}/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, User.fromJson);
    } catch (e) {
      log('Admin ApiService.updateUser error: $e');
      _throwWithMessage(e, 'Greška pri ažuriranju korisnika');
    }
  }

  static Future<User> toggleUserActive({
    required int userId,
    required bool isActive,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.users}/$userId'),
            headers: _getHeaders(),
            body: jsonEncode(
              UserUpdateRequestDto(isActive: isActive).toJson(),
            ),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, User.fromJson);
    } catch (e) {
      log('Admin ApiService.toggleUserActive error: $e');
      _throwWithMessage(e, 'Greška pri promjeni statusa');
    }
  }

  static Future<PagedResponse<City>> getAllCities({
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final params = await _buildQueryParams(page: page, pageSize: pageSize);
      final response = await http
          .get(_buildUri(AppUrls.cities, params), headers: _getHeaders())
          .timeout(_timeout);
      return await _handlePagedResponse(response, City.fromJson);
    } catch (e) {
      log('Admin ApiService.getAllCities error: $e');
      _throwWithMessage(e, 'Greška pri preuzimanju gradova');
    }
  }

  static Future<City> getCityById({required int cityId}) async {
    try {
      final response = await http
          .get(Uri.parse('${AppUrls.cities}/$cityId'), headers: _getHeaders())
          .timeout(_timeout);
      return await _handleModelResponse(response, City.fromJson);
    } catch (e) {
      log('Admin ApiService.getCityById error: $e');
      _throwWithMessage(e, 'Greška pri preuzimanju grada');
    }
  }

  static Future<PagedResponse<City>> searchCities({String? name}) async {
    try {
      final params = await _buildQueryParams(
        pageSize: 1000,
        filters: {'name': name},
      );
      final response = await http
          .get(_buildUri(AppUrls.cities, params), headers: _getHeaders())
          .timeout(_timeout);
      return await _handlePagedResponse(response, City.fromJson);
    } catch (e) {
      log('Admin ApiService.searchCities error: $e');
      _throwWithMessage(e, 'Greška pri pretrazi gradova');
    }
  }

  static Future<City> createCity(CityUpsertRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.cities),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);
      return await _handleModelResponse(response, City.fromJson);
    } catch (e) {
      log('Admin ApiService.createCity error: $e');
      _throwWithMessage(e, 'Greška pri kreiranju grada');
    }
  }

  static Future<City> updateCity({
    required int cityId,
    required CityUpsertRequest request,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.cities}/$cityId'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);
      return await _handleModelResponse(response, City.fromJson);
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
      await _handleObjectResponse(response);
    } catch (e) {
      log('Admin ApiService.deleteCity error: $e');
      _throwWithMessage(e, 'Greška pri brisanju grada');
    }
  }

  static Future<PagedResponse<ParkingZone>> searchParkingZones({
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
      return await _handlePagedResponse(response, ParkingZone.fromJson);
    } catch (e) {
      log('Admin ApiService.searchZones error: $e');
      _throwWithMessage(e, 'Greška pri pretrazi parking zona');
    }
  }

  static Future<ParkingZone> createParkingZone(
    ParkingZoneCreateRequest request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.parkingZones),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, ParkingZone.fromJson);
    } catch (e) {
      log('Admin ApiService.createZone error: $e');
      _throwWithMessage(e, 'Greška pri kreiranju zone');
    }
  }

  static Future<ParkingZone> updateParkingZone({
    required int zoneId,
    required ParkingZoneUpdateRequest request,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.parkingZones}/$zoneId'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, ParkingZone.fromJson);
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

      await _handleObjectResponse(response);
    } catch (e) {
      log('Admin ApiService.deleteZone error: $e');
      _throwWithMessage(e, 'Greška pri brisanju zone');
    }
  }

  static Future<ParkingSpot> createParkingSpot(
    ParkingSpotCreateRequest request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppUrls.parkingSpots),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, ParkingSpot.fromJson);
    } catch (e) {
      log('Admin ApiService.addSpot error: $e');
      _throwWithMessage(e, 'Greška pri dodavanju spota');
    }
  }

  static Future<ParkingSpot> updateParkingSpot({
    required int spotId,
    required ParkingSpotUpdateRequest request,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.parkingSpots}/$spotId'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, ParkingSpot.fromJson);
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

      await _handleObjectResponse(response);
    } catch (e) {
      log('Admin ApiService.deleteSpot error: $e');
      _throwWithMessage(e, 'Greška pri brisanju mjesta');
    }
  }

  static Future<ParkingSpot> toggleParkingSpotActive({
    required int spotId,
    required bool isAvailable,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppUrls.parkingSpots}/$spotId'),
            headers: _getHeaders(),
            body: jsonEncode(
              ParkingSpotUpdateRequest(isAvailable: isAvailable).toJson(),
            ),
          )
          .timeout(_timeout);

      return await _handleModelResponse(response, ParkingSpot.fromJson);
    } catch (e) {
      log('Admin ApiService.toggleSpotActive error: $e');
      _throwWithMessage(e, 'Greška pri promjeni statusa spota');
    }
  }

  static Future<PagedResponse<Reservation>> searchReservations({
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
      return await _handlePagedResponse(response, Reservation.fromJson);
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
    int? userId,
  }) async {
    try {
      final response = await http
          .get(
            _buildUri('${AppUrls.reservations}/report/finance/pdf', {
              if (from != null) 'from': from.toIso8601String(),
              if (to != null) 'to': to.toIso8601String(),
              if (userId != null) 'userId': userId.toString(),
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

  static Future<Reservation> updateReservationStatus(
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

      return await _handleModelResponse(response, Reservation.fromJson);
    } catch (e) {
      log('Admin ApiService.updateReservationStatus error: $e');
      _throwWithMessage(e, 'Greška pri ažuriranju statusa');
    }
  }

  static Future<Reservation> checkInReservation(
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

      return await _handleModelResponse(response, Reservation.fromJson);
    } catch (e) {
      log('Admin ApiService.checkIn error: $e');
      _throwWithMessage(e, 'Greška pri check-in-u');
    }
  }

  static Future<Reservation> checkOutReservation(
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

      return await _handleModelResponse(response, Reservation.fromJson);
    } catch (e) {
      _throwWithMessage(e, 'Greška pri check-out-u');
    }
  }

  static Future<PagedResponse<AppNotification>> getNotifications({
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

      return await _handlePagedResponse(response, AppNotification.fromJson);
    } catch (e) {
      _throwWithMessage(e, 'Greška pri učitavanju notifikacija');
    }
  }

  static Future<void> sendNotification(NotificationSendRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppUrls.notifications}/send'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      await _handleObjectResponse(response);
    } catch (e) {
      _throwWithMessage(e, 'Greška pri slanju notifikacije');
    }
  }

  static Future<void> sendNotificationToAll(NotificationSendRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppUrls.notifications}/send-all'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      await _handleObjectResponse(response);
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

      await _handleObjectResponse(response);
    } catch (e) {
      _throwWithMessage(e, 'Greška pri označavanju notifikacije');
    }
  }
}
