import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/models/dd_game_state.dart';
import '../../../core/models/monster_model.dart';
import 'dd_event.dart';

class DdBloc extends Bloc<DdEvent, DdGameState> {
  final _rand = Random();

  DdBloc() : super(DdGameState.initial()) {
    on<DdInitEvent>(_onInit);
    on<DdCoinRollEvent>(_onCoinRoll);
    on<DdHandoffConfirmEvent>(_onHandoffConfirm);
    on<DdSetMonsterEvent>(_onSetMonster);
    on<DdRemoveMonsterEvent>(_onRemoveMonster);
    on<DdGoBattleEvent>(_onGoBattle);
    on<DdRollDiceEvent>(_onRollDice);
    on<DdGoPresetEvent>(_onGoPreset);
    on<DdEndTurnEvent>(_onEndTurn);
    on<DdRestartEvent>(_onRestart);
    on<DdSetModeEvent>(_onSetMode);
  }

  int _rng() => _rand.nextInt(6) + 1;

  // ── 초기화 ──
  void _onInit(DdInitEvent event, Emitter<DdGameState> emit) {
    emit(DdGameState.initial());
  }

  // ── 선공 결정 주사위 ──
  Future<void> _onCoinRoll(
    DdCoinRollEvent event,
    Emitter<DdGameState> emit,
  ) async {
    if (state.coinFlipRolling) return;

    emit(state.copyWith(
      coinFlipRolling: true,
      coinFlipResult: '',
      coinFlipRolls: [null, null],
    ));

    // 애니메이션 시간 (UI가 rolling 상태 보고 자체 애니 실행)
    await Future.delayed(const Duration(milliseconds: 1300));

    int r1 = _rng();
    int r2 = _rng();

    // 무승부 처리: 재굴림
    if (r1 == r2) {
      emit(state.copyWith(
        coinFlipRolling: false,
        coinFlipRolls: [r1, r2],
        coinFlipResult: '🔄 무승부! 다시 굴립니다...',
      ));
      await Future.delayed(const Duration(milliseconds: 1000));
      emit(state.copyWith(
        coinFlipRolling: false,
        coinFlipRolls: [null, null],
        coinFlipResult: '',
      ));
      return;
    }

    final first = r1 > r2 ? 1 : 2;
    emit(state.copyWith(
      coinFlipRolling: false,
      coinFlipRolls: [r1, r2],
      coinFlipResult: '🎉 PLAYER $first 선공!',
    ));

    await Future.delayed(const Duration(milliseconds: 1200));

    var s = state.copyWith(
      turn: first,
      log: [...state.log, '선공 결정: PLAYER $first 선공!'],
    );

    if (s.isCpuMode) {
      // CPU 모드: 핸드오프 없이 바로 플레이
      s = s.copyWith(screenMode: DdScreenMode.playing);
      emit(s);
      if (first == 2) await _runCpuTurn(s, emit);
    } else {
      s = s.copyWith(
        screenMode: DdScreenMode.handoff,
        handoffTitle: 'PLAYER $first 선공!',
        handoffSub: '화면을 PLAYER $first에게 넘겨주세요.\n첫 턴은 배틀 불가.',
      );
      emit(s);
    }
  }

  // ── 핸드오프 확인 ──
  void _onHandoffConfirm(
    DdHandoffConfirmEvent event,
    Emitter<DdGameState> emit,
  ) {
    emit(state.copyWith(
      screenMode: DdScreenMode.playing,
      log: [
        ...state.log,
        '라운드 ${state.round} · PLAYER ${state.turn} 턴${state.firstTurn ? ' (첫 턴 - 배틀 불가)' : ''}',
      ],
    ));
  }

  // ── 몬스터 세트 ──
  void _onSetMonster(DdSetMonsterEvent event, Emitter<DdGameState> emit) {
    final ti = state.turn - 1;
    final m = kMonsters.firstWhere(
      (x) => x.id == event.monsterId,
      orElse: () => kMonsters.first,
    );

    if (state.phase == DdPhase.preset) {
      final newPre = List<MonsterModel?>.from(state.preMonsters);
      newPre[ti] = m;
      emit(state.copyWith(
        preMonsters: newPre,
        log: [...state.log, 'PLAYER ${state.turn}: 다음 라운드 몬스터 예약 (비공개)'],
      ));
    } else {
      final newMon = List<MonsterModel?>.from(state.monsters);
      final newAtk = List<int>.from(state.curAtk);
      newMon[ti] = m;
      newAtk[ti] = m.atk;
      emit(state.copyWith(
        monsters: newMon,
        curAtk: newAtk,
        log: [...state.log, 'PLAYER ${state.turn}: 몬스터 세트 완료 (비공개)'],
      ));
    }
  }

