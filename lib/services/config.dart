import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted local storage (Android Keystore + EncryptedSharedPreferences)
class Store {
  static const _s = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static Future<String> get(String k, [String d = '']) async {
    try {
      return (await _s.read(key: k)) ?? d;
    } catch (_) {
      return d;
    }
  }

  static Future<void> set(String k, String v) async {
    try {
      await _s.write(key: k, value: v);
    } catch (_) {}
  }
}

class Cfg extends ChangeNotifier {
  static final Cfg i = Cfg._();
  Cfg._();

  String lang = 'bn'; // bn | en
  String gender = 'female'; // female | male
  String provider = 'groq'; // groq | gemini
  String groqKey = '';
  String geminiKey = '';
  final Map<String, String> _voice = {};

  Future<void> load() async {
    lang = await Store.get('lang', 'bn');
    gender = await Store.get('gender', 'female');
    provider = await Store.get('provider', 'groq');
    groqKey = await Store.get('groqKey');
    geminiKey = await Store.get('geminiKey');
    for (final l in ['bn', 'en']) {
      for (final g in ['male', 'female']) {
        _voice['voice_${l}_$g'] = await Store.get('voice_${l}_$g');
      }
    }
  }

  String voiceFor(String l, String g) => _voice['voice_${l}_$g'] ?? '';

  Future<void> setVoice(String l, String g, String name) async {
    _voice['voice_${l}_$g'] = name;
    await Store.set('voice_${l}_$g', name);
    notifyListeners();
  }

  Future<void> setLang(String v) async {
    lang = v;
    await Store.set('lang', v);
    notifyListeners();
  }

  Future<void> setGender(String v) async {
    gender = v;
    await Store.set('gender', v);
    notifyListeners();
  }

  Future<void> setProvider(String v) async {
    provider = v;
    await Store.set('provider', v);
    notifyListeners();
  }

  Future<void> setKeys(String groq, String gemini) async {
    groqKey = groq.trim();
    geminiKey = gemini.trim();
    await Store.set('groqKey', groqKey);
    await Store.set('geminiKey', geminiKey);
    notifyListeners();
  }
}
