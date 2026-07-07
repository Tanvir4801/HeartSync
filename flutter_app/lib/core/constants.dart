import 'package:flutter/foundation.dart' show kIsWeb;

/// Derive the backend URL at runtime so it works in Replit dev preview
/// (where Flutter runs on port 8080 and the API on port 3001, same hostname).
String get kBackendUrl {
  if (kIsWeb) {
    try {
      final uri = Uri.base;
      // Strip any port already embedded in the host string
      final host = uri.host.contains(':') ? uri.host.split(':').first : uri.host;
      return 'https://$host:3001';
    } catch (_) {}
  }
  return 'http://localhost:3001';
}