  // ── 몬스터 제거 ──
  void _onRemoveMonster(DdRemoveMonsterEvent event, Emitter<DdGameState> emit) {
    final ti = state.turn - 1;

    if (state.phase == DdPhase.preset) {
      final newPre = List<MonsterModel?>.from(state.preMonsters);
      newPre[ti] = null;
      emit(state.copyWith(preMonsters: newPre));
    } else {
      final newMon = List<MonsterModel?>.from(state.monsters);
      final newAtk = List<int>.from(state.curAtk);
      newMon[ti] = null;
      newAtk[ti] = 0;
      emit(state.copyWith(
        monsters: newMon,
        curAtk: newAtk,
        log: [...state.log, 'PLAYER ${state.turn}: 몬스터 변경'],
      ));
    }
  }

  // ── 배틀 페이즈 이동 ──
  void _onGoBattle(DdGoBattleEvent event, Emitter<DdGameState> emit) {
    if (state.firstTurn) {
      emit(state.copyWith(
        resultMessage: '⚠️ 첫 턴은 배틀을 할 수 없습니다!',
      ));
      return;
    }
    emit(state.copyWith(phase: DdPhase.battle));
  }

  // ── 주사위 굴리기 + 배틀 처리 ──
  Future<void> _onRollDice(
    DdRollDiceEvent event,
    Emitter<DdGameState> emit,
  ) async {
    if (state.rolling) return;

    emit(state.copyWith(rolling: true));
    await Future.delayed(const Duration(milliseconds: 1200));

    // 주사위 굴리기
    var r = [_rng(), _rng()];

    // 효과 적용 + ATK 계산
    final effectResult = _applyEffects(List.from(r), List.from(state.monsters));
    final newCurAtk = effectResult.curAtk;
    final msgs = effectResult.messages;
    final extraRoll = effectResult.extraRoll;

    // 배틀 처리
    var newLp = List<int>.from(state.lp);
    final battleMsgs = _doBattle(newCurAtk, state.monsters, newLp);

    final allMsgs = [...msgs, ...battleMsgs];
    final resultStr = allMsgs.join('\n');

    // 게임 종료 체크
    int? winner;
    if (newLp[0] <= 0) winner = 2;
    if (newLp[1] <= 0) winner = 1;
    if (newLp[0] <= 0 && newLp[1] <= 0) winner = state.turn; // 동시 0이면 현재 턴 플레이어 승

    emit(state.copyWith(
      rolling: false,
      diceRolls: [r[0], r[1]],
      curAtk: newCurAtk,
      lp: newLp,
      phase: DdPhase.result,
      resultMessage: resultStr,
      extraRoll: extraRoll,
      gameOver: winner != null,
      winner: winner,
      logRevealed: winner != null,
      log: [...state.log, ...allMsgs],
    ));
  }

  // ── preset 페이즈 이동 ──
  void _onGoPreset(DdGoPresetEvent event, Emitter<DdGameState> emit) {
    emit(state.copyWith(
      phase: DdPhase.preset,
      monsters: [null, null], // 배틀 결과 확인 후 초기화
    ));
  }

  // ── 턴 종료 ──
  Future<void> _onEndTurn(DdEndTurnEvent event, Emitter<DdGameState> emit) async {
    final ti = state.turn - 1;
    final next = state.turn == 1 ? 2 : 1;

    // 다음 라운드 슬롯 초기화 (preset 있으면 복사)
    var newMon = <MonsterModel?>[null, null];
    var newAtk = [0, 0];
    var newPre = List<MonsterModel?>.from(state.preMonsters);

    if (state.preMonsters[ti] != null) {
      newMon[ti] = state.preMonsters[ti];
      newAtk[ti] = state.preMonsters[ti]!.atk;
      newPre[ti] = null;
    }

    final newRound = next == 1 ? state.round + 1 : state.round;

    final baseState = state.copyWith(
      turn: next,
      phase: DdPhase.set,
      firstTurn: false,
      rolling: false,
      monsters: newMon,
      preMonsters: newPre,
      curAtk: newAtk,
      round: newRound,
      diceRolls: [null, null],
      resultMessage: '몬스터를 선택하고 세트하세요.',
      clearExtraRoll: true,
      log: [...state.log, '→ PLAYER $next 턴 시작'],
    );

    if (state.isCpuMode) {
      final s = baseState.copyWith(screenMode: DdScreenMode.playing);
      emit(s);
      if (next == 2 && !s.gameOver) await _runCpuTurn(s, emit);
    } else {
      emit(baseState.copyWith(
        screenMode: DdScreenMode.handoff,
        handoffTitle: 'PLAYER $next의 턴',
        handoffSub: '이제 PLAYER $next 차례입니다.\n화면을 넘겨주세요.',
      ));
    }
  }

