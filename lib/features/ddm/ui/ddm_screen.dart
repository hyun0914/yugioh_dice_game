import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/models/ddm_models.dart';
import '../../../core/services/sfx_service.dart';
import '../bloc/ddm_bloc.dart';
import '../bloc/ddm_event.dart';

// ═══════════════════════════════════════════
// DDM 화면 루트
// ═══════════════════════════════════════════
class DdmScreen extends StatelessWidget {
  final VoidCallback onBack;
  const DdmScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DdmBloc(),
      child: _DdmScreenBody(onBack: onBack),
    );
  }
}

class _DdmScreenBody extends StatefulWidget {
  final VoidCallback onBack;
  const _DdmScreenBody({required this.onBack});

  @override
  State<_DdmScreenBody> createState() => _DdmScreenBodyState();
}

class _DdmScreenBodyState extends State<_DdmScreenBody> {
  DdmGameState? _prev;

  void _handleSfx(DdmGameState curr) {
    final prev = _prev;
    _prev = curr;
    if (prev == null) return;

    final sfx = SfxService.instance;

    // 주사위 굴리기 시작
    if (!prev.rolled && curr.rolled) sfx.playDiceRoll();

    // 몬스터 소환
    if (curr.monsters.length > prev.monsters.length) sfx.playSummon();

    // 전투 팝업 등장
    if (prev.pendingBattle == null && curr.pendingBattle != null) {
      sfx.playBattle();
    }

    // 게임 승리
    if (!prev.gameOver && curr.gameOver) sfx.playWin();

    // 로그 기반 효과음 (이동/피해/트랩/마법)
    if (curr.log.length > prev.log.length) {
      for (final entry in curr.log.sublist(prev.log.length)) {
        if (entry.startsWith('🚶')) sfx.playMove();
        if (entry.startsWith('💥')) sfx.playDamage();
        if (entry.contains('트랩')) sfx.playTrap();
        if (entry.startsWith('✨') || entry.contains('마법')) sfx.playMagic();
        if (entry.startsWith('🎲')) sfx.playResult(1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DdmBloc, DdmGameState>(
      listener: (context, state) => _handleSfx(state),
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.dark,
          body: Stack(
            children: [
              _GameLayout(onBack: widget.onBack, state: state),
              if (state.screenMode == DdmScreenMode.modeSelect)
                _ModeSelectOverlay(),
              if (state.screenMode == DdmScreenMode.coinFlip)
                _CoinFlipOverlay(state: state),
              if (state.summonPanelOpen)
                _SummonPanelOverlay(state: state),
              if (state.pendingBattle != null)
                _BattlePopup(
                  battle: state.pendingBattle!,
                  isCpuTurn: state.isCpuMode && state.turn == 2,
                ),
              if (state.cpuThinking && state.pendingBattle == null)
                _CpuThinkingOverlay(),
              if (state.gameOver && state.winner != null)
                _GameOverOverlay(winner: state.winner!),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// 메인 게임 레이아웃
// ═══════════════════════════════════════════
class _GameLayout extends StatelessWidget {
  final VoidCallback onBack;
  final DdmGameState state;
  const _GameLayout({required this.onBack, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(onBack: onBack, state: state),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlayerPanel(player: 1, state: state),
              Expanded(child: _BoardArea(state: state)),
              _PlayerPanel(player: 2, state: state),
            ],
          ),
        ),
        _ActionBar(state: state),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 상단 헤더
// ═══════════════════════════════════════════
class _TopBar extends StatefulWidget {
  final VoidCallback onBack;
  final DdmGameState state;
  const _TopBar({required this.onBack, required this.state});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  bool _muted = false;

  @override
  Widget build(BuildContext context) {
    final turn = widget.state.turn;
    final pColor = turn == 1 ? AppColors.p1g : AppColors.p2g;
    return Container(
      height: 44,
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          TextButton(
            onPressed: widget.onBack,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
            ),
            child: const Text('← 타이틀',
                style: TextStyle(color: AppColors.muted, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Text('♟ DDM',
              style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: pColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                _topBarStatusText(widget.state, turn, pColor),
                style: TextStyle(
                    color: pColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 음소거 버튼
          GestureDetector(
            onTap: () {
              setState(() => _muted = !_muted);
              SfxService.instance.enabled = !_muted;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                _muted ? '🔇' : '🔊',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _LordHpRow(state: widget.state),
        ],
      ),
    );
  }
}

String _topBarStatusText(DdmGameState state, int turn, Color _) {
  if (state.phase == DdmPhase.select) {
    return 'P$turn 턴 — 주사위 ${state.selectedDice.length}/3 선택';
  }
  final sel = state.selectedMonster;
  if (sel != null) {
    final hl = state.highlights;
    final parts = <String>[];
    if (hl.move.isNotEmpty) parts.add('🚶${hl.move.length}칸');
    if (hl.attack.isNotEmpty) parts.add('⚔공격');
    final hint = parts.isEmpty ? '행동 완료' : parts.join(' ');
    return '${sel.emoji} ${sel.name} — $hint';
  }
  final t = turn - 1;
  final c = state.crests[t];
  final parts = <String>[];
  if (c.move > 0) parts.add('🚶×${c.move}');
  if (c.atk > 0) parts.add('⚔×${c.atk}');
  if (c.magic >= 2) parts.add('✨힐가능');
  if (parts.isEmpty) return 'P$turn 액션 — 몬스터 클릭';
  return 'P$turn — ${parts.join(' ')}  몬스터 클릭';
}

class _LordHpRow extends StatelessWidget {
  final DdmGameState state;
  const _LordHpRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final l1 = state.lords[0];
    final l2 = state.lords[1];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LordHpChip(player: 1, lord: l1),
        const SizedBox(width: 6),
        _LordHpChip(player: 2, lord: l2),
      ],
    );
  }
}

class _LordHpChip extends StatelessWidget {
  final int player;
  final DdmLord lord;
  const _LordHpChip({required this.player, required this.lord});

  @override
  Widget build(BuildContext context) {
    final pColor = player == 1 ? AppColors.p1g : AppColors.p2g;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('P$player', style: TextStyle(color: pColor, fontSize: 10)),
        const SizedBox(width: 3),
        ...List.generate(
          lord.maxHp,
          (i) => Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < lord.hp ? pColor : AppColors.muted.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 보드 영역 (스크롤 + 줌)
// ═══════════════════════════════════════════
class _BoardArea extends StatefulWidget {
  final DdmGameState state;
  const _BoardArea({required this.state});

  @override
  State<_BoardArea> createState() => _BoardAreaState();
}

class _BoardAreaState extends State<_BoardArea>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.45, end: 1.0).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cellW = constraints.maxWidth / kDdmCols;
      final cellH = constraints.maxHeight / kDdmRows;
      final cellSize = cellW < cellH ? cellW : cellH;

      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: Center(
              child: SizedBox(
                width: cellSize * kDdmCols,
                height: cellSize * kDdmRows,
                child: _DdmBoard(
                  state: widget.state,
                  cellSize: cellSize,
                  pulseValue: _pulseAnim.value,
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

// ═══════════════════════════════════════════
// DDM 보드
// ═══════════════════════════════════════════
class _DdmBoard extends StatelessWidget {
  final DdmGameState state;
  final double cellSize;
  final double pulseValue;
  const _DdmBoard({
    required this.state,
    required this.cellSize,
    this.pulseValue = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(kDdmRows, (r) {
        return Row(
          children: List.generate(kDdmCols, (c) {
            return _BoardCell(
              r: r,
              c: c,
              state: state,
              size: cellSize,
              pulseValue: pulseValue,
            );
          }),
        );
      }),
    );
  }
}

class _BoardCell extends StatelessWidget {
  final int r, c;
  final DdmGameState state;
  final double size;
  final double pulseValue;
  const _BoardCell({
    required this.r,
    required this.c,
    required this.state,
    required this.size,
    this.pulseValue = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final cell = state.board[r][c];
    final monster = _findMonster(state.monsters, r, c);
    final isSelected = state.selectedMonster?.r == r &&
        state.selectedMonster?.c == c;
    final isMoveHL = state.highlights.move.any((h) => h.r == r && h.c == c);
    final isAtkHL = state.highlights.attack.any((h) => h.r == r && h.c == c);
    final isTrapHL =
        state.trapMode?.any((h) => h.r == r && h.c == c) ?? false;

    // 타일 배치 프리뷰
    final pt = state.placingTile;
    final isPreview = pt != null &&
        pt.previewCells.any((p) => p.r == r && p.c == c);
    final hasPreviewError = pt?.previewError != null;

    Color bgColor = AppColors.dark2;
    Color borderColor = AppColors.border.withValues(alpha: 0.4);
    String label = '';

    if (cell != null) {
      switch (cell.type) {
        case BoardCellType.lord:
          bgColor = cell.player == 1
              ? AppColors.p1.withValues(alpha: 0.5)
              : AppColors.p2.withValues(alpha: 0.5);
          borderColor = cell.player == 1 ? AppColors.p1g : AppColors.p2g;
          label = '👑';
        case BoardCellType.tile:
          bgColor = cell.player == 1
              ? AppColors.p1d.withValues(alpha: 0.7)
              : AppColors.p2d.withValues(alpha: 0.7);
          borderColor = cell.player == 1
              ? AppColors.p1.withValues(alpha: 0.6)
              : AppColors.p2.withValues(alpha: 0.6);
        case BoardCellType.summon:
          bgColor = cell.player == 1
              ? AppColors.p1.withValues(alpha: 0.4)
              : AppColors.p2.withValues(alpha: 0.4);
          borderColor = cell.player == 1 ? AppColors.p1g : AppColors.p2g;
      }
      // 트랩 표시
      if (cell.trap != null) {
        borderColor = AppColors.crestTrap;
        label = cell.trap!.owner == state.turn ? '🪤' : '❓';
      }
    }

    if (isPreview) {
      bgColor = hasPreviewError
          ? AppColors.red.withValues(alpha: 0.35)
          : AppColors.crestSummon.withValues(alpha: 0.3);
      borderColor = hasPreviewError ? AppColors.red : AppColors.crestSummon;
    }
    if (isMoveHL) {
      bgColor = AppColors.green.withValues(alpha: 0.2 + 0.2 * pulseValue);
      borderColor = AppColors.green.withValues(alpha: 0.5 + 0.5 * pulseValue);
    }
    if (isAtkHL) {
      bgColor = AppColors.red.withValues(alpha: 0.2 + 0.25 * pulseValue);
      borderColor = AppColors.red.withValues(alpha: 0.5 + 0.5 * pulseValue);
    }
    if (isTrapHL) {
      bgColor = AppColors.crestTrap.withValues(alpha: 0.35);
      borderColor = AppColors.crestTrap;
    }
    if (isSelected) {
      bgColor = AppColors.goldLight.withValues(alpha: 0.18);
      borderColor = AppColors.goldLight;
    }

    // 로드 셀 HP 표시용 lord HP
    final lordHp = (cell?.type == BoardCellType.lord)
        ? (cell!.player == 1
            ? state.lords[0].hp
            : state.lords[1].hp)
        : null;

    // 몬스터 표시
    Widget content;
    if (monster != null) {
      final hpRatio = monster.hp / monster.maxHp;
      final hpColor = hpRatio > 0.5
          ? AppColors.green
          : hpRatio > 0.25
              ? AppColors.yellow
              : AppColors.red;
      final isSelectedMon = isSelected;
      content = Stack(
        children: [
          Center(
            child: Text(
              monster.emoji,
              style: TextStyle(fontSize: size * 0.46),
            ),
          ),
          // 선택 표시: 밝은 테두리 내부 링
          if (isSelectedMon)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.goldLight.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          // HP 바
          Positioned(
            bottom: 0,
            left: 1,
            right: 1,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: hpColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // 행동 완료 표시
          if (monster.hasMoved && monster.hasAttacked)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                color: Colors.black54,
                child: Center(
                  child: Text('✓',
                      style: TextStyle(
                          color: AppColors.muted,
                          fontSize: size * 0.18)),
                ),
              ),
            ),
        ],
      );
    } else if (label.isNotEmpty) {
      // 로드 셀: HP 표시
      content = Stack(
        children: [
          Center(
            child: Text(label, style: TextStyle(fontSize: size * 0.44)),
          ),
          if (lordHp != null)
            Positioned(
              bottom: 1,
              left: 0,
              right: 0,
              child: Text(
                '❤️' * lordHp,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: size * 0.16),
              ),
            ),
        ],
      );
    } else if (isMoveHL) {
      // 이동 가능 칸: 점 마커
      content = Center(
        child: Container(
          width: size * 0.28,
          height: size * 0.28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.green.withValues(alpha: 0.7),
          ),
        ),
      );
    } else if (isAtkHL) {
      // 공격 가능 칸: X 마커
      content = Center(
        child: Text('⚔',
            style: TextStyle(
                fontSize: size * 0.36,
                color: AppColors.red.withValues(alpha: 0.9))),
      );
    } else {
      content = const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => context.read<DdmBloc>().add(DdmCellClickEvent(r, c)),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : (isMoveHL || isAtkHL) ? 1.0 : 0.5,
          ),
        ),
        child: content,
      ),
    );
  }

  DdmMonster? _findMonster(List<DdmMonster> monsters, int r, int c) {
    for (final m in monsters) {
      if (m.r == r && m.c == c) return m;
    }
    return null;
  }
}

// ═══════════════════════════════════════════
// 플레이어 패널 (좌: P1, 우: P2)
// ═══════════════════════════════════════════
class _PlayerPanel extends StatelessWidget {
  final int player;
  final DdmGameState state;
  const _PlayerPanel({required this.player, required this.state});

  @override
  Widget build(BuildContext context) {
    final t = player - 1;
    final pColor = player == 1 ? AppColors.p1 : AppColors.p2;
    final pColorG = player == 1 ? AppColors.p1g : AppColors.p2g;
    final isActive = state.turn == player &&
        state.screenMode == DdmScreenMode.playing;
    final pool = state.pools[t];
    final crests = state.crests[t];
    final myMonsters =
        state.monsters.where((m) => m.player == player).toList();

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border(
          right: player == 1
              ? BorderSide(color: AppColors.border, width: 1)
              : BorderSide.none,
          left: player == 2
              ? BorderSide(color: AppColors.border, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          // 플레이어 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            color: pColor.withValues(alpha: isActive ? 0.25 : 0.08),
            child: Column(
              children: [
                Text(
                  'P$player${state.isCpuMode && player == 2 ? ' 🤖' : ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? pColorG : AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isActive && state.phase == DdmPhase.action) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (crests.move > 0)
                        _MiniCrestBadge('🚶', crests.move, AppColors.crestMove),
                      if (crests.atk > 0) ...[
                        const SizedBox(width: 2),
                        _MiniCrestBadge('⚔', crests.atk, AppColors.crestAtk),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 크레스트 풀
                  _CrestsDisplay(crests: crests),
                  const SizedBox(height: 6),
                  // 주사위 풀
                  _DicePoolDisplay(
                    pool: pool,
                    player: player,
                    state: state,
                  ),
                  const SizedBox(height: 6),
                  // 필드 몬스터
                  if (myMonsters.isNotEmpty) ...[
                    Text('필드',
                        style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 9)),
                    ...myMonsters.map(
                      (m) => _FieldMonsterCard(
                        monster: m,
                        state: state,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCrestBadge extends StatelessWidget {
  final String emoji;
  final int count;
  final Color color;
  const _MiniCrestBadge(this.emoji, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.7),
      ),
      child: Text(
        '$emoji$count',
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CrestsDisplay extends StatelessWidget {
  final DdmCrests crests;
  const _CrestsDisplay({required this.crests});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('🚶', crests.move, AppColors.crestMove),
      ('⚔', crests.atk, AppColors.crestAtk),
      ('✨', crests.magic, AppColors.crestMagic),
      ('🛡', crests.def, AppColors.crestDef),
      ('🪤', crests.trap, AppColors.crestTrap),
    ];

    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: items
          .where((e) => e.$2 > 0)
          .map((e) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: e.$3.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                      color: e.$3.withValues(alpha: 0.5), width: 0.5),
                ),
                child: Text(
                  '${e.$1}${e.$2}',
                  style: TextStyle(
                      color: e.$3, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ))
          .toList(),
    );
  }
}

class _DicePoolDisplay extends StatelessWidget {
  final List<DdmDie> pool;
  final int player;
  final DdmGameState state;
  const _DicePoolDisplay({
    required this.pool,
    required this.player,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = state.turn == player &&
        state.phase == DdmPhase.select &&
        state.screenMode == DdmScreenMode.playing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('주사위',
            style: TextStyle(color: AppColors.muted, fontSize: 9)),
        const SizedBox(height: 3),
        Wrap(
          spacing: 2,
          runSpacing: 2,
          children: List.generate(pool.length, (i) {
            final die = pool[i];
            final isSelected = isActive && state.selectedDice.contains(i);
            final pColor = player == 1 ? AppColors.p1 : AppColors.p2;
            final pColorG =
                player == 1 ? AppColors.p1g : AppColors.p2g;

            Color bg, border;
            if (die.used) {
              bg = AppColors.dark2;
              border = AppColors.muted.withValues(alpha: 0.2);
            } else if (isSelected) {
              bg = AppColors.gold.withValues(alpha: 0.2);
              border = AppColors.gold;
            } else {
              bg = pColor.withValues(alpha: 0.15);
              border = pColor.withValues(alpha: 0.4);
            }

            return GestureDetector(
              onTap: isActive
                  ? () =>
                      context.read<DdmBloc>().add(DdmToggleDieEvent(i))
                  : null,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: border, width: 0.7),
                ),
                child: Center(
                  child: Text(
                    die.used ? '×' : '${die.level}',
                    style: TextStyle(
                      color: die.used
                          ? AppColors.muted.withValues(alpha: 0.3)
                          : isSelected
                              ? AppColors.gold
                              : pColorG,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FieldMonsterCard extends StatelessWidget {
  final DdmMonster monster;
  final DdmGameState state;
  const _FieldMonsterCard({required this.monster, required this.state});

  @override
  Widget build(BuildContext context) {
    final hpRatio = monster.hp / monster.maxHp;
    final hpColor = hpRatio > 0.5
        ? AppColors.green
        : hpRatio > 0.25
            ? AppColors.yellow
            : AppColors.red;
    final pColor = monster.player == 1 ? AppColors.p1 : AppColors.p2;
    final isSelected = state.selectedMonster?.uid == monster.uid;
    final t = state.turn - 1;
    final canMagic = monster.player == state.turn &&
        state.crests[t].magic >= 2;

    return GestureDetector(
      onTap: () =>
          context.read<DdmBloc>().add(DdmCellClickEvent(monster.r, monster.c)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: pColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? AppColors.goldLight
                : pColor.withValues(alpha: 0.35),
            width: 0.7,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(monster.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    monster.name,
                    style: TextStyle(
                        color: AppColors.text, fontSize: 7),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (monster.hasMoved)
                  Text('🚶', style: TextStyle(fontSize: 7, color: AppColors.muted)),
                if (monster.hasAttacked)
                  Text('⚔', style: TextStyle(fontSize: 7, color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: hpRatio,
                backgroundColor: AppColors.dark2,
                valueColor: AlwaysStoppedAnimation(hpColor),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HP ${monster.hp}',
                  style: TextStyle(color: hpColor, fontSize: 7),
                ),
                if (canMagic)
                  GestureDetector(
                    onTap: () => context
                        .read<DdmBloc>()
                        .add(DdmUseMagicEvent(monster.uid)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color:
                            AppColors.crestMagic.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                            color: AppColors.crestMagic.withValues(alpha: 0.5),
                            width: 0.5),
                      ),
                      child: const Text('✨',
                          style: TextStyle(fontSize: 7)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 하단 액션 바
// ═══════════════════════════════════════════
class _ActionBar extends StatelessWidget {
  final DdmGameState state;
  const _ActionBar({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.screenMode != DdmScreenMode.playing) {
      return const SizedBox(height: 4);
    }
    // CPU 턴 중에는 조작 비활성화
    if (state.isCpuMode && state.turn == 2) {
      return const SizedBox(height: 4);
    }
    final pt = state.placingTile;
    if (pt != null) return _PlacingTileBar(state: state, pt: pt);

    return Container(
      color: AppColors.panel,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.lastRolled.isNotEmpty) _RollResultRow(state: state),
          const SizedBox(height: 4),
          Row(
            children: [
              if (state.phase == DdmPhase.select) ...[
                _ActionBtn(
                  label:
                      '🎲 굴리기 (${state.selectedDice.length}/3)',
                  color: state.selectedDice.length == 3
                      ? AppColors.gold
                      : AppColors.muted,
                  enabled: state.selectedDice.length == 3,
                  onTap: () => context
                      .read<DdmBloc>()
                      .add(const DdmRollDiceEvent()),
                ),
              ] else ...[
                if (state.canSummonLevel != null)
                  _ActionBtn(
                    label: '★ 소환 Lv${state.canSummonLevel}',
                    color: AppColors.crestSummon,
                    onTap: () => context
                        .read<DdmBloc>()
                        .add(const DdmOpenSummonPanelEvent()),
                  ),
                const SizedBox(width: 4),
                _ActionBtn(
                  label: '🪤 트랩',
                  color: state.crests[state.turn - 1].trap > 0
                      ? AppColors.crestTrap
                      : AppColors.muted,
                  enabled: state.crests[state.turn - 1].trap > 0,
                  onTap: () => context
                      .read<DdmBloc>()
                      .add(const DdmStartTrapModeEvent()),
                ),
                if (state.trapMode != null) ...[
                  const SizedBox(width: 4),
                  _ActionBtn(
                    label: '✕ 취소',
                    color: AppColors.red,
                    onTap: () => context
                        .read<DdmBloc>()
                        .add(const DdmCancelTrapEvent()),
                  ),
                ],
                const Spacer(),
                _ActionBtn(
                  label: '턴 종료 →',
                  color: AppColors.green,
                  onTap: () => context
                      .read<DdmBloc>()
                      .add(const DdmEndTurnEvent()),
                ),
              ],
            ],
          ),
          // 로그 한 줄 미리보기
          if (state.log.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              state.log.last,
              style: TextStyle(color: AppColors.muted, fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _RollResultRow extends StatelessWidget {
  final DdmGameState state;
  const _RollResultRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = state.turn - 1;
    final crests = state.crests[t];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 주사위 결과 카드 3개
        Row(
          children: [
            ...state.lastRolled.map((r) {
              final color = _crestColor(r.crest);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _crestEmoji(r.crest),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _crestLabel(r.crest),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Lv${r.level}',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 6),
        // 누적 크레스트 현황
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.dark2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CrestTotal('🚶', crests.move, AppColors.crestMove),
              _CrestTotal('⚔', crests.atk, AppColors.crestAtk),
              _CrestTotal('✨', crests.magic, AppColors.crestMagic),
              _CrestTotal('🛡', crests.def, AppColors.crestDef),
              _CrestTotal('🪤', crests.trap, AppColors.crestTrap),
            ],
          ),
        ),
      ],
    );
  }

  Color _crestColor(String crest) => switch (crest) {
        'move' => AppColors.crestMove,
        'attack' => AppColors.crestAtk,
        'magic' => AppColors.crestMagic,
        'def' => AppColors.crestDef,
        'trap' => AppColors.crestTrap,
        _ => AppColors.crestSummon,
      };

  String _crestEmoji(String crest) => switch (crest) {
        'move' => '🚶',
        'attack' => '⚔',
        'magic' => '✨',
        'def' => '🛡',
        'trap' => '🪤',
        _ => '★',
      };

  String _crestLabel(String crest) => switch (crest) {
        'move' => '이동',
        'attack' => '공격',
        'magic' => '마법',
        'def' => '방어',
        'trap' => '트랩',
        _ => '소환',
      };
}

class _CrestTotal extends StatelessWidget {
  final String emoji;
  final int count;
  final Color color;
  const _CrestTotal(this.emoji, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: TextStyle(
            color: count > 0 ? color : AppColors.muted.withValues(alpha: 0.4),
            fontSize: 13,
            fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _PlacingTileBar extends StatelessWidget {
  final DdmGameState state;
  final PlacingTileState pt;
  const _PlacingTileBar({required this.state, required this.pt});

  @override
  Widget build(BuildContext context) {
    final hasError = pt.previewError != null;
    final hasAnchor = pt.previewAnchor != null;

    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(pt.monsterEmoji,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pt.monsterName,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      hasError
                          ? pt.previewError!
                          : hasAnchor
                              ? '✓ 배치 가능 — 확정 버튼 클릭'
                              : '보드에서 배치할 위치를 클릭하세요',
                      style: TextStyle(
                        color: hasError ? AppColors.red : AppColors.green,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // 회전 버튼
              _RotateBtn(dir: -1),
              const SizedBox(width: 4),
              Text(
                ['0°', '90°', '180°', '270°'][pt.rot],
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
              const SizedBox(width: 4),
              _RotateBtn(dir: 1),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _TileShapePreview(pt: pt),
              const Spacer(),
              _ActionBtn(
                label: '✕ 취소',
                color: AppColors.red,
                onTap: () => context
                    .read<DdmBloc>()
                    .add(const DdmCancelSummonEvent()),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: '✓ 배치 확정',
                color:
                    hasAnchor && !hasError ? AppColors.green : AppColors.muted,
                enabled: hasAnchor && !hasError,
                onTap: () => context
                    .read<DdmBloc>()
                    .add(const DdmConfirmPlaceTileEvent()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RotateBtn extends StatelessWidget {
  final int dir;
  const _RotateBtn({required this.dir});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.read<DdmBloc>().add(DdmRotateTileEvent(dir)),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.4), width: 0.7),
        ),
        child: Center(
          child: Text(
            dir == 1 ? '↻' : '↺',
            style: TextStyle(color: AppColors.gold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _TileShapePreview extends StatelessWidget {
  final PlacingTileState pt;
  const _TileShapePreview({required this.pt});

  @override
  Widget build(BuildContext context) {
    final rotated = rotateTile(pt.shape, pt.rot);
    if (rotated.isEmpty) return const SizedBox.shrink();

    final maxR = rotated.map((c) => c[0]).reduce((a, b) => a > b ? a : b);
    final maxC = rotated.map((c) => c[1]).reduce((a, b) => a > b ? a : b);
    const cellSz = 12.0;

    return SizedBox(
      width: (maxC + 1) * cellSz,
      height: (maxR + 1) * cellSz,
      child: Stack(
        children: rotated.map((cell) {
          return Positioned(
            top: cell[0] * cellSz,
            left: cell[1] * cellSz,
            child: Container(
              width: cellSz - 1,
              height: cellSz - 1,
              decoration: BoxDecoration(
                color: AppColors.crestSummon.withValues(alpha: 0.4),
                border: Border.all(
                    color: AppColors.crestSummon.withValues(alpha: 0.8),
                    width: 0.5),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;

  const _ActionBtn({
    required this.label,
    required this.color,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && onTap != null;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.15)
              : AppColors.dark2,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.6)
                : AppColors.muted.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : AppColors.muted.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 코인 플립 오버레이
// ═══════════════════════════════════════════
class _CoinFlipOverlay extends StatefulWidget {
  final DdmGameState state;
  const _CoinFlipOverlay({required this.state});

  @override
  State<_CoinFlipOverlay> createState() => _CoinFlipOverlayState();
}

class _CoinFlipOverlayState extends State<_CoinFlipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _fakeRoll1 = 1;
  int _fakeRoll2 = 6;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _fakeRoll1 = (DateTime.now().millisecondsSinceEpoch % 6) + 1;
            _fakeRoll2 = (DateTime.now().millisecondsSinceEpoch ~/ 7 % 6) + 1;
          });
        }
      });
  }

  @override
  void didUpdateWidget(_CoinFlipOverlay old) {
    super.didUpdateWidget(old);
    if (widget.state.coinFlipRolling) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final rolling = state.coinFlipRolling;
    final r1 = rolling ? _fakeRoll1 : (state.coinFlipRolls[0] ?? 1);
    final r2 = rolling ? _fakeRoll2 : (state.coinFlipRolls[1] ?? 1);

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '♟ DUNGEON DICE MONSTERS',
                style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text('선공 결정',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CoinDie(label: 'P1', value: r1, pColor: AppColors.p1g),
                  const SizedBox(width: 32),
                  _CoinDie(label: 'P2', value: r2, pColor: AppColors.p2g),
                ],
              ),
              const SizedBox(height: 20),
              if (state.coinFlipResult.isNotEmpty)
                Text(
                  state.coinFlipResult,
                  style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              if (!rolling)
                ElevatedButton(
                  onPressed: () =>
                      context.read<DdmBloc>().add(const DdmCoinRollEvent()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.dark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text('🎲 주사위 굴리기',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else
                Text('굴리는 중...',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinDie extends StatelessWidget {
  final String label;
  final int value;
  final Color pColor;
  const _CoinDie(
      {required this.label, required this.value, required this.pColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: pColor, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: pColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: pColor.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                  color: pColor, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 소환 패널 오버레이
// ═══════════════════════════════════════════
class _SummonPanelOverlay extends StatelessWidget {
  final DdmGameState state;
  const _SummonPanelOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    final level = state.canSummonLevel ?? 1;
    final pColor = state.turn == 1 ? AppColors.p1g : AppColors.p2g;

    // 태그 필터 (레벨별 소환 가능 몬스터: ts=any, td=dice only)
    final available = kMonsters.where((m) {
      if (level == 1) return m.tags.contains('ts');
      if (level == 2) return m.tags.contains('td') || m.tags.contains('ts');
      return true;
    }).toList();

    return GestureDetector(
      onTap: () => context.read<DdmBloc>().add(const DdmCancelSummonEvent()),
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 340,
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '★ Lv$level 몬스터 소환',
                        style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context
                            .read<DdmBloc>()
                            .add(const DdmCancelSummonEvent()),
                        child: Text('✕',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PLAYER ${state.turn} — 소환할 몬스터를 선택하세요',
                    style: TextStyle(color: pColor, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: available.length,
                      separatorBuilder: (context2, idx) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final m = available[i];
                        return GestureDetector(
                          onTap: () => context
                              .read<DdmBloc>()
                              .add(DdmSelectMonsterForSummonEvent(m.id)),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.panel,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      AppColors.border.withValues(alpha: 0.6),
                                  width: 0.7),
                            ),
                            child: Row(
                              children: [
                                Text(m.emoji,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            m.name,
                                            style: TextStyle(
                                                color: AppColors.text,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 6),
                                          if (m.flying)
                                            Text('비행',
                                                style: TextStyle(
                                                    color: AppColors.crestMove,
                                                    fontSize: 9)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ATK ${m.atk}  ${m.type}',
                                        style: TextStyle(
                                            color: AppColors.gold,
                                            fontSize: 10),
                                      ),
                                      Text(
                                        m.effect,
                                        style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 9),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 게임 오버 오버레이
// ═══════════════════════════════════════════
// ═══════════════════════════════════════════
// 모드 선택 오버레이
// ═══════════════════════════════════════════
class _ModeSelectOverlay extends StatelessWidget {
  const _ModeSelectOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '♟ DUNGEON DICE MONSTERS',
                style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                '게임 모드 선택',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _ModeBtn(
                emoji: '👥',
                title: '2P 대전',
                sub: '두 명이 번갈아 플레이',
                onTap: () => context
                    .read<DdmBloc>()
                    .add(const DdmSetModeEvent(false)),
              ),
              const SizedBox(height: 12),
              _ModeBtn(
                emoji: '🤖',
                title: 'CPU 대전',
                sub: 'P1 vs 컴퓨터 (P2)',
                onTap: () => context
                    .read<DdmBloc>()
                    .add(const DdmSetModeEvent(true)),
                highlight: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final bool highlight;

  const _ModeBtn({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.gold : AppColors.p1g;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(sub,
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// CPU 생각 중 오버레이
// ═══════════════════════════════════════════
class _CpuThinkingOverlay extends StatefulWidget {
  const _CpuThinkingOverlay();

  @override
  State<_CpuThinkingOverlay> createState() => _CpuThinkingOverlayState();
}

class _CpuThinkingOverlayState extends State<_CpuThinkingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _anim,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.p2g.withValues(alpha: 0.5), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🤖',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'CPU 생각 중...',
                  style: TextStyle(
                      color: AppColors.p2g,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 게임 오버 오버레이
// ═══════════════════════════════════════════
class _GameOverOverlay extends StatefulWidget {
  final int winner;
  const _GameOverOverlay({required this.winner});

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pColor = widget.winner == 1 ? AppColors.p1g : AppColors.p2g;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: pColor.withValues(alpha: 0.6), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🏆',
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PLAYER ${widget.winner} 승리!',
                    style: TextStyle(
                        color: pColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<DdmBloc>().add(const DdmRestartEvent()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pColor,
                      foregroundColor: AppColors.dark,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                    ),
                    child: const Text('다시 시작',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 전투 팝업 오버레이
// ═══════════════════════════════════════════
class _BattlePopup extends StatefulWidget {
  final DdmBattleResult battle;
  final bool isCpuTurn;
  const _BattlePopup({required this.battle, required this.isCpuTurn});

  @override
  State<_BattlePopup> createState() => _BattlePopupState();
}

class _BattlePopupState extends State<_BattlePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // 팝업 외부 클릭 차단
      child: Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.dark2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '⚔️ 전투!',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.battle.isLordAttack)
                    _LordAttackContent(battle: widget.battle)
                  else
                    _MonsterBattleContent(battle: widget.battle),
                  const SizedBox(height: 16),
                  if (!widget.isCpuTurn)
                    ElevatedButton(
                      onPressed: () => context
                          .read<DdmBloc>()
                          .add(const DdmConfirmBattleEvent()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.dark,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 10),
                      ),
                      child: const Text('확인',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  else
                    Text('처리 중...',
                        style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _LordAttackContent extends StatelessWidget {
  final DdmBattleResult battle;
  const _LordAttackContent({required this.battle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${battle.attackerEmoji} ${battle.attackerName}',
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '로드 직격 공격!',
          style: TextStyle(color: AppColors.crestAtk, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.crestAtk.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '❤️ 로드 HP -1',
            style: TextStyle(
                color: AppColors.crestAtk,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _MonsterBattleContent extends StatelessWidget {
  final DdmBattleResult battle;
  const _MonsterBattleContent({required this.battle});

  @override
  Widget build(BuildContext context) {
    final outcomeColor = battle.outcome == 'attacker_wins'
        ? AppColors.crestAtk
        : battle.outcome == 'defender_wins'
            ? AppColors.crestDef
            : AppColors.muted;
    final outcomeText = battle.outcome == 'attacker_wins'
        ? '공격자 승!'
        : battle.outcome == 'defender_wins'
            ? '방어자 승!'
            : '무승부';

    return Column(
      children: [
        // 공격자 vs 방어자 행
        Row(
          children: [
            Expanded(
              child: _BattleSide(
                emoji: battle.attackerEmoji,
                name: battle.attackerName,
                roll: battle.attackerRoll,
                finalAtk: battle.attackerFinalAtk,
                effect: battle.attackerEffect,
                isWinner: battle.outcome == 'attacker_wins',
                color: AppColors.crestAtk,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('VS',
                  style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            Expanded(
              child: _BattleSide(
                emoji: battle.defenderEmoji ?? '?',
                name: battle.defenderName ?? '?',
                roll: battle.defenderRoll ?? 0,
                finalAtk: battle.defenderFinalAtk ?? 0,
                effect: battle.defenderEffect,
                isWinner: battle.outcome == 'defender_wins',
                color: AppColors.crestDef,
              ),
            ),
          ],
        ),
        if (battle.usedDefCrest) ...[
          const SizedBox(height: 6),
          Text('🛡️ 방어 크레스트 발동!',
              style: TextStyle(color: AppColors.crestDef, fontSize: 11)),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: outcomeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: outcomeColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            outcomeText,
            style: TextStyle(
                color: outcomeColor,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _BattleSide extends StatelessWidget {
  final String emoji;
  final String name;
  final int roll;
  final int finalAtk;
  final String? effect;
  final bool isWinner;
  final Color color;
  const _BattleSide({
    required this.emoji,
    required this.name,
    required this.roll,
    required this.finalAtk,
    required this.effect,
    required this.isWinner,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isWinner
            ? color.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinner ? color : AppColors.border,
          width: isWinner ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 10),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '🎲 $roll',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          Text(
            'ATK $finalAtk',
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          if (effect != null) ...[
            const SizedBox(height: 2),
            Text(
              effect!,
              style: TextStyle(color: AppColors.gold, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
