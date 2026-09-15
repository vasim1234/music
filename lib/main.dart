import 'package:flutter/material.dart';
import 'services/audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await initAudioService();
    debugPrint('✅ AudioService initialized');
  } catch (e) {
    debugPrint('❌ AudioService init error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bhai Bhai Music',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B1310),
      ),
      home: const MusicPlayerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
