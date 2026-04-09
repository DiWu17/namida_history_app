import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final Map<String, String> _config = {};
  late File _configFile;

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _configFile = File('${dir.path}${Platform.pathSeparator}config.ini');
    if (await _configFile.exists()) {
      await _load();
    }
  }

  Future<void> _load() async {
    final lines = await _configFile.readAsLines();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed.startsWith('[')) {
        continue;
      }
      final idx = trimmed.indexOf('=');
      if (idx > 0) {
        final key = trimmed.substring(0, idx).trim();
        final value = trimmed.substring(idx + 1).trim();
        _config[key] = value;
      }
    }
  }

  Future<void> _save() async {
    final buffer = StringBuffer();
    buffer.writeln('[Settings]');
    for (final entry in _config.entries) {
      buffer.writeln('${entry.key}=${entry.value}');
    }
    await _configFile.writeAsString(buffer.toString());
  }

  String? get(String key) => _config[key];

  int getInt(String key, int defaultValue) {
    final val = _config[key];
    if (val == null) return defaultValue;
    return int.tryParse(val) ?? defaultValue;
  }

  Future<void> set(String key, String value) async {
    _config[key] = value;
    await _save();
  }

  Future<void> remove(String key) async {
    _config.remove(key);
    await _save();
  }
}
