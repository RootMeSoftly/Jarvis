import 'package:flutter/material.dart';
import '../services/config.dart';
import '../services/llm.dart';
import '../services/tts.dart';
import 'orb.dart';
import 'settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ctl = TextEditingController();
  final List<Msg> _msgs = [];
  OrbState _state = OrbState.idle;
  bool _busy = false;
  String _err = '';

  @override
  void initState() {
    super.initState();
    Cfg.i.addListener(_refresh);
    Tts.i.onStart = () {
      if (mounted) setState(() => _state = OrbState.speaking);
    };
    Tts.i.onDone = () {
      if (mounted) setState(() => _state = OrbState.idle);
    };
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Cfg.i.removeListener(_refresh);
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _ctl.text.trim();
    if (t.isEmpty || _busy) return;
    _ctl.clear();
    FocusScope.of(context).unfocus();
    await Tts.i.stop();
    setState(() {
      _msgs.add(Msg('user', t));
      _state = OrbState.thinking;
      _busy = true;
      _err = '';
    });
    try {
      // Light memory: only last 9 messages go to the LLM (starts with 'user')
      final h = _msgs.length > 9 ? _msgs.sublist(_msgs.length - 9) : _msgs;
      final r = await Llm.ask(List.of(h));
      if (!mounted) return;
      setState(() => _msgs.add(Msg('assistant', r)));
      await Tts.i.speak(r);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _msgs.removeLast();
        _err = e.toString();
        _state = OrbState.idle;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Cfg.i;
    const cyan = Color(0xFF00E5FF);
    return Scaffold(
      appBar: AppBar(
        title: const Text('J.A.R.V.I.S',
            style: TextStyle(letterSpacing: 4, color: cyan)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings, color: cyan),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text(c.lang == 'bn' ? 'বাংলা' : 'English'),
                  selected: true,
                  onSelected: (_) async {
                    await Tts.i.stop();
                    await c.setLang(c.lang == 'bn' ? 'en' : 'bn');
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  avatar: Icon(c.gender == 'male' ? Icons.male : Icons.female,
                      size: 18),
                  label: Text(c.gender == 'male' ? 'Male' : 'Female'),
                  selected: true,
                  onSelected: (_) =>
                      c.setGender(c.gender == 'male' ? 'female' : 'male'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Tts.i.stop(),
              child: JarvisOrb(state: _state),
            ),
            if (_err.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_err,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _msgs.length,
                itemBuilder: (_, i) {
                  final m = _msgs[_msgs.length - 1 - i];
                  final me = m.role == 'user';
                  return Align(
                    alignment:
                        me ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * .8),
                      decoration: BoxDecoration(
                        color: me
                            ? const Color(0x332979FF)
                            : const Color(0x3300E5FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x5500E5FF)),
                      ),
                      child: Text(m.text),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Mic (Phase 2)',
                    icon: const Icon(Icons.mic_off, color: Colors.white38),
                    onPressed: () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                            content: Text('মাইক Phase 2 তে আসবে'))),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctl,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: c.lang == 'bn'
                            ? 'জার্ভিসকে কিছু লিখুন...'
                            : 'Type to JARVIS...',
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: cyan),
                    onPressed: _busy ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
