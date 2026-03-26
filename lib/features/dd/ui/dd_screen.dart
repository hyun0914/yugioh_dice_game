import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/models/dd_game_state.dart';
import '../../../core/models/monster_model.dart';
import '../../../core/services/sfx_service.dart';
import '../bloc/dd_bloc.dart';
import '../bloc/dd_event.dart';

class DdScreen extends StatelessWidget {
  final VoidCallback onBack;
  const DdScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DdBloc()..add(const DdInitEvent()),
      child: _DdScreenBody(onBack: onBack),
    );
  }
}

class _DdScreenBody extends StatefulWidget {
  final VoidCallback onBack;
  const _DdScreenBody({required this.onBack});

  @override
  State<_DdScreenBody> createState() => _DdScreenBodyState();
}

class _DdScreenBodyState extends State<_DdScreenBody> {
  DdGameState? _prev;
  bool _muted = false;

  void _handleSfx(DdGameState curr) {
    final prev = _prev;
    _prev = curr;
    if (prev == null) return;

    final sfx = SfxService.instance;

    // 코인플립/주사위 굴리기
    if (!prev.coinFlipRolling && curr.coinFlipRolling) sfx.playDiceRoll();
    if (!prev.rolling && curr.rolling) sfx.playDiceRoll();

    // 전투 결과 화면 진입
    if (prev.phase != DdPhase.result && curr.phase == DdPhase.result) {
      sfx.playBattle();
    }

    // LP 감소 (피해)
    if (curr.lp[0] < prev.lp[0] || curr.lp[1] < prev.lp[1]) {
      sfx.playDamage();
    }

    // 게임 종료
    if (!prev.gameOver && curr.gameOver) sfx.playWin();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DdBloc, DdGameState>(
      listener: (context, state) => _handleSfx(state),
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.dark,
          appBar: AppBar(
            backgroundColor: Colors.black54,
            title: Text(
              '⚔ DICE DUEL  •  ROUND ${state.round}',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                letterSpacing: 2,
              ),
            ),
            leading: TextButton(
              onPressed: widget.onBack,
              child: const Text(
                '← 타이틀',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ),
            leadingWidth: 70,
            actions: [
              GestureDetector(
                onTap: () {
                  setState(() => _muted = !_muted);
                  SfxService.instance.enabled = !_muted;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _muted ? '🔇' : '🔊',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // 메인 플레이 화면 (항상 렌더)
              _PlayArea(state: state),
              // 모드 선택 오버레이
              if (state.screenMode == DdScreenMode.modeSelect)
                const _DdModeSelectOverlay(),
              // 코인플립 오버레이
              if (state.screenMode == DdScreenMode.coinFlip)
                _CoinFlipOverlay(state: state),
              // 핸드오프 오버레이
              if (state.screenMode == DdScreenMode.handoff)
                _HandoffOverlay(state: state),
              // 게임 종료 오버레이
              if (state.gameOver) _WinOverlay(state: state),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// 모드 선택 오버레이
// ═══════════════════════════════════════════
class _DdModeSelectOverlay extends StatelessWidget {
  const _DdModeSelectOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.dark.withValues(alpha: 0.97),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚔', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              'DICE DUEL',
              style: TextStyle(
                color: AppColors.goldLight,
                fontSize: 28,
                letterSpacing: 4,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '게임 모드를 선택하세요',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () =>
                    context.read<DdBloc>().add(const DdSetModeEvent(false)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.p1.withValues(alpha: 0.15),
                  foregroundColor: AppColors.p1g,
                  side: const BorderSide(color: AppColors.p1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  '👥 2인 대전',
                  style: TextStyle(fontSize: 14, letterSpacing: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () =>
                    context.read<DdBloc>().add(const DdSetModeEvent(true)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.p2.withValues(alpha: 0.15),
                  foregroundColor: AppColors.p2g,
                  side: const BorderSide(color: AppColors.p2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  '🤖 vs CPU',
                  style: TextStyle(fontSize: 14, letterSpacing: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 코인플립 오버레이
// ═══════════════════════════════════════════
class _CoinFlipOverlay extends StatefulWidget {
  final DdGameState state;
  const _CoinFlipOverlay({required this.state});

  @override
  State<_CoinFlipOverlay> createState() => _CoinFlipOverlayState();
}

class _CoinFlipOverlayState extends State<_CoinFlipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rand = Random();
  int _animP1 = 1, _animP2 = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..addListener(() {
        if (widget.state.coinFlipRolling) {
          setState(() {
            _animP1 = _rand.nextInt(6) + 1;
            _animP2 = _rand.nextInt(6) + 1;
          });
        }
      });
  }

  @override
  void didUpdateWidget(_CoinFlipOverlay old) {
    super.didUpdateWidget(old);
    if (widget.state.coinFlipRolling && !old.state.coinFlipRolling) {
      _ctrl.repeat();
    } else if (!widget.state.coinFlipRolling && old.state.coinFlipRolling) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final p1Display = s.coinFlipRolling
        ? '$_animP1'
        : (s.coinFlipRolls[0]?.toString() ?? '—');
    final p2Display = s.coinFlipRolling
        ? '$_animP2'
        : (s.coinFlipRolls[1]?.toString() ?? '—');

    Color p1Color = AppColors.text;
    Color p2Color = AppColors.text;
    if (!s.coinFlipRolling && s.coinFlipRolls[0] != null) {
      if (s.coinFlipRolls[0]! > s.coinFlipRolls[1]!) {
        p1Color = AppColors.green;
        p2Color = AppColors.muted;
      } else if (s.coinFlipRolls[1]! > s.coinFlipRolls[0]!) {
        p1Color = AppColors.muted;
        p2Color = AppColors.green;
      }
    }

    return Container(
      color: AppColors.dark.withValues(alpha: 0.97),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎲', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              '선공 결정!',
              style: TextStyle(
                color: AppColors.goldLight,
                fontSize: 26,
                letterSpacing: 3,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '높은 수가 나온 플레이어가 선공합니다',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CoinRollSlot(label: 'PLAYER 1', value: p1Display,
                    color: p1Color, playerColor: AppColors.p1g),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('VS', style: TextStyle(color: AppColors.muted, fontSize: 18)),
                ),
                _CoinRollSlot(label: 'PLAYER 2', value: p2Display,
                    color: p2Color, playerColor: AppColors.p2g),
              ],
            ),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 28,
              child: Text(
                s.coinFlipResult,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: s.coinFlipRolling
                  ? null
                  : () => context.read<DdBloc>().add(const DdCoinRollEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.panel,
                foregroundColor: AppColors.goldLight,
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                s.coinFlipRolling ? '굴리는 중...' : '🎲 주사위 굴리기!',
                style: const TextStyle(fontSize: 14, letterSpacing: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinRollSlot extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color playerColor;
  const _CoinRollSlot({
    required this.label,
    required this.value,
    required this.color,
    required this.playerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: playerColor, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 100),
          style: TextStyle(
            color: color,
            fontSize: 52,
            fontWeight: FontWeight.bold,
          ),
          child: Text(value),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 핸드오프 오버레이
// ═══════════════════════════════════════════
class _HandoffOverlay extends StatelessWidget {
  final DdGameState state;
  const _HandoffOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.dark.withValues(alpha: 0.97),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.turn == 1 ? '🔵' : '🔴',
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 20),
              Text(
                state.handoffTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 22,
                  letterSpacing: 3,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                state.handoffSub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () =>
                    context.read<DdBloc>().add(const DdHandoffConfirmEvent()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.turn == 1
                      ? AppColors.p1.withValues(alpha: 0.2)
                      : AppColors.p2.withValues(alpha: 0.2),
                  foregroundColor:
                      state.turn == 1 ? AppColors.p1g : AppColors.p2g,
                  side: BorderSide(
                      color: state.turn == 1 ? AppColors.p1 : AppColors.p2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'PLAYER ${state.turn} 준비 완료 →',
                  style: const TextStyle(fontSize: 13, letterSpacing: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 플레이 영역
// ═══════════════════════════════════════════
class _PlayArea extends StatelessWidget {
  final DdGameState state;
  const _PlayArea({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 페이즈 바
          _PhaseBar(phase: state.phase, firstTurn: state.firstTurn),
          const SizedBox(height: 10),

          // 현재 턴 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: (state.turn == 1 ? AppColors.p1 : AppColors.p2)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: (state.turn == 1 ? AppColors.p1 : AppColors.p2)
                      .withValues(alpha: 0.3)),
            ),
            child: Text(
              'PLAYER ${state.turn} 턴',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: state.turn == 1 ? AppColors.p1g : AppColors.p2g,
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // LP 패널
          Row(
            children: [
              Expanded(child: _LpPanel(player: 1, state: state)),
              const SizedBox(width: 8),
              Expanded(child: _LpPanel(player: 2, state: state)),
            ],
          ),
          const SizedBox(height: 12),

          // 내 몬스터 패널
          _MyMonsterPanel(state: state),
          const SizedBox(height: 12),

          // 주사위 영역
          _DiceArena(state: state),
          const SizedBox(height: 12),

          // 액션 버튼
          _ActionButtons(state: state),
          const SizedBox(height: 12),

          // 상대방 패널 (요약)
          _OppPanel(state: state),
          const SizedBox(height: 12),

          // 게임 로그
          _LogPanel(state: state),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 페이즈 바
// ═══════════════════════════════════════════
class _PhaseBar extends StatelessWidget {
  final DdPhase phase;
  final bool firstTurn;
  const _PhaseBar({required this.phase, required this.firstTurn});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (DdPhase.set, '🃏 SET', firstTurn ? '첫 턴' : 'SET'),
      (DdPhase.battle, '⚔️ BATTLE', 'BATTLE'),
      (DdPhase.result, '📋 RESULT', 'RESULT'),
      (DdPhase.preset, '🃏 NEXT', 'NEXT'),
    ];

    return Row(
      children: steps.map((step) {
        final isActive = step.$1 == phase;
        final isDone = steps.indexOf(step) < steps.indexWhere((s) => s.$1 == phase);
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.gold.withValues(alpha: 0.12)
                  : AppColors.panel,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isActive
                    ? AppColors.gold.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
            ),
            child: Text(
              step.$3,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive
                    ? AppColors.gold
                    : isDone
                        ? AppColors.muted.withValues(alpha: 0.5)
                        : AppColors.muted,
                fontSize: 8,
                letterSpacing: 1,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════
// LP 패널
// ═══════════════════════════════════════════
class _LpPanel extends StatelessWidget {
  final int player;
  final DdGameState state;
  const _LpPanel({required this.player, required this.state});

  @override
  Widget build(BuildContext context) {
    final ti = player - 1;
    final lp = state.lp[ti];
    final isMyTurn = state.turn == player;
    final pColor = player == 1 ? AppColors.p1 : AppColors.p2;
    final pgColor = player == 1 ? AppColors.p1g : AppColors.p2g;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMyTurn
              ? pColor.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'P$player',
                style: TextStyle(
                  color: pgColor,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isMyTurn) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: pColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('TURN',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            lp.toString(),
            style: TextStyle(
              color: pgColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: lp / 8000,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(pColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 내 몬스터 패널 (세트/프리셋 UI 포함)
// ═══════════════════════════════════════════
class _MyMonsterPanel extends StatefulWidget {
  final DdGameState state;
  const _MyMonsterPanel({required this.state});

  @override
  State<_MyMonsterPanel> createState() => _MyMonsterPanelState();
}

class _MyMonsterPanelState extends State<_MyMonsterPanel> {
  String _selectedId = kMonsters.first.id;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final ti = s.turn - 1;
    final isPreset = s.phase == DdPhase.preset;
    final currentMon = isPreset ? s.preMonsters[ti] : s.monsters[ti];
    final canSet = (s.phase == DdPhase.set || isPreset) && currentMon == null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isPreset ? '🃏 NEXT ROUND SET' : '🃏 MONSTER ZONE',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                'PLAYER ${s.turn}',
                style: TextStyle(
                  color:
                      s.turn == 1 ? AppColors.p1g : AppColors.p2g,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (canSet) ...[
            // 몬스터 선택 드롭다운
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedId,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(
                        color: AppColors.text, fontSize: 11),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      filled: true,
                      fillColor: AppColors.card,
                    ),
                    items: kMonsters
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(
                                '${m.emoji} ${m.name} (${m.atk})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedId = v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => context
                      .read<DdBloc>()
                      .add(DdSetMonsterEvent(_selectedId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.gold.withValues(alpha: 0.12),
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(
                        color: AppColors.gold, width: 0.8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    isPreset ? '예약' : 'SET',
                    style:
                        const TextStyle(fontSize: 11, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ] else if (currentMon != null) ...[
            // 몬스터 카드 표시
            _MonsterCard(
              monster: currentMon,
              curAtk: (s.phase == DdPhase.result ||
                      s.phase == DdPhase.preset)
                  ? s.curAtk[ti]
                  : currentMon.atk,
              showChange: true,
            ),
            const SizedBox(height: 8),
            // 변경 버튼 (set 페이즈에서만)
            if (s.phase == DdPhase.set || isPreset)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      context.read<DdBloc>().add(const DdRemoveMonsterEvent()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(
                        color: Color(0xFFA03030), width: 0.8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('✕ 변경',
                      style:
                          TextStyle(fontSize: 10, letterSpacing: 1)),
                ),
              ),
          ] else ...[
            // 빈 슬롯
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              alignment: Alignment.center,
              child: Text(
                isPreset ? '— 다음 라운드 몬스터 없음 —' : '— 몬스터 없음 —',
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 몬스터 카드
// ═══════════════════════════════════════════
class _MonsterCard extends StatelessWidget {
  final MonsterModel monster;
  final int curAtk;
  final bool showChange;
  const _MonsterCard({
    required this.monster,
    required this.curAtk,
    this.showChange = false,
  });

  @override
  Widget build(BuildContext context) {
    final delta = curAtk - monster.atk;
    final atkColor = delta > 0
        ? AppColors.green
        : delta < 0
            ? AppColors.red
            : AppColors.goldLight;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // 이미지 영역 (이모지)
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.02),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Center(
              child: Text(
                monster.emoji,
                style: const TextStyle(fontSize: 44),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        monster.name +
                            (monster.flying ? ' 🦅' : ''),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            width: 0.8),
                      ),
                      child: Text(
                        monster.type,
                        style: const TextStyle(
                            color: AppColors.gold, fontSize: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('ATK ',
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 9)),
                    Text(
                      '$curAtk',
                      style: TextStyle(
                        color: atkColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${monster.atk}',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 9),
                    ),
                  ],
                ),
                if (monster.effect.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    monster.effect,
                    style: const TextStyle(
                        color: Color(0xFF8888BB),
                        fontSize: 10,
                        height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 주사위 영역
// ═══════════════════════════════════════════
class _DiceArena extends StatelessWidget {
  final DdGameState state;
  const _DiceArena({required this.state});

  @override
  Widget build(BuildContext context) {
    final isResult = state.phase == DdPhase.result || state.phase == DdPhase.preset;
    final p1Roll = state.diceRolls[0];
    final p2Roll = state.diceRolls[1];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            child: (isResult && state.monsters[0] != null && state.monsters[1] != null)
                ? _BattleResultDisplay(key: const ValueKey('battle'), state: state)
                : SizedBox(
                    key: const ValueKey('dice'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DiceSlot(
                          label: 'P1',
                          value: p1Roll,
                          rolling: state.rolling,
                          playerColor: AppColors.p1g,
                        ),
                        const Text(
                          'VS',
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                        _DiceSlot(
                          label: 'P2',
                          value: p2Roll,
                          rolling: state.rolling,
                          playerColor: AppColors.p2g,
                        ),
                      ],
                    ),
                  ),
          ),
          if (state.resultMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                state.resultMessage,
                style: const TextStyle(
                    color: AppColors.text, fontSize: 10, height: 1.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BattleResultDisplay extends StatelessWidget {
  final DdGameState state;
  const _BattleResultDisplay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final p1Mon = state.monsters[0]!;
    final p2Mon = state.monsters[1]!;
    final p1Atk = state.curAtk[0];
    final p2Atk = state.curAtk[1];
    final p1Roll = state.diceRolls[0];
    final p2Roll = state.diceRolls[1];

    final p1Wins = p1Atk > p2Atk;
    final p2Wins = p2Atk > p1Atk;

    return Row(
      children: [
        Expanded(
          child: _BattleSideCard(
            player: 1,
            monster: p1Mon,
            atk: p1Atk,
            roll: p1Roll,
            isWinner: p1Wins,
            isLoser: p2Wins,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              const Text('VS',
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              // LP 현황
              _LpCompact(lp1: state.lp[0], lp2: state.lp[1]),
            ],
          ),
        ),
        Expanded(
          child: _BattleSideCard(
            player: 2,
            monster: p2Mon,
            atk: p2Atk,
            roll: p2Roll,
            isWinner: p2Wins,
            isLoser: p1Wins,
          ),
        ),
      ],
    );
  }
}

class _BattleSideCard extends StatelessWidget {
  final int player;
  final MonsterModel monster;
  final int atk;
  final int? roll;
  final bool isWinner;
  final bool isLoser;
  const _BattleSideCard({
    required this.player,
    required this.monster,
    required this.atk,
    required this.roll,
    required this.isWinner,
    required this.isLoser,
  });

  @override
  Widget build(BuildContext context) {
    final pColor = player == 1 ? AppColors.p1 : AppColors.p2;
    final pgColor = player == 1 ? AppColors.p1g : AppColors.p2g;
    final borderColor = isWinner
        ? AppColors.green
        : isLoser
            ? AppColors.red.withValues(alpha: 0.5)
            : pColor.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: pColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: isWinner ? 1.5 : 1.0),
      ),
      child: Column(
        children: [
          Text('P$player',
              style: TextStyle(
                  color: pgColor, fontSize: 9, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(monster.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            monster.name,
            style: const TextStyle(
                color: AppColors.gold,
                fontSize: 9,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (roll != null) ...[
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text('$roll',
                      style: const TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                'ATK $atk',
                style: TextStyle(
                  color: isWinner
                      ? AppColors.green
                      : isLoser
                          ? AppColors.red
                          : AppColors.goldLight,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isWinner)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('🏆 WIN',
                  style: TextStyle(
                      color: AppColors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class _LpCompact extends StatelessWidget {
  final int lp1;
  final int lp2;
  const _LpCompact({required this.lp1, required this.lp2});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$lp1',
            style: const TextStyle(
                color: AppColors.p1g,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const Text('LP', style: TextStyle(color: AppColors.muted, fontSize: 8)),
        const SizedBox(height: 2),
        Text('$lp2',
            style: const TextStyle(
                color: AppColors.p2g,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DiceSlot extends StatefulWidget {
  final String label;
  final int? value;
  final bool rolling;
  final Color playerColor;
  const _DiceSlot({
    required this.label,
    required this.value,
    required this.rolling,
    required this.playerColor,
  });

  @override
  State<_DiceSlot> createState() => _DiceSlotState();
}

class _DiceSlotState extends State<_DiceSlot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rand = Random();
  int _animVal = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..addListener(() {
        if (widget.rolling) {
          setState(() => _animVal = _rand.nextInt(6) + 1);
        }
      });
  }

  @override
  void didUpdateWidget(_DiceSlot old) {
    super.didUpdateWidget(old);
    if (widget.rolling && !old.rolling) {
      _ctrl.repeat();
    } else if (!widget.rolling && old.rolling) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayVal = widget.rolling ? _animVal : widget.value;
    final showVal = displayVal != null;

    Color borderColor = AppColors.border;
    Color textColor = AppColors.goldLight;
    if (!widget.rolling && widget.value != null) {
      if (widget.value == 6) borderColor = AppColors.green;
      if (widget.value == 1) borderColor = AppColors.red;
      if (widget.value == 5) borderColor = AppColors.yellow;
    }

    return Column(
      children: [
        Text(widget.label,
            style: TextStyle(
                color: widget.playerColor,
                fontSize: 9,
                letterSpacing: 1)),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: borderColor != AppColors.border
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: showVal
              ? Text(
                  '$displayVal',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Georgia',
                  ),
                )
              : Text(
                  '—',
                  style: TextStyle(
                    color: AppColors.muted.withValues(alpha: 0.5),
                    fontSize: 20,
                  ),
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 액션 버튼
// ═══════════════════════════════════════════
class _ActionButtons extends StatelessWidget {
  final DdGameState state;
  const _ActionButtons({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DdBloc>();
    final s = state;

    final isSet = s.phase == DdPhase.set;
    final isBattle = s.phase == DdPhase.battle;
    final isResult = s.phase == DdPhase.result;

    final canBattle = isSet && !s.firstTurn;
    final canRoll = isBattle && !s.rolling;
    final canEnd = !isBattle && !s.rolling;

    return Column(
      children: [
        // 가이드 텍스트
        _GuideText(state: s),
        const SizedBox(height: 10),

        if (isResult) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => bloc.add(const DdGoPresetEvent()),
              style: _goldBtnStyle(),
              child: const Text('🃏 다음 라운드 세트 →',
                  style: TextStyle(fontSize: 12, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (isBattle)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  canRoll ? () => bloc.add(const DdRollDiceEvent()) : null,
              style: _goldBtnStyle(),
              child: Text(
                s.rolling ? '🎲 굴리는 중...' : '🎲 주사위 굴리기!',
                style: const TextStyle(fontSize: 13, letterSpacing: 2),
              ),
            ),
          ),

        if (!isBattle && !isResult) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canBattle
                  ? () => bloc.add(const DdGoBattleEvent())
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.p1.withValues(alpha: 0.15),
                foregroundColor: AppColors.p1g,
                side: const BorderSide(
                    color: AppColors.p1, width: 0.8),
                disabledForegroundColor: AppColors.muted,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                s.firstTurn
                    ? '⚔️ 배틀 불가 (첫 턴)'
                    : '⚔️ 배틀 페이즈',
                style: const TextStyle(fontSize: 12, letterSpacing: 1),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (!isBattle) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed:
                  canEnd ? () => bloc.add(const DdEndTurnEvent()) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldLight,
                side: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.5)),
                disabledForegroundColor: AppColors.muted,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                '턴 종료 →',
                style: TextStyle(fontSize: 11, letterSpacing: 2),
              ),
            ),
          ),
        ],
      ],
    );
  }

  ButtonStyle _goldBtnStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold.withValues(alpha: 0.15),
        foregroundColor: AppColors.goldLight,
        side: const BorderSide(color: AppColors.gold, width: 0.8),
        disabledForegroundColor: AppColors.muted,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      );
}

class _GuideText extends StatelessWidget {
  final DdGameState state;
  const _GuideText({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    String guide = '';
    if (s.phase == DdPhase.set) {
      guide = s.firstTurn
          ? '⚠️ 첫 턴 — 배틀 불가. 몬스터를 세트하고 턴 종료를 누르세요.'
          : '🃏 몬스터를 세트하고 ⚔️ 배틀 페이즈를 누르세요. 세트 없이 배틀하면 LP -1000.';
    } else if (s.phase == DdPhase.battle) {
      guide = '⚔️ 배틀 페이즈 — 🎲 주사위 굴리기를 눌러 전투를 시작하세요.';
    } else if (s.phase == DdPhase.result) {
      guide = '📋 결과 확인 — 다음 라운드 세트 버튼을 눌러 미리 세트하세요.';
    } else if (s.phase == DdPhase.preset) {
      guide = '🃏 다음 라운드 몬스터를 미리 세트하세요. 세트 후 턴 종료를 누르세요.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.15)),
      ),
      child: Text(
        guide,
        style: const TextStyle(
            color: AppColors.muted, fontSize: 10, height: 1.6),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 상대방 패널 (간략)
// ═══════════════════════════════════════════
class _OppPanel extends StatelessWidget {
  final DdGameState state;
  const _OppPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final oi = 2 - state.turn; // 상대 인덱스 (0 or 1)
    final oppPlayer = state.turn == 1 ? 2 : 1;
    final oppMon = state.monsters[oi];
    final showCard = state.phase == DdPhase.result ||
        state.phase == DdPhase.preset;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상대방 (PLAYER $oppPlayer)',
            style: TextStyle(
              color: oppPlayer == 1 ? AppColors.p1g : AppColors.p2g,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          if (showCard && oppMon != null) ...[
            Row(
              children: [
                Text(oppMon.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      oppMon.name,
                      style: const TextStyle(
                          color: AppColors.gold, fontSize: 11),
                    ),
                    Text(
                      'ATK ${state.curAtk[oi]}',
                      style: const TextStyle(
                          color: AppColors.goldLight, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ] else if (oppMon != null) ...[
            Row(
              children: [
                const Text('🂠',
                    style: TextStyle(
                        fontSize: 32, color: AppColors.muted)),
                const SizedBox(width: 12),
                const Text(
                  '✓ 몬스터 세트됨',
                  style: TextStyle(
                      color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ] else ...[
            const Text(
              '— 몬스터 없음 (배틀 시 LP -1000) —',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            '상대방 카드 정보는 배틀 후 공개됩니다',
            style: TextStyle(
                color: AppColors.muted,
                fontSize: 9,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 게임 로그
// ═══════════════════════════════════════════
class _LogPanel extends StatelessWidget {
  final DdGameState state;
  const _LogPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final revealed = state.logRevealed || state.gameOver;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'DUEL LOG',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 9,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                Text(
                  revealed ? '✓ 공개됨' : '🔒 게임 종료 후 공개',
                  style: TextStyle(
                    color: revealed ? AppColors.green : AppColors.muted,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (revealed)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemCount: state.log.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    state.log[i],
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 10,
                        height: 1.5),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '게임 종료 후 공개됩니다',
                  style: TextStyle(
                    color: AppColors.muted.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 승리 오버레이
// ═══════════════════════════════════════════
class _WinOverlay extends StatelessWidget {
  final DdGameState state;
  const _WinOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    final winner = state.winner;
    final winColor =
        winner == 1 ? AppColors.p1g : AppColors.p2g;

    return Container(
      color: AppColors.dark.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'PLAYER $winner WIN!',
              style: TextStyle(
                color: winColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Georgia',
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: winColor.withValues(alpha: 0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'DUEL COMPLETE',
              style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  letterSpacing: 4),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      context.read<DdBloc>().add(const DdRestartEvent()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.p1.withValues(alpha: 0.15),
                    foregroundColor: AppColors.p1g,
                    side: const BorderSide(color: AppColors.p1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('▶ 다시 시작',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
