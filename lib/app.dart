import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/title/title_screen.dart';
import 'features/dd/ui/dd_screen.dart';
import 'features/ddm/ui/ddm_screen.dart';

enum GameMode { title, dd, ddm }

class YugiohDiceApp extends StatefulWidget {
  const YugiohDiceApp({super.key});

  @override
  State<YugiohDiceApp> createState() => _YugiohDiceAppState();
}

class _YugiohDiceAppState extends State<YugiohDiceApp> {
  GameMode _mode = GameMode.title;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '유희왕 다이스 게임',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_mode) {
      case GameMode.title:
        return TitleScreen(
          onSelectDD: () => setState(() => _mode = GameMode.dd),
          onSelectDDM: () => setState(() => _mode = GameMode.ddm),
        );
      case GameMode.dd:
        return DdScreen(
          onBack: () => setState(() => _mode = GameMode.title),
        );
      case GameMode.ddm:
        return DdmScreen(
          onBack: () => setState(() => _mode = GameMode.title),
        );
    }
  }
}