  // ── 재시작 ──
  void _onRestart(DdRestartEvent event, Emitter<DdGameState> emit) {
    emit(DdGameState.initial());
  }

  // ── 모드 선택 ──
  void _onSetMode(DdSetModeEvent event, Emitter<DdGameState> emit) {
    emit(state.copyWith(
      isCpuMode: event.isCpuMode,
      screenMode: DdScreenMode.coinFlip,
    ));
  }

  // ── CPU 턴 자동 처리 ──
  Future<void> _runCpuTurn(
    DdGameState init,
    Emitter<DdGameState> emit,
  ) async {
    var s = init;
    await Future.delayed(const Duration(milliseconds: 600));

    // CPU 몬스터 자동 세트 (ATK 최대 몬스터 선택)
    final cpuMon = kMonsters.reduce((a, b) => a.atk >= b.atk ? a : b);
    final newMon = List<MonsterModel?>.from(s.monsters);
    final newAtk = List<int>.from(s.curAtk);
    newMon[1] = cpuMon;
    newAtk[1] = cpuMon.atk;
    s = s.copyWith(
      monsters: newMon,
      curAtk: newAtk,
      log: [...s.log, '🤖 CPU: ${cpuMon.emoji} ${cpuMon.name} 세트'],
    );
    emit(s);
    await Future.delayed(const Duration(milliseconds: 800));

    if (s.firstTurn) {
      // 첫 턴은 배틀 불가 → 턴 종료
      final next = 1;
      final newRound = next == 1 ? s.round + 1 : s.round;
      s = s.copyWith(
        turn: next,
        phase: DdPhase.set,
        firstTurn: false,
        round: newRound,
        diceRolls: [null, null],
        resultMessage: '몬스터를 선택하고 세트하세요.',
        screenMode: DdScreenMode.playing,
        log: [...s.log, '🤖 CPU: 첫 턴 종료 → PLAYER 1 턴'],
      );
      emit(s);
      return;
    }

    // 배틀 페이즈 → 주사위 굴리기
    s = s.copyWith(phase: DdPhase.battle);
    emit(s);
    await Future.delayed(const Duration(milliseconds: 500));

    // 주사위 굴리기 (기존 롤 로직 재사용)
    s = s.copyWith(rolling: true);
    emit(s);
    await Future.delayed(const Duration(milliseconds: 1200));

    var r = [_rng(), _rng()];
    final effectResult = _applyEffects(List.from(r), List.from(s.monsters));
    final newCurAtk2 = effectResult.curAtk;
    final msgs = effectResult.messages;
    final extraRoll = effectResult.extraRoll;
    var newLp = List<int>.from(s.lp);
    final battleMsgs = _doBattle(newCurAtk2, s.monsters, newLp);
    final allMsgs = [...msgs, ...battleMsgs];

    int? winner;
    if (newLp[0] <= 0) winner = 2;
    if (newLp[1] <= 0) winner = 1;
    if (newLp[0] <= 0 && newLp[1] <= 0) winner = s.turn;

    s = s.copyWith(
      rolling: false,
      diceRolls: [r[0], r[1]],
      curAtk: newCurAtk2,
      lp: newLp,
      phase: DdPhase.result,
      resultMessage: allMsgs.join('\n'),
      extraRoll: extraRoll,
      gameOver: winner != null,
      winner: winner,
      logRevealed: winner != null,
      log: [...s.log, ...allMsgs],
    );
    emit(s);
    if (s.gameOver) return;

    await Future.delayed(const Duration(milliseconds: 1500));

    // preset → 턴 종료 → P1 턴
    s = s.copyWith(phase: DdPhase.preset);
    emit(s);
    await Future.delayed(const Duration(milliseconds: 600));

    // CPU preset: 동일 몬스터 예약
    final newPre2 = List<MonsterModel?>.from(s.preMonsters);
    newPre2[1] = cpuMon;
    s = s.copyWith(
      preMonsters: newPre2,
      log: [...s.log, '🤖 CPU: 다음 라운드 ${cpuMon.emoji} 예약'],
    );
    emit(s);
    await Future.delayed(const Duration(milliseconds: 600));

    // 턴 종료 → P1
    var newMonFinal = <MonsterModel?>[null, null];
    var newAtkFinal = [0, 0];
    var newPreFinal = List<MonsterModel?>.from(s.preMonsters);
    if (newPreFinal[1] != null) {
      newMonFinal[1] = newPreFinal[1];
      newAtkFinal[1] = newPreFinal[1]!.atk;
      newPreFinal[1] = null;
    }
    s = s.copyWith(
      turn: 1,
      phase: DdPhase.set,
      firstTurn: false,
      rolling: false,
      monsters: newMonFinal,
      preMonsters: newPreFinal,
      curAtk: newAtkFinal,
      round: s.round + 1,
      diceRolls: [null, null],
      resultMessage: '몬스터를 선택하고 세트하세요.',
      screenMode: DdScreenMode.playing,
      log: [...s.log, '→ PLAYER 1 턴 시작'],
    );
    emit(s);
  }

