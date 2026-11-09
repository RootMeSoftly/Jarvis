import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'config.dart';

/// Native Android Google TTS engine only. Free & unlimited.
class Tts {
  static final Tts i = Tts._();
  Tts._();

  final FlutterTts _t = FlutterTts();
  List<Map<String, String>> voices = [];
  VoidCallback? onStart;
  VoidCallback? onDone;

  Future<void> init() async {
    try {
      await _t.setEngine('com.google.android.tts');
    } catch (_) {}
    await _t.setSpeechRate(0.5);
    await _t.setVolume(1.0);
    _t.setStartHandler(() => onStart?.call());
    _t.setCompletionHandler(() => onDone?.call());
    _t.setCancelHandler(() => onDone?.call());
    _t.setErrorHandler((_) => onDone?.call());
    await refreshVoices();
  }

  Future<void> refreshVoices() async {
    try {
      final raw = await _t.getVoices as List;
      voices = raw
          .map((e) => (e as Map)
              .map((k, v) => MapEntry(k.toString(), v.toString())))
          .toList();
    } catch (_) {
      voices = [];
    }
  }

  /// All installed Google voices for a language, sorted by name.
  List<Map<String, String>> voicesFor(String lang) {
    final list = voices.where((v) {
      final loc = (v['locale'] ?? '').toLowerCase().replaceAll('_', '-');
      return lang == 'bn' ? loc.startsWith('bn') : loc.startsWith('en-us');
    }).toList();
    list.sort((a, b) => a['name']!.compareTo(b['name']!));
    return list;
  }

  String _clean(String s) =>
      s.replaceAll(RegExp(r'[*#_`>~]'), '').replaceAll('\n', ' ');

  Future<void> speak(String text) async {
    final c = Cfg.i;
    final bn = c.lang == 'bn';
    await _t.setLanguage(bn ? 'bn-BD' : 'en-US');

    final list = voicesFor(c.lang);
    Map<String, String>? v;
    final chosen = c.voiceFor(c.lang, c.gender);
    if (chosen.isNotEmpty) {
      for (final e in list) {
        if (e['name'] == chosen) v = e;
      }
    }
    // Auto: 1st variant = female, 2nd variant = male (if it exists)
    if (v == null && list.isNotEmpty) {
      v = list[(c.gender == 'male' && list.length > 1) ? 1 : 0];
    }
    if (v != null) {
      await _t.setVoice({'name': v['name']!, 'locale': v['locale']!});
    }
    // Pitch fallback so male/female always sounds different
    await _t.setPitch(c.gender == 'male' ? 0.75 : 1.05);
    await _t.speak(_clean(text));
  }

  Future<void> stop() => _t.stop();
}
