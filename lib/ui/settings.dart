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
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('সেভ হয়েছে ✔'),
                duration: Duration(seconds: 1),
              ));
            },
            child: const Text('Save Keys'),
          ),
          const Divider(height: 32),
          const Text('AI Brain'),
          const SizedBox(height: 8),
          SegmentedButton