  // ════════════════════════════════════════
  // 게임 로직 헬퍼
  // ════════════════════════════════════════

  _EffectResult _applyEffects(List<int> r, List<MonsterModel?> monsters) {
    final msgs = <String>[];
    final curAtk = [0, 0];
    int? extraRoll;

    // 1. 하피 바람 (눈 4~6: 상대 주사위 -2)
    for (int me = 0; me < 2; me++) {
      final opp = 1 - me;
      if (monsters[me]?.special == 'harpy_wind' && r[me] >= 4) {
        final before = r[opp];
        r[opp] = (r[opp] - 2).clamp(1, 6);
        msgs.add('🦅 하피 바람! P${opp + 1} 주사위 $before→${r[opp]}');
      }
    }

    // 2. 데몬 저주 예약
    final skullCurse = [false, false];
    if (monsters[0]?.special == 'skull_curse' && r[0] == 3) skullCurse[1] = true;
    if (monsters[1]?.special == 'skull_curse' && r[1] == 3) skullCurse[0] = true;

    // 3. ATK 계산
    for (int i = 0; i < 2; i++) {
      final m = monsters[i];
      if (m == null) {
        msgs.add('P${i + 1} 몬스터 없음 → LP -1000');
        continue;
      }
      final roll = r[i];
      int atk;
      String note = '';

      switch (m.special) {
        case 'lucky_sword':
          atk = ddBaseRule(m.atk, roll);
          if (roll == 6) {
            atk = m.atk * 2;
            note = '⚔️ 행운의 일격! ATK×2 + 추가 피해 예정';
          }
        case 'no_half':
          atk = roll == 5 ? m.atk : ddBaseRule(m.atk, roll);
          if (roll == 5) note = '🧝 절반 무효! ATK 유지';
        case 'dice_multiply':
          atk = roll * 200;
          note = '🦔 ATK=$roll×200=$atk';
        case 'dragon_ace':
          if (roll == 6) {
            atk = 3000;
            note = '🐉 드래곤 에이스! ATK 3000!';
          } else if (roll == 1) {
            atk = 0;
            note = '🐉 눈 1 — 공격 불가!';
          } else {
            atk = ddBaseRule(m.atk, roll);
          }
        case 'blue_shield':
          atk = ddBaseRule(m.atk, roll);
          if (atk < 1500) {
            atk = 1500;
            note = '🔵 백룡 보호막! ATK 최소 1500';
          }
        case 'skull_curse':
          atk = ddBaseRule(m.atk, roll);
          if (roll == 3) note = '😈 저주 발동! 상대 ATK 절반';
        case 'slot_double':
          final ex = _rng();
          extraRoll = ex;
          final sum = roll + ex;
          if (sum == 12) {
            atk = m.atk * 3;
            note = '🎰 슈퍼잭팟! 합$sum ATK×3!!!';
          } else if (sum == 7) {
            atk = m.atk * 2;
            note = '🎰 잭팟! 합$sum ATK×2!';
          } else if (sum == 2) {
            atk = 0;
            note = '🎰 대참사! 합$sum ATK 0';
          } else {
            atk = ddBaseRule(m.atk, roll);
            note = '🎰 슬롯: +$ex→합$sum';
          }
        case 'mage_bonus':
          atk = ddBaseRule(m.atk, roll);
          if ([2, 3, 4].contains(roll)) {
            atk += 300;
            note = '🧙 마법 증폭! +300';
          }
        default:
          atk = ddBaseRule(m.atk, roll);
      }

      curAtk[i] = atk.clamp(0, 999999);
      final delta = curAtk[i] - m.atk;
      final deltaStr = delta > 0 ? '+$delta' : delta < 0 ? '$delta' : '±0';
      msgs.add('P${i + 1} 🎲$roll → ATK ${curAtk[i]} ($deltaStr)');
      if (note.isNotEmpty) msgs.add(note);
    }

    // 4. 데몬 저주 적용
    for (int i = 0; i < 2; i++) {
      if (skullCurse[i] && monsters[i] != null) {
        final before = curAtk[i];
        curAtk[i] = (before / 2).floor();
        msgs.add('😈 저주! P${i + 1} ATK $before→${curAtk[i]}');
      }
    }

    return _EffectResult(curAtk: curAtk, messages: msgs, extraRoll: extraRoll);
  }

