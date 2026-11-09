import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class Msg {
  final String role; // user | assistant
  final String text;
  Msg(this.role, this.text);
}

class Llm {
  static String _system(String lang) => lang == 'bn'
      ? 'তুমি জার্ভিস, আমার ব্যক্তিগত ভয়েস অ্যাসিস্ট্যান্ট। সবসময় বাংলাদেশী বাংলায় উত্তর দাও। '
          'উত্তর খুব ছোট রাখো (১-৩ বাক্য)। মার্কডাউন, তারকাচিহ্ন বা ইমোজি ব্যবহার করবে না, '
          'কারণ উত্তরটি জোরে পড়ে শোনানো হবে।'
      : 'You are JARVIS, my personal voice assistant. Reply in English. '
          'Keep answers very short (1-3 sentences). Do not use markdown, asterisks or emojis, '
          'because your reply will be read aloud.';

  /// history must start with a user message and end with a user message.
  static Future<String> ask(List<Msg> history) async {
    final c = Cfg.i;
    final sys = _system(c.lang);
    if (c.provider == 'groq') return _groq(history, sys, c.groqKey);
    return _gemini(history, sys, c.geminiKey);
  }

  static Future<String> _groq(List<Msg> h, String sys, String key) async {
    if (key.isEmpty) throw 'Groq API key নেই। Settings এ গিয়ে দিন।';
    final res = await http
        .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode({
            'model': 'llama-3.3-70b-versatile',
            'temperature': 0.6,
            'max_tokens': 300,
            'messages': [
              {'role': 'system', 'content': sys},
              ...h.map((m) => {'role': m.role, 'content': m.text}),
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) throw 'Groq error ${res.statusCode}: $body';
    return (jsonDecode(body)['choices'][0]['message']['content'] as String)
        .trim();
  }

  static Future<String> _gemini(List<Msg> h, String sys, String key) async {
    if (key.isEmpty) throw 'Gemini API key নেই। Settings এ গিয়ে দিন।';
    final res = await http
        .post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent'),
          headers: {
            'x-goog-api-key': key,
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': sys}
              ]
            },
            'contents': h
                .map((m) => {
                      'role': m.role == 'user' ? 'user' : 'model',
                      'parts': [
                        {'text': m.text}
                      ]
                    })
                .toList(),
            'generationConfig': {'maxOutputTokens': 400, 'temperature': 0.6},
          }),
        )
        .timeout(const Duration(seconds: 30));
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) throw 'Gemini error ${res.statusCode}: $body';
    return (jsonDecode(body)['candidates'][0]['content']['parts'][0]['text']
            as String)
        .trim();
  }
}
