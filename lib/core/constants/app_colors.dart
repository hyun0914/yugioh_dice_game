import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color dark = Color(0xFF060410);
  static const Color dark2 = Color(0xFF0D0B1A);
  static const Color panel = Color(0xFF0F0D1E);
  static const Color card = Color(0xFF13102A);
  static const Color border = Color(0xFF1E1A38);

  // Gold
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFF0D080);
  static const Color goldDark = Color(0xFF7A6030);

  // Players
  static const Color p1 = Color(0xFF2A7FD4);
  static const Color p1g = Color(0xFF60C0FF);
  static const Color p1d = Color(0xFF1A4A7A);
  static const Color p2 = Color(0xFFC43030);
  static const Color p2g = Color(0xFFFF7070);
  static const Color p2d = Color(0xFF7A1A1A);

  // Text
  static const Color text = Color(0xFFDDD8C0);
  static const Color muted = Color(0xFF6A6458);

  // Status
  static const Color green = Color(0xFF44DD88);
  static const Color red = Color(0xFFFF5555);
  static const Color yellow = Color(0xFFFFCC44);

  // Crest colors
  static const Color crestMove = Color(0xFF7EF5A0);
  static const Color crestAtk = Color(0xFFFF8080);
  static const Color crestMagic = Color(0xFFC8A0FF);
  static const Color crestDef = Color(0xFF7EC8F5);
  static const Color crestTrap = Color(0xFFE8AA60);
  static const Color crestSummon = Color(0xFFF0D080);

  // Helper
  static Color p1Color(int player) => player == 1 ? p1 : p2;
  static Color p1gColor(int player) => player == 1 ? p1g : p2g;
}
