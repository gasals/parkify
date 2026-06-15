import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _initialized = false;

  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    if (_initialized) return;
    _initialized = true;

    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink, navigatorKey);
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleLink(uri, navigatorKey),
      onError: (_) {},
    );
  }

  void _handleLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();

    final isPaymentCallback =
        path.contains('payment') || host.contains('payment');

    if (!isPaymentCallback) return;

    navigatorKey.currentState?.pushNamed('/my-reservations');
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}
