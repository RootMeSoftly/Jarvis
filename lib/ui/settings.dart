import 'package:flutter/material.dart';
import '../services/config.dart';
import '../services/tts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final c = Cfg.i;
  late final _groq = TextEditingController(text: c.groqKey);
  late final _gem = TextEditingController(text: c.geminiKey);
  bool _hide = true;

  @override
  void dispose() {
    _groq.dispose();
    _gem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voices = Tts.i.voicesFor(c.lang);
    final current = c.voiceFor(c.lang, c.gender);
    final value =
        voices.any((v) => v['name'] == current) ? current : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('API Keys (এনক্রিপ্টেড স্টোরেজে সেভ হবে)',
              style: TextStyle(color: Color(0xFF00E5FF))),
          const SizedBox(height: 8),
          TextField(
            controller: _groq,
            obscureText: _hide,
            decoration: InputDecoration(
              labelText: 'Groq API Key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gem,
            obscureText: _hide,
            decoration: const InputDecoration(
              labelText: 'Gemini API Key',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await c.setKeys(_groq.text, _gem.text);
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('সেভ হয়েছে ✔')));
            },
            child: const Text('Save Keys'),
          ),
          const Divider(height: 32),
          const Text('AI Brain'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'groq', label: Text('Groq Llama 3.3')),
              ButtonSegment(value: 'gemini', label: Text('Gemini 2.5 Flash')),
            ],
            selected: {c.provider},
            onSelectionChanged: (s) async {
              await c.setProvider(s.first);
              setState(() {});
            },
          ),
          const Divider(height: 32),
          const Text('ভাষা / Language'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'bn', label: Text('বাংলা')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {c.lang},
            onSelectionChanged: (s) async {
              await c.setLang(s.first);
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          const Text('Voice (Google TTS)'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'female', icon: Icon(Icons.female), label: Text('Female')),
              ButtonSegment(
                  value: 'male', icon: Icon(Icons.male), label: Text('Male')),
            ],
            selected: {c.gender},
            onSelectionChanged: (s) async {
              await c.setGender(s.first);
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          if (voices.isEmpty)
            const Text(
              'এই ভাষার কোনো Google voice পাওয়া যায়নি। Phone Settings → Text-to-speech → Google → Install voice data থেকে ভয়েস ডাউনলোড করুন। '
              'ততক্ষণ শুধু pitch দিয়ে Male/Female আলাদা হবে।',
              style: TextStyle(color: Colors.orangeAccent),
            )
          else
            DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                labelText:
                    'ভয়েস ভ্যারিয়েন্ট (${c.lang.toUpperCase()} / ${c.gender})',
                border: const OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('Auto')),
                ...voices.map((v) => DropdownMenuItem(
                    value: v['name'],
                    child: Text(v['name']!, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) async {
                await c.setVoice(c.lang, c.gender, v ?? '');
                setState(() {});
              },
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.volume_up),
            label: const Text('Test Voice'),
            onPressed: () => Tts.i.speak(c.lang == 'bn'
                ? 'আমি জার্ভিস। আপনার সেবায় প্রস্তুত।'
                : 'I am JARVIS. Ready to serve.'),
          ),
        ],
      ),
    );
  }
}
