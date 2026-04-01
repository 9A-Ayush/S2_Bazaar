import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Centralized registry for handling OS deep links (Android/iOS Intents).
class DeepLinkHandler {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;

  /// Initializes deep linking for cold starts and warm starts.
  static Future<void> init(ProviderContainer container) async {
    // 1. Cold Start (App launched freshly from a deep link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _processUri(initialUri, container);
      }
    } catch (e) {
      debugPrint('[DeepLinkHandler] Failed to get initial link: $e');
    }

    // 2. Warm Start (App was in background and brought to foreground via deep link)
    _sub = _appLinks.uriLinkStream.listen((Uri uri) async {
      await _processUri(uri, container);
    }, onError: (err) {
      debugPrint('[DeepLinkHandler] Error listening to uri stream: $err');
    });
  }

  static void dispose() {
    _sub?.cancel();
  }

  static Future<void> _processUri(Uri uri, ProviderContainer container) async {
    debugPrint('[DeepLinkHandler] Processing deep link: $uri');
    
    // Check if it's our login callback
    if (uri.host == 'login-callback') {
      try {
        final authService = container.read(authServiceProvider);
        await authService.handleDeepLinkCallback(uri);
      } catch (e) {
        debugPrint('[DeepLinkHandler] Error processing OAuth deep link: $e');
      }
    }
  }
}
