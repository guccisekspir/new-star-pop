import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/start_screen.dart';
import 'ui/stage_theme.dart';

/// New Star Pop — tererpop.com
/// New Star Soccer'ın TR Pop girl band / boy band üye kariyeri versiyonu.
void main() {
  runApp(const ProviderScope(child: NewStarPopApp()));
}

class NewStarPopApp extends StatelessWidget {
  const NewStarPopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Star Pop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: StageTheme.bgDeep,
        colorSchemeSeed: StageTheme.neonPink,
      ),
      home: const StartScreen(),
    );
  }
}
