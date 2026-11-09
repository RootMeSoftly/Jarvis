import 'package:flutter/material.dart';
import 'services/config.dart';
import 'services/tts.dart';
import 'ui/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Cfg.i.load();
  await Tts.i.init();
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J.A.R.V.I.S',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030B14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF2979FF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF030B14),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
