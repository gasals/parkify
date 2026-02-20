import 'package:mobile/constants/app_urls.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationService {
  static Future<void> startNavigation({
    required double destinationLat,
    required double destinationLng,
    required String destinationName,
  }) async {
    try {
      final String googleMapsUrl = AppUrls.navigation
          .replaceFirst('{lat}', destinationLat.toString())
          .replaceFirst('{lng}', destinationLng.toString());
      final Uri uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Greška: Ne mogu otvoriti Google Maps';
      }
    } catch (e) {
      throw Exception('Greška pri otvaranju navigacije: $e');
    }
  }
}