  List<String> _doBattle(
    List<int> curAtk,
    List<MonsterModel?> monsters,
    List<int> lp, // mutable — 직접 수정
  ) {
    final msgs = <String>[];

    if (monsters[0] == null) {
      lp[0] = (lp[0] - 1000).clamp(0, 8000);
      msgs.add('💥 P1 LP -1000 (몬스터 없음) → ${lp[0]}');
    }
    if (monsters[1] == null) {
      lp[1] = (lp[1] - 1000).clamp(0, 8000);
      msgs.add('💥 P2 LP -1000 (몬스터 없음) → ${lp[1]}');
    }

    if (monsters[0] != null && monsters[1] != null) {
      final diff = curAtk[0] - curAtk[1];
      if (diff > 0) {
        int dmg = diff;
        if (monsters[1]?.special == 'iron_wall') {
          dmg = (diff / 2).floor();
          msgs.add('🛡️ 철갑 방어! P2 피해 절반($diff→$dmg)');
        }
        lp[1] = (lp[1] - dmg).clamp(0, 8000);
        msgs.add(
          '⚔️ ${monsters[0]!.emoji} ${monsters[0]!.name}(${curAtk[0]}) 승!'
          ' P2 LP -$dmg → ${lp[1]}',
        );
        // 행운의 일격 추가 피해
        if (monsters[0]?.special == 'lucky_sword' &&
            curAtk[0] == monsters[0]!.atk * 2) {
          lp[1] = (lp[1] - 400).clamp(0, 8000);
          msgs.add('⚔️ 행운의 일격 추가 피해! P2 LP -400 → ${lp[1]}');
        }
      } else if (diff < 0) {
        int dmg = -diff;
        if (monsters[0]?.special == 'iron_wall') {
          dmg = (dmg / 2).floor();
          msgs.add('🛡️ 철갑 방어! P1 피해 절반(${-diff}→$dmg)');
        }
        lp[0] = (lp[0] - dmg).clamp(0, 8000);
        msgs.add(
          '⚔️ ${monsters[1]!.emoji} ${monsters[1]!.name}(${curAtk[1]}) 승!'
          ' P1 LP -$dmg → ${lp[0]}',
        );
        if (monsters[1]?.special == 'lucky_sword' &&
            curAtk[1] == monsters[1]!.atk * 2) {
          lp[0] = (lp[0] - 400).clamp(0, 8000);
          msgs.add('⚔️ 행운의 일격 추가 피해! P1 LP -400 → ${lp[0]}');
        }
      } else {
        msgs.add('⚔️ 공격력 동일 → 무승부');
      }
    }

    return msgs;
  }
}

class _EffectResult {
  final List<int> curAtk;
  final List<String> messages;
  final int? extraRoll;

  _EffectResult({
    required this.curAtk,
    required this.messages,
    this.extraRoll,
  });
}
