import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TitleScreen extends StatelessWidget {
  final VoidCallback onSelectDD;
  final VoidCallback onSelectDDM;

  const TitleScreen({
    super.key,
    required this.onSelectDD,
    required this.onSelectDDM,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Logo / Title
              Text(
                'YU-GI-OH',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                  letterSpacing: 6,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '유희왕\n다이스 게임',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  color: AppColors.goldLight,
                  letterSpacing: 4,
                  height: 1.2,
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Color(0x99C9A84C),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'DICE EDITION',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.goldDark,
                  letterSpacing: 8,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 240,
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, AppColors.gold, Colors.transparent],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '2인용 · 주사위 배틀',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),

              // Mode Cards
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    _ModeCard(
                      icon: '🎲',
                      title: 'DICE DUEL',
                      subtitle: 'DD MODE',
                      description: '양 플레이어가 몬스터를 선택하고 주사위를 굴려 ATK로 승패를 겨루는 간단한 카드 배틀!',
                      tags: const ['2인용', '주사위', '배틀'],
                      tagColors: const [AppColors.p1g, AppColors.gold, AppColors.p2g],
                      buttonLabel: 'DD 시작',
                      accentColor: AppColors.p1,
                      onTap: onSelectDD,
                    ),
                    _ModeCard(
                      icon: '♟',
                      title: 'DUNGEON DICE',
                      subtitle: 'DDM MODE',
                      description: '13×19 보드에 타일을 배치하고 몬스터를 소환해 상대 로드를 격파하는 전략 게임!',
                      tags: const ['전략', '타일', '소환'],
                      tagColors: const [AppColors.gold, AppColors.goldLight, AppColors.goldDark],
                      buttonLabel: 'DDM 시작',
                      accentColor: AppColors.goldDark,
                      onTap: onSelectDDM,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> tags;
  final List<Color> tagColors;
  final String buttonLabel;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tags,
    required this.tagColors,
    required this.buttonLabel,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 260,
        transform: _hovered
            ? (Matrix4.identity()..translateByDouble(0.0, -6.0, 0.0, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? AppColors.gold.withValues(alpha: 0.5)
                : AppColors.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top accent bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [widget.accentColor, widget.accentColor.withValues(alpha: 0.5)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.icon, style: const TextStyle(fontSize: 44)),
                  const SizedBox(height: 14),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 15,
                      letterSpacing: 2,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tags
                  Wrap(
                    spacing: 6,
                    children: List.generate(
                      widget.tags.length,
                      (i) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.tagColors[i % widget.tagColors.length]
                                .withValues(alpha: 0.4),
                          ),
                          color: widget.tagColors[i % widget.tagColors.length]
                              .withValues(alpha: 0.1),
                        ),
                        child: Text(
                          widget.tags[i],
                          style: TextStyle(
                            fontSize: 9,
                            color: widget.tagColors[i % widget.tagColors.length],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8888AA),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: widget.onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.accentColor == AppColors.p1
                            ? AppColors.p1g
                            : AppColors.goldLight,
                        side: BorderSide(color: widget.accentColor),
                        backgroundColor: widget.accentColor.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.buttonLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
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
