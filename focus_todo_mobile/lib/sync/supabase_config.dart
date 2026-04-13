import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String? url;
  final String? anonKey;
}

String? _normalizeConfigValue(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

const String _rawSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);
const String _rawSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);

final String? SUPABASE_URL = _normalizeConfigValue(_rawSupabaseUrl);
final String? SUPABASE_ANON_KEY = _normalizeConfigValue(_rawSupabaseAnonKey);
bool _supabaseInitialized = false;

SupabaseConfig getSupabaseConfig() {
  return SupabaseConfig(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);
}

bool hasSupabaseConfig([SupabaseConfig? config]) {
  final resolved = config ?? getSupabaseConfig();
  return resolved.url != null && resolved.anonKey != null;
}

bool isSupabaseInitialized() => _supabaseInitialized;

Future<void> initializeSupabaseIfConfigured([SupabaseConfig? config]) async {
  final resolved = config ?? getSupabaseConfig();
  if (_supabaseInitialized || !hasSupabaseConfig(resolved)) {
    return;
  }

  await Supabase.initialize(url: resolved.url!, anonKey: resolved.anonKey!);
  _supabaseInitialized = true;
}
