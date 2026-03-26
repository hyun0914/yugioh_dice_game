import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/models/ddm_models.dart';
import 'ddm_cpu.dart';
import 'ddm_event.dart';

class DdmBloc extends Bloc<DdmEvent, DdmGameState> {
  final _rand = Random();

  DdmBloc() : super(_buildInitialState()) {
    on<DdmInitEvent>(_onInit);
    on<DdmCoinRollEvent>(_onCoinRoll);
    on<DdmToggleDieEvent>(_onToggleDie);
    on<DdmRollDiceEvent>(_onRollDice);
    on<DdmOpenSummonPanelEvent>(_onOpenSummonPanel);
    on<DdmSelectMonsterForSummonEvent>(_onSelectMonsterForSummon);
    on<DdmRotateTileEvent>(_onRotateTile);
    on<DdmCellClickEvent>(_onCellClick);
    on<DdmConfirmPlaceTileEvent>(_onConfirmPlaceTile);
    on<DdmCancelSummonEvent>(_onCancelSummon);
    on<DdmUseMagicEvent>(_onUseMagic);
    on<DdmStartTrapModeEvent>(_onStartTrapMode);
    on<DdmCancelTrapEvent>(_onCancelTrap);
    on<DdmEndTurnEvent>(_onEndTurn);
    on<DdmRestartEvent>(_onRestart);
    on<DdmSetModeEvent>(_onSetMode);
    on<DdmConfirmBattleEvent>(_onConfirmBattle);
  }

  // ─── 초기 상태 생성 ───────────────────────────
  static DdmGameState _buildInitialState() {
    final board = _makeBoard();
    return DdmGameState(
      turn: 1,
      phase: DdmPhase.select,
      screenMode: DdmScreenMode.modeSelect,
      coinFlipRolls: const [null, null],
      coinFlipRolling: false,
      coinFlipResult: '',
      lords: const [DdmLord(), DdmLord()],
      pools: [_makeDicePool(), _makeDicePool()],
      crests: const [DdmCrests(), DdmCrests()],
      summonCount: const [0, 0],
      selectedDice: const [],
      lastRolled: const [],
      summonPanelOpen: false,
      board: board,
      monsters: const [],
      highlights: DdmHighlights.empty,
      mUidCounter: 0,
      rolled: false,
      log: const ['⬡ 던전 다이스 몬스터즈 시작!'],
      gameOver: false,
    );
  }

  static List<List<BoardCell?>> _makeBoard() {
    final board = List.generate(
      kDdmRows,
      (_) => List<BoardCell?>.filled(kDdmCols, null),
    );
    board[kLord1Row][kLordCol] =
        const BoardCell(type: BoardCellType.lord, player: 1);
    board[kLord2Row][kLordCol] =
        const BoardCell(type: BoardCellType.lord, player: 2);
    return board;
  }

  static List<DdmDie> _makeDicePool() {
    final pool = <DdmDie>[];
    for (int lv = 1; lv <= 3; lv++) {
      for (int i = 0; i < 5; i++) {
        pool.add(DdmDie(id: pool.length, level: lv));
      }
    }
    return pool;
  }

  // ─── 유틸리티 ────────────────────────────────
  List<List<BoardCell?>> _copyBoard(List<List<BoardCell?>> board) =>
      board.map((row) => List<BoardCell?>.from(row)).toList();

  List<List<DdmDie>> _copyPools(List<List<DdmDie>> pools) =>
      pools.map((pool) => List<DdmDie>.from(pool)).toList();

  DdmGameState _addLog(DdmGameState s, String msg) =>
      s.copyWith(log: [...s.log, msg]);

  DdmMonster? _monsterAt(List<DdmMonster> monsters, int r, int c,
      {int? playerNot}) {
    for (final m in monsters) {
      if (m.r == r && m.c == c) {
        if (playerNot == null || m.player != playerNot) return m;
      }
    }
    return null;
  }

  // ─── 초기화 ─────────────────────────────────
  void _onInit(DdmInitEvent event, Emitter<DdmGameState> emit) {
    emit(_buildInitialState());
  }

  // ─── 모드 선택 ──────────────────────────────
  void _onSetMode(DdmSetModeEvent event, Emitter<DdmGameState> emit) {
    emit(state.copyWith(
      isCpuMode: event.isCpuMode,
      screenMode: DdmScreenMode.coinFlip,
    ));
  }

  // ─── 선공 결정 ──────────────────────────────
  Future<void> _onCoinRoll(
    DdmCoinRollEvent event,
    Emitter<DdmGameState> emit,
  ) async {
    if (state.coinFlipRolling) return;

    emit(state.copyWith(
      coinFlipRolling: true,
      coinFlipResult: '',
      coinFlipRolls: [null, null],
    ));

    await Future.delayed(const Duration(milliseconds: 1300));

    final r1 = _rand.nextInt(6) + 1;
    final r2 = _rand.nextInt(6) + 1;

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
      screenMode: DdmScreenMode.playing,
      log: [...state.log, '선공: PLAYER $first'],
    );
    s = _addLog(s, '→ PLAYER $first 턴 시작 — 주사위 3개를 선택하세요');
    emit(s);

    // CPU가 선공이면 바로 CPU 턴 실행
    if (s.isCpuMode && first == 2) {
      await _runCpuTurn(s, emit);
    }
  }

  // ─── 주사위 선택 토글 ────────────────────────
  void _onToggleDie(DdmToggleDieEvent event, Emitter<DdmGameState> emit) {
    final t = state.turn - 1;
    if (state.phase != DdmPhase.select) return;

    final die = state.pools[t][event.index];
    if (die.used) return;

    final selected = List<int>.from(state.selectedDice);
    final idx = selected.indexOf(event.index);

    if (idx >= 0) {
      selected.removeAt(idx);
    } else {
      if (selected.length >= 3) {
        emit(_addLog(state, '✕ 주사위는 3개만 선택할 수 있습니다!'));
        return;
      }
      selected.add(event.index);
    }

    emit(state.copyWith(selectedDice: selected));
  }

  // ─── 주사위 굴리기 ───────────────────────────
  void _onRollDice(DdmRollDiceEvent event, Emitter<DdmGameState> emit) {
    final t = state.turn - 1;
    if (state.selectedDice.length != 3) {
      emit(_addLog(state, '✕ 주사위 3개를 선택하세요!'));
      return;
    }

    // 각 주사위 굴리기
    final results = state.selectedDice.map((idx) {
      final die = state.pools[t][idx];
      final faces = kDiceFaces[die.level]!;
      final crest = faces[_rand.nextInt(6)];
      return DdmRollResult(idx: idx, level: die.level, crest: crest);
    }).toList();

    // 크레스트 집계 (소환은 레벨별로 따로 카운트)
    final summonByLevel = {1: 0, 2: 0, 3: 0};
    var newCrests = state.crests[t];

    for (final r in results) {
      if (r.crest == 'summon') {
        summonByLevel[r.level] = (summonByLevel[r.level] ?? 0) + 1;
      } else {
        switch (r.crest) {
          case 'move':
            newCrests =
                newCrests.copyWith(move: (newCrests.move + 1).clamp(0, 10));
          case 'attack':
            newCrests =
                newCrests.copyWith(atk: (newCrests.atk + 1).clamp(0, 10));
          case 'magic':
            newCrests = newCrests.copyWith(
                magic: (newCrests.magic + 1).clamp(0, 10));
          case 'def':
            newCrests =
                newCrests.copyWith(def: (newCrests.def + 1).clamp(0, 10));
          case 'trap':
            newCrests =
                newCrests.copyWith(trap: (newCrests.trap + 1).clamp(0, 10));
        }
      }
    }

    // 소환 가능 레벨 확인 (같은 레벨 소환 크레스트 2개 이상)
    int? canSummonLevel;
    for (int lv = 1; lv <= 3; lv++) {
      if ((summonByLevel[lv] ?? 0) >= 2) canSummonLevel = lv;
    }

    final newCrestsList = List<DdmCrests>.from(state.crests);
    newCrestsList[t] = newCrests;

    final resStr = results
        .map((r) => 'Lv${r.level}→${_crestLabel(r.crest)}')
        .join(' / ');

    var s = state.copyWith(
      lastRolled: results,
      crests: newCrestsList,
      canSummonLevel: canSummonLevel,
      rolled: true,
      phase: DdmPhase.action,
      log: [...state.log, '🎲 $resStr'],
    );

    if (canSummonLevel != null) {
      s = _addLog(s, '★ Lv$canSummonLevel 소환 가능!');
    }
    emit(s);
  }

  String _crestLabel(String crest) {
    return switch (crest) {
      'summon' => '★소환',
      'move' => '🚶이동',
      'attack' => '⚔공격',
      'magic' => '✨마법',
      'def' => '🛡방어',
      'trap' => '🪤트랩',
      _ => crest,
    };
  }

  // ─── 소환 패널 열기 ──────────────────────────
  void _onOpenSummonPanel(
    DdmOpenSummonPanelEvent event,
    Emitter<DdmGameState> emit,
  ) {
    if (state.canSummonLevel == null) {
      emit(_addLog(state, '✕ 소환 크레스트 부족! (같은 레벨 2개 필요)'));
      return;
    }
    if (state.summonCount[state.turn - 1] >= kMaxSummonCount) {
      emit(_addLog(state, '✕ 최대 소환 횟수($kMaxSummonCount회) 초과!'));
      return;
    }
    emit(state.copyWith(summonPanelOpen: true));
  }

  // ─── 몬스터 선택 → 타일 배치 모드 진입 ─────────
  void _onSelectMonsterForSummon(
    DdmSelectMonsterForSummonEvent event,
    Emitter<DdmGameState> emit,
  ) {
    final level = state.canSummonLevel ?? 1;
    final shape = rollTileShape(level, _rand);
    final m = kMonsters.firstWhere(
      (x) => x.id == event.monsterId,
      orElse: () => kMonsters.first,
    );

    emit(state.copyWith(
      summonPanelOpen: false,
      placingTile: PlacingTileState(
        monsterId: m.id,
        monsterEmoji: m.emoji,
        monsterName: m.name,
        monsterAtk: m.atk,
        monsterFlying: m.flying,
        shape: shape,
      ),
    ));
  }

  // ─── 타일 회전 ──────────────────────────────
  void _onRotateTile(DdmRotateTileEvent event, Emitter<DdmGameState> emit) {
    final pt = state.placingTile;
    if (pt == null) return;

    final newRot = (pt.rot + event.dir + 4) % 4;
    var newPt = pt.copyWith(rot: newRot);

    // anchor가 있으면 새 rotation으로 프리뷰 재계산
    final anchor = pt.previewAnchor;
    if (anchor != null) {
      final computed = _computePreview(anchor.r, anchor.c, newPt, state);
      newPt = computed;
    } else {
      newPt = newPt.copyWith(previewCells: [], clearPreviewAnchor: true);
    }

    emit(state.copyWith(placingTile: newPt));
  }

  // ─── 보드 셀 클릭 ────────────────────────────
  void _onCellClick(DdmCellClickEvent event, Emitter<DdmGameState> emit) {
    if (state.pendingBattle != null) return;
    final r = event.r;
    final c = event.c;

    // 1. 타일 배치 모드
    if (state.placingTile != null) {
      final newPt = _computePreview(r, c, state.placingTile!, state);
      emit(state.copyWith(placingTile: newPt));
      return;
    }

    // 2. 트랩 설치 모드
    final trapMode = state.trapMode;
    if (trapMode != null) {
      final isCandidate = trapMode.any((h) => h.r == r && h.c == c);
      if (isCandidate) {
        final t = state.turn - 1;
        final newBoard = _copyBoard(state.board);
        final existing = newBoard[r][c];
        if (existing != null) {
          newBoard[r][c] = existing.copyWith(
            trap: TrapData(owner: state.turn),
          );
        }
        final newCrests = List<DdmCrests>.from(state.crests);
        newCrests[t] = newCrests[t].copyWith(
          trap: (newCrests[t].trap - 1).clamp(0, 10),
        );
        var s = state.copyWith(
          board: newBoard,
          crests: newCrests,
          clearTrapMode: true,
          log: [...state.log, '🪤 (${r + 1}행,${c + 1}열) 트랩 설치!'],
        );
        emit(s);
      }
      return;
    }

    // 3. 일반 모드: 내 몬스터 선택/이동/공격
    final clickedMon = _monsterAt(state.monsters, r, c);

    if (clickedMon != null && clickedMon.player == state.turn) {
      // 내 몬스터 클릭 → 선택/해제
      if (state.selectedMonster?.uid == clickedMon.uid) {
        emit(state.copyWith(
          clearSelectedMonster: true,
          highlights: DdmHighlights.empty,
        ));
      } else {
        final hl = _calcHighlights(clickedMon, state);
        emit(state.copyWith(
          selectedMonster: clickedMon,
          highlights: hl,
        ));
      }
      return;
    }

    final sel = state.selectedMonster;
    if (sel != null) {
      final hl = state.highlights;

      // 이동 하이라이트 클릭
      if (hl.move.any((h) => h.r == r && h.c == c)) {
        emit(_moveMonster(sel, r, c, state));
        return;
      }

      // 공격 하이라이트 클릭
      if (hl.attack.any((h) => h.r == r && h.c == c)) {
        emit(_doAttack(sel, r, c, state));
        return;
      }

      // 그 외 클릭 → 선택 해제
      emit(state.copyWith(
        clearSelectedMonster: true,
        highlights: DdmHighlights.empty,
      ));
    }
  }

  // ─── 타일 배치 확정 ──────────────────────────
  void _onConfirmPlaceTile(
    DdmConfirmPlaceTileEvent event,
    Emitter<DdmGameState> emit,
  ) {
    final s = _applyConfirmTile(state);
    if (s != null) emit(s);
  }

  // ─── 타일 확정 순수 변환 ──────────────────────
  DdmGameState? _applyConfirmTile(DdmGameState s) {
    final pt = s.placingTile;
    if (pt == null || pt.previewAnchor == null || pt.previewError != null) {
      return null;
    }
    final cells = pt.previewCells;
    if (cells.isEmpty) return null;

    final t = s.turn - 1;
    final newBoard = _copyBoard(s.board);

    // 소환 위치 결정: P1은 타일 중 최하단, P2는 최상단
    final ({int r, int c}) sc;
    if (s.turn == 1) {
      sc = cells.reduce((a, b) => a.r > b.r ? a : b);
    } else {
      sc = cells.reduce((a, b) => a.r < b.r ? a : b);
    }

    for (final cell in cells) {
      final isSummon = cell.r == sc.r && cell.c == sc.c;
      newBoard[cell.r][cell.c] = BoardCell(
        type: isSummon ? BoardCellType.summon : BoardCellType.tile,
        player: s.turn,
      );
    }

    final uid = s.mUidCounter + 1;
    final mon = DdmMonster(
      uid: uid,
      id: pt.monsterId,
      player: s.turn,
      r: sc.r,
      c: sc.c,
      atk: pt.monsterAtk,
      hp: kMonsterHp,
      maxHp: kMonsterMaxHp,
      emoji: pt.monsterEmoji,
      name: pt.monsterName,
      flying: pt.monsterFlying,
    );

    final newPools = _copyPools(s.pools);
    final level = s.canSummonLevel ?? 1;
    int consumed = 0;
    for (final idx in s.selectedDice) {
      if (newPools[t][idx].level == level &&
          !newPools[t][idx].used &&
          consumed < 2) {
        newPools[t][idx] = newPools[t][idx].copyWith(used: true);
        consumed++;
      }
    }

    final newSummonCount = List<int>.from(s.summonCount);
    newSummonCount[t]++;

    var ns = s.copyWith(
      board: newBoard,
      monsters: [...s.monsters, mon],
      pools: newPools,
      mUidCounter: uid,
      summonCount: newSummonCount,
      clearCanSummonLevel: true,
      clearPlacingTile: true,
      selectedDice: const [],
      summonPanelOpen: false,
      log: [
        ...s.log,
        '★ ${pt.monsterEmoji} ${pt.monsterName} 소환!'
            ' (${sc.r + 1}행,${sc.c + 1}열) 타일 ${cells.length}칸',
      ],
    );

    // 소환 특수효과 적용
    ns = _applySummonEffect(mon, ns);
    return ns;
  }

  // ─── 소환 취소 ──────────────────────────────
  void _onCancelSummon(DdmCancelSummonEvent event, Emitter<DdmGameState> emit) {
    emit(state.copyWith(
      clearPlacingTile: true,
      summonPanelOpen: false,
    ));
  }

  // ─── 마법 크레스트 사용 ─────────────────────
  void _onUseMagic(DdmUseMagicEvent event, Emitter<DdmGameState> emit) {
    final t = state.turn - 1;
    if (state.crests[t].magic < 2) {
      emit(_addLog(state, '✕ 마법 크레스트 2개 필요!'));
      return;
    }

    final monIdx = state.monsters.indexWhere((m) => m.uid == event.monsterUid);
    if (monIdx < 0) return;

    final mon = state.monsters[monIdx];
    if (mon.player != state.turn) {
      emit(_addLog(state, '✕ 내 몬스터만 마법을 사용할 수 있습니다!'));
      return;
    }

    const heal = kMagicHeal;
    final newHp = (mon.hp + heal).clamp(0, mon.maxHp);
    final newMonsters = List<DdmMonster>.from(state.monsters);
    newMonsters[monIdx] = mon.copyWith(hp: newHp);

    final newCrests = List<DdmCrests>.from(state.crests);
    newCrests[t] =
        newCrests[t].copyWith(magic: (newCrests[t].magic - 2).clamp(0, 10));

    emit(state.copyWith(
      monsters: newMonsters,
      crests: newCrests,
      log: [...state.log, '✨ ${mon.emoji} ${mon.name} 마법! HP +$heal → $newHp'],
    ));
  }

  // ─── 트랩 설치 모드 진입 ────────────────────
  void _onStartTrapMode(
    DdmStartTrapModeEvent event,
    Emitter<DdmGameState> emit,
  ) {
    final t = state.turn - 1;
    if (state.crests[t].trap <= 0) {
      emit(_addLog(state, '✕ 트랩 크레스트가 없습니다!'));
      return;
    }

    final monSet = {
      for (final m in state.monsters) '${m.r},${m.c}',
    };
    final candidates = <({int r, int c})>[];

    for (int r = 0; r < kDdmRows; r++) {
      for (int c = 0; c < kDdmCols; c++) {
        final cell = state.board[r][c];
        if (cell != null &&
            (cell.type == BoardCellType.tile ||
                cell.type == BoardCellType.summon) &&
            cell.player == state.turn &&
            cell.trap == null &&
            !monSet.contains('$r,$c')) {
          candidates.add((r: r, c: c));
        }
      }
    }

    if (candidates.isEmpty) {
      emit(_addLog(state, '✕ 트랩을 설치할 빈 타일이 없습니다!'));
      return;
    }

    emit(state.copyWith(
      trapMode: candidates,
      log: [
        ...state.log,
        '🪤 설치할 칸을 보드에서 클릭하세요 (${candidates.length}곳)',
      ],
    ));
  }

  // ─── 트랩 모드 취소 ────────────────────────
  void _onCancelTrap(DdmCancelTrapEvent event, Emitter<DdmGameState> emit) {
    emit(state.copyWith(clearTrapMode: true));
  }

  // ─── 턴 종료 ────────────────────────────────
  Future<void> _onEndTurn(
    DdmEndTurnEvent event,
    Emitter<DdmGameState> emit,
  ) async {
    if (state.pendingBattle != null) return;
    final s = _applyEndTurn(state);
    emit(s);

    if (s.isCpuMode && s.turn == 2 && !s.gameOver) {
      await _runCpuTurn(s, emit);
    }
  }

  // ─── 턴 종료 순수 변환 ───────────────────────
  DdmGameState _applyEndTurn(DdmGameState s) {
    final newTurn = s.turn == 1 ? 2 : 1;
    final resetMonsters = s.monsters
        .map((m) => m.copyWith(hasMoved: false, hasAttacked: false))
        .toList();
    return s.copyWith(
      turn: newTurn,
      phase: DdmPhase.select,
      selectedDice: const [],
      lastRolled: const [],
      clearCanSummonLevel: true,
      rolled: false,
      clearSelectedMonster: true,
      highlights: DdmHighlights.empty,
      clearPlacingTile: true,
      clearTrapMode: true,
      summonPanelOpen: false,
      monsters: resetMonsters,
      cpuThinking: false,
      log: [...s.log, '→ PLAYER $newTurn 턴 시작 — 주사위 3개를 선택하세요'],
    );
  }

  // ─── 재시작 ─────────────────────────────────
  void _onRestart(DdmRestartEvent event, Emitter<DdmGameState> emit) {
    emit(_buildInitialState());
  }

  // ─── CPU 턴 실행 ─────────────────────────────
  Future<void> _runCpuTurn(
    DdmGameState init,
    Emitter<DdmGameState> emit,
  ) async {
    var s = init.copyWith(cpuThinking: true);
    emit(s);
    await Future.delayed(const Duration(milliseconds: 700));

    // ① 주사위 선택
    final selected = DdmCpu.selectDice(s, _rand);
    s = s.copyWith(selectedDice: selected);
    emit(s);
    await Future.delayed(const Duration(milliseconds: 500));

    // ② 주사위 굴리기
    final t = 1; // CPU = P2
    final results = selected.map((idx) {
      final die = s.pools[t][idx];
      final faces = kDiceFaces[die.level]!;
      final crest = faces[_rand.nextInt(6)];
      return DdmRollResult(idx: idx, level: die.level, crest: crest);
    }).toList();

    final summonByLevel = {1: 0, 2: 0, 3: 0};
    var newCrests = s.crests[t];
    for (final r in results) {
      if (r.crest == 'summon') {
        summonByLevel[r.level] = (summonByLevel[r.level] ?? 0) + 1;
      } else {
        switch (r.crest) {
          case 'move':
            newCrests = newCrests.copyWith(move: (newCrests.move + 1).clamp(0, 10));
          case 'attack':
            newCrests = newCrests.copyWith(atk: (newCrests.atk + 1).clamp(0, 10));
          case 'magic':
            newCrests = newCrests.copyWith(magic: (newCrests.magic + 1).clamp(0, 10));
          case 'def':
            newCrests = newCrests.copyWith(def: (newCrests.def + 1).clamp(0, 10));
          case 'trap':
            newCrests = newCrests.copyWith(trap: (newCrests.trap + 1).clamp(0, 10));
        }
      }
    }
    int? canSummonLevel;
    for (int lv = 1; lv <= 3; lv++) {
      if ((summonByLevel[lv] ?? 0) >= 2) canSummonLevel = lv;
    }
    final newCrestsList = List<DdmCrests>.from(s.crests);
    newCrestsList[t] = newCrests;
    final resStr =
        results.map((r) => 'Lv${r.level}→${_crestLabel(r.crest)}').join(' / ');

    s = s.copyWith(
      lastRolled: results,
      crests: newCrestsList,
      canSummonLevel: canSummonLevel,
      rolled: true,
      phase: DdmPhase.action,
      log: [...s.log, '🤖 CPU 🎲 $resStr'],
    );
    emit(s);
    await Future.delayed(const Duration(milliseconds: 900));

    // ③ 소환
    if (s.canSummonLevel != null && s.summonCount[t] < kMaxSummonCount) {
      final monsterId = DdmCpu.pickMonster(s);
      final level = s.canSummonLevel!;
      final shape = rollTileShape(level, _rand);
      final m = kMonsters.firstWhere((x) => x.id == monsterId);

      s = s.copyWith(
        placingTile: PlacingTileState(
          monsterId: m.id,
          monsterEmoji: m.emoji,
          monsterName: m.name,
          monsterAtk: m.atk,
          monsterFlying: m.flying,
          shape: shape,
        ),
      );
      emit(s);
      await Future.delayed(const Duration(milliseconds: 400));

      final best = _cpuPickTileAnchor(s);
      if (best != null) {
        var pt = s.placingTile!.copyWith(rot: best.rot);
        pt = _computePreview(best.r, best.c, pt, s);
        s = s.copyWith(placingTile: pt);
        emit(s);
        await Future.delayed(const Duration(milliseconds: 600));

        final confirmed = _applyConfirmTile(s);
        if (confirmed != null) {
          s = confirmed;
          s = _addLog(s, '🤖 CPU 소환 완료!');
          emit(s);
          await Future.delayed(const Duration(milliseconds: 600));
        } else {
          s = s.copyWith(clearPlacingTile: true, clearCanSummonLevel: true);
          emit(s);
        }
      } else {
        s = s.copyWith(clearPlacingTile: true, clearCanSummonLevel: true);
        emit(s);
      }
    }

    // ④ 이동 + 공격
    final myMonsters =
        s.monsters.where((m) => m.player == 2).map((m) => m.uid).toList();
    for (final uid in myMonsters) {
      if (s.gameOver) break;
      final mon = s.monsters.firstWhere(
        (m) => m.uid == uid,
        orElse: () => s.monsters.first,
      );
      if (mon.player != 2) continue;

      // 이동
      if (!mon.hasMoved && s.crests[t].move > 0) {
        final hl = _calcHighlights(mon, s);
        final target = DdmCpu.pickMoveTarget(mon, hl.move);
        if (target != null) {
          s = _moveMonster(mon, target.r, target.c, s);
          if (s.gameOver) { emit(s); return; }
          emit(s);
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // 공격
      final movedMon =
          s.monsters.firstWhere((m) => m.uid == uid, orElse: () => mon);
      if (!movedMon.hasAttacked && s.crests[t].atk > 0) {
        final hl = _calcHighlights(movedMon, s);
        final target = DdmCpu.pickAttackTarget(hl.attack, s);
        if (target != null) {
          s = _doAttack(movedMon, target.r, target.c, s);
          emit(s);
          await Future.delayed(const Duration(milliseconds: 1600));
          // CPU는 자동 확인 후 결과 적용
          if (s.pendingBattle != null) {
            s = _applyBattleResult(s);
            emit(s);
            await Future.delayed(const Duration(milliseconds: 600));
          }
          if (s.gameOver) return;
        }
      }
    }

    // ⑤ 마법 힐
    if (s.crests[t].magic >= 2) {
      final target = DdmCpu.pickMagicTarget(s);
      if (target != null) {
        final monIdx = s.monsters.indexWhere((m) => m.uid == target.uid);
        if (monIdx >= 0) {
          const heal = kMagicHeal;
          final newHp = (target.hp + heal).clamp(0, target.maxHp);
          final mons = List<DdmMonster>.from(s.monsters);
          mons[monIdx] = target.copyWith(hp: newHp);
          final nc = List<DdmCrests>.from(s.crests);
          nc[t] = nc[t].copyWith(magic: (nc[t].magic - 2).clamp(0, 10));
          s = s.copyWith(
            monsters: mons,
            crests: nc,
            log: [...s.log, '🤖 CPU ✨ ${target.emoji} HP +$heal → $newHp'],
          );
          emit(s);
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    }

    // ⑥ 턴 종료
    if (s.gameOver) return;
    await Future.delayed(const Duration(milliseconds: 400));
    emit(_applyEndTurn(s));
  }

  // CPU용 최적 타일 배치 위치 탐색 (P1 로드 방향 최대 전진)
  ({int r, int c, int rot})? _cpuPickTileAnchor(DdmGameState s) {
    final pt = s.placingTile;
    if (pt == null) return null;

    ({int r, int c, int rot})? best;
    int bestMaxR = -1;

    for (int rot = 0; rot < 4; rot++) {
      final rotatedPt = pt.copyWith(rot: rot);
      for (int r = 0; r < kDdmRows; r++) {
        for (int c = 0; c < kDdmCols; c++) {
          final computed = _computePreview(r, c, rotatedPt, s);
          if (computed.previewError == null && computed.previewAnchor != null) {
            final maxR = computed.previewCells
                .map((p) => p.r)
                .reduce((a, b) => a > b ? a : b);
            if (maxR > bestMaxR) {
              bestMaxR = maxR;
              best = (r: r, c: c, rot: rot);
            }
          }
        }
      }
    }
    return best;
  }

  // ════════════════════════════════════════════
  // 게임 로직 헬퍼
  // ════════════════════════════════════════════

  // 타일 프리뷰 계산
  PlacingTileState _computePreview(
    int r,
    int c,
    PlacingTileState pt,
    DdmGameState s,
  ) {
    final shape = rotateTile(pt.shape, pt.rot);
    final cells = shape.map((cell) => (r: r + cell[0], c: c + cell[1])).toList();

    // 유효성 검사
    String? error;
    for (final cell in cells) {
      if (cell.r < 0 || cell.r >= kDdmRows || cell.c < 0 || cell.c >= kDdmCols) {
        error = '타일이 보드 밖으로 나갑니다!';
        break;
      }
      final existing = s.board[cell.r][cell.c];
      if (existing != null && existing.type != BoardCellType.tile) {
        error = '이미 점유된 칸이 포함됩니다!';
        break;
      }
    }

    // 인접 검사 (내 타일/로드/몬스터에 인접해야 함)
    if (error == null) {
      final myTiles = <({int r, int c})>[];
      for (int rr = 0; rr < kDdmRows; rr++) {
        for (int cc = 0; cc < kDdmCols; cc++) {
          final d = s.board[rr][cc];
          if (d != null &&
              d.player == s.turn &&
              (d.type == BoardCellType.tile ||
                  d.type == BoardCellType.lord ||
                  d.type == BoardCellType.summon)) {
            myTiles.add((r: rr, c: cc));
          }
        }
      }
      for (final m in s.monsters) {
        if (m.player == s.turn) myTiles.add((r: m.r, c: m.c));
      }

      final isAdj = cells.any((cell) =>
          myTiles.any((mt) =>
              (mt.r - cell.r).abs() + (mt.c - cell.c).abs() == 1));
      if (!isAdj) error = '내 타일 또는 로드에 인접해야 합니다!';
    }

    return pt.copyWith(
      previewCells: cells,
      previewAnchor: (r: r, c: c),
      previewError: error,
      clearPreviewError: error == null,
    );
  }

  // 이동/공격 하이라이트 계산 (BFS 다단계 이동)
  DdmHighlights _calcHighlights(DdmMonster mon, DdmGameState s) {
    final t = s.turn - 1;
    final crests = s.crests[t];
    final move = <({int r, int c})>[];
    final attack = <({int r, int c})>[];

    if (!mon.hasMoved && crests.move > 0) {
      // BFS: 이동 크레스트 수만큼 다단계 이동 가능
      final visited = <String>{'${mon.r},${mon.c}'};
      final queue = <({int r, int c, int steps})>[
        (r: mon.r, c: mon.c, steps: 0),
      ];

      while (queue.isNotEmpty) {
        final curr = queue.removeAt(0);
        if (curr.steps >= crests.move) continue;

        for (final d in [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
          final nr = curr.r + d[0];
          final nc = curr.c + d[1];
          final key = '$nr,$nc';
          if (nr < 0 || nr >= kDdmRows || nc < 0 || nc >= kDdmCols) continue;
          if (visited.contains(key)) continue;

          final cell = s.board[nr][nc];
          final occupied = s.monsters.any((m) => m.r == nr && m.c == nc);
          if (occupied) continue;

          // 비행: 어디든 통과/착지 가능 / 비비행: 내 타일만 통과
          final isMyTile = cell != null &&
              (cell.type == BoardCellType.tile ||
                  cell.type == BoardCellType.summon) &&
              cell.player == s.turn;
          if (!mon.flying && !isMyTile) continue;

          visited.add(key);
          move.add((r: nr, c: nc));
          queue.add((r: nr, c: nc, steps: curr.steps + 1));
        }
      }
    }

    if (!mon.hasAttacked && crests.atk > 0) {
      for (final d in [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
        final nr = mon.r + d[0];
        final nc = mon.c + d[1];
        if (nr < 0 || nr >= kDdmRows || nc < 0 || nc >= kDdmCols) continue;
        final occ = _monsterAt(s.monsters, nr, nc, playerNot: s.turn);
        final cell = s.board[nr][nc];
        if (occ != null ||
            (cell?.type == BoardCellType.lord && cell?.player != s.turn)) {
          attack.add((r: nr, c: nc));
        }
      }
    }

    return DdmHighlights(move: move, attack: attack);
  }

  // 몬스터 이동
  DdmGameState _moveMonster(
    DdmMonster mon,
    int r,
    int c,
    DdmGameState s,
  ) {
    final t = s.turn - 1;
    final moveCost = mon.flying ? 2 : 1;
    final newCrests = List<DdmCrests>.from(s.crests);
    newCrests[t] = newCrests[t].copyWith(
      move: (newCrests[t].move - moveCost).clamp(0, 10),
    );

    final newMonsters = s.monsters.map((m) {
      if (m.uid == mon.uid) return m.copyWith(r: r, c: c, hasMoved: true);
      return m;
    }).toList();

    var ns = s.copyWith(
      monsters: newMonsters,
      crests: newCrests,
      clearSelectedMonster: true,
      highlights: DdmHighlights.empty,
      log: [...s.log, '🚶 ${mon.emoji} ${mon.name} → (${r + 1}행,${c + 1}열)'],
    );

    // 트랩 체크
    ns = _checkTrap(newMonsters.firstWhere((m) => m.uid == mon.uid), ns);

    // 이동 특수효과 적용 (게임 오버가 아닌 경우에만)
    if (!ns.gameOver) {
      final movedMon = ns.monsters.firstWhere(
        (m) => m.uid == mon.uid,
        orElse: () => mon,
      );
      ns = _applyMoveEffect(movedMon, ns);
    }

    return ns;
  }

  // 트랩 체크
  DdmGameState _checkTrap(DdmMonster mon, DdmGameState s) {
    final cell = s.board[mon.r][mon.c];
    if (cell?.trap == null || cell!.trap!.triggered) return s;
    if (cell.trap!.owner == mon.player) return s; // 내 트랩은 발동 안 함

    const dmg = kTrapDamage;
    final newHp = (mon.hp - dmg).clamp(0, mon.maxHp);
    final newBoard = _copyBoard(s.board);
    newBoard[mon.r][mon.c] = cell.copyWith(
      trap: cell.trap!.copyWith(triggered: true),
    );

    var newMonsters = s.monsters.map((m) {
      if (m.uid == mon.uid) return m.copyWith(hp: newHp);
      return m;
    }).toList();

    var ns = s.copyWith(
      board: newBoard,
      monsters: newMonsters,
      log: [
        ...s.log,
        '🪤 트랩 발동! ${mon.emoji} ${mon.name} HP -$dmg → $newHp',
      ],
    );

    if (newHp <= 0) {
      newMonsters = newMonsters.where((m) => m.uid != mon.uid).toList();
      ns = ns.copyWith(
        monsters: newMonsters,
        log: [...ns.log, '💀 ${mon.emoji} ${mon.name} 트랩에 격파!'],
      );
      ns = _checkWinByMonsters(mon.player, ns);
    }
    return ns;
  }

  // 공격 (전투 결과 계산 → pendingBattle 세팅)
  DdmGameState _doAttack(
    DdmMonster attacker,
    int r,
    int c,
    DdmGameState s,
  ) {
    final t = s.turn - 1;
    final newCrests = List<DdmCrests>.from(s.crests);
    newCrests[t] = newCrests[t].copyWith(
      atk: (newCrests[t].atk - 1).clamp(0, 10),
    );

    final newAttackers = s.monsters.map((m) {
      if (m.uid == attacker.uid) return m.copyWith(hasAttacked: true);
      return m;
    }).toList();

    var ns = s.copyWith(
      monsters: newAttackers,
      crests: newCrests,
      clearSelectedMonster: true,
      highlights: DdmHighlights.empty,
    );

    // 로드 공격: 주사위 없이 즉시 -1 HP
    final cell = s.board[r][c];
    if (cell?.type == BoardCellType.lord && cell?.player != s.turn) {
      final battle = DdmBattleResult(
        attackerUid: attacker.uid,
        attackerEmoji: attacker.emoji,
        attackerName: attacker.name,
        attackerMonsterId: attacker.id,
        attackerRoll: 0,
        attackerFinalAtk: attacker.atk,
        isLordAttack: true,
        outcome: 'lord_hit',
      );
      return ns.copyWith(pendingBattle: battle);
    }

    // 몬스터 공격: 양측 주사위 굴려 ATK 비교
    final target = _monsterAt(s.monsters, r, c, playerNot: s.turn);
    if (target == null) return ns;

    final battle = _computeBattle(attacker, target, ns);
    return ns.copyWith(pendingBattle: battle);
  }

  // 전투 계산 (양측 주사위 + 특수효과)
  DdmBattleResult _computeBattle(
    DdmMonster attacker,
    DdmMonster defender,
    DdmGameState s,
  ) {
    final t = s.turn - 1;
    final oi = 1 - t;

    // 공격자 주사위
    int aRoll = _rand.nextInt(6) + 1;
    var (aAtk, aEffect) = computeDdmCombatAtk(attacker.id, attacker.atk, aRoll);

    // slot_double: 추가 주사위 합산
    if (attacker.id == 'slot_machine') {
      final roll2 = _rand.nextInt(6) + 1;
      final sum = aRoll + roll2;
      if (sum == 12) {
        aAtk = attacker.atk * 3;
      } else if (sum == 7) {
        aAtk = attacker.atk * 2;
      } else if (sum == 2) {
        aAtk = 0;
      } else {
        aAtk = attacker.atk;
      }
      aEffect = '🎰 $aRoll+$roll2=$sum → ATK $aAtk';
    }

    // harpy_wind: 눈 4~6이면 방어자 주사위 -2
    int defRollMod = 0;
    if (attacker.id == 'harpy' && aRoll >= 4) {
      defRollMod = -2;
      aEffect = '${aEffect ?? ''}🌪️ 상대 주사위 -2';
    }

    // 방어자 주사위
    int dRoll = (_rand.nextInt(6) + 1 + defRollMod).clamp(1, 6);
    var (dAtk, dEffect) = computeDdmCombatAtk(defender.id, defender.atk, dRoll);

    // no_half (witch): 눈 5의 ATK 70% 감소 효과 무효 → 기본 ATK 유지
    if (defender.id == 'witch' && dRoll == 5) {
      dAtk = defender.atk;
      dEffect = '🧝 눈 5 감소 무효! ATK ${defender.atk}';
    }

    // skull_curse: 공격자 눈 3이면 방어자 ATK 절반
    if (attacker.id == 'summon_skull' && aRoll == 3) {
      dAtk = (dAtk / 2).floor();
      aEffect = '${aEffect ?? ''}💀 상대 ATK 절반 저주!';
    }

    // iron_wall: 전투 피해 절반 → ATK 비교 시 방어자 ATK ×2
    if (defender.id == 'warrior') {
      dAtk = dAtk * 2;
      dEffect = '${dEffect ?? ''}🛡️ 철벽 방어(ATK×2)';
    }

    String outcome;
    if (aAtk > dAtk) {
      outcome = 'attacker_wins';
    } else if (dAtk > aAtk) {
      outcome = 'defender_wins';
    } else {
      outcome = 'tie';
    }

    // 방어 크레스트: 공격자가 이기면 방어자가 한 번 재굴림
    bool usedDefCrest = false;
    if (s.crests[oi].def > 0 && outcome == 'attacker_wins') {
      final reroll = (_rand.nextInt(6) + 1 + defRollMod).clamp(1, 6);
      var (reAtk, _) = computeDdmCombatAtk(defender.id, defender.atk, reroll);
      if (defender.id == 'witch' && reroll == 5) { reAtk = defender.atk; }
      if (defender.id == 'warrior') { reAtk = reAtk * 2; }
      if (attacker.id == 'summon_skull' && aRoll == 3) {
        reAtk = (reAtk / 2).floor();
      }
      usedDefCrest = true;
      if (reAtk >= aAtk) {
        dAtk = reAtk;
        dEffect = '${dEffect ?? ''}🛡️재굴림($reroll)→$reAtk';
        outcome = reAtk > aAtk ? 'defender_wins' : 'tie';
      } else {
        dEffect = '${dEffect ?? ''}🛡️재굴림($reroll→$reAtk 실패)';
      }
    }

    return DdmBattleResult(
      attackerUid: attacker.uid,
      attackerEmoji: attacker.emoji,
      attackerName: attacker.name,
      attackerMonsterId: attacker.id,
      attackerRoll: aRoll,
      attackerFinalAtk: aAtk,
      attackerEffect: aEffect,
      isLordAttack: false,
      defenderUid: defender.uid,
      defenderEmoji: defender.emoji,
      defenderName: defender.name,
      defenderMonsterId: defender.id,
      defenderRoll: dRoll,
      defenderFinalAtk: dAtk,
      defenderEffect: dEffect,
      outcome: outcome,
      usedDefCrest: usedDefCrest,
    );
  }

  // 전투 결과 적용 (pendingBattle 소비)
  DdmGameState _applyBattleResult(DdmGameState s) {
    final battle = s.pendingBattle;
    if (battle == null) return s.copyWith(clearPendingBattle: true);

    final t = s.turn - 1;
    final oi = 1 - t;
    var ns = s.copyWith(clearPendingBattle: true);

    if (battle.isLordAttack) {
      final newLords = List<DdmLord>.from(s.lords);
      final newHp = (newLords[oi].hp - 1).clamp(0, newLords[oi].maxHp);
      newLords[oi] = newLords[oi].copyWith(hp: newHp);
      ns = ns.copyWith(
        lords: newLords,
        log: [
          ...ns.log,
          '⚔️ ${battle.attackerEmoji} → P${oi + 1} 로드 직격! ❤️-1 (남은: $newHp)',
        ],
      );
      if (newHp <= 0) {
        ns = ns.copyWith(
          gameOver: true,
          winner: s.turn,
          log: [...ns.log, '👑 PLAYER ${s.turn} 승리! 로드 격파!'],
        );
      }
      return ns;
    }

    // 방어 크레스트 소모
    if (battle.usedDefCrest) {
      final nc = List<DdmCrests>.from(ns.crests);
      nc[oi] = nc[oi].copyWith(def: (nc[oi].def - 1).clamp(0, 10));
      ns = ns.copyWith(crests: nc);
    }

    // 전투 로그
    final atkStr =
        '${battle.attackerEmoji}(🎲${battle.attackerRoll}→${battle.attackerFinalAtk})';
    final defStr =
        '${battle.defenderEmoji}(🎲${battle.defenderRoll}→${battle.defenderFinalAtk})';
    ns = _addLog(ns, '⚔️ $atkStr vs $defStr');
    if (battle.attackerEffect != null) ns = _addLog(ns, battle.attackerEffect!);
    if (battle.defenderEffect != null) ns = _addLog(ns, battle.defenderEffect!);

    switch (battle.outcome) {
      case 'attacker_wins':
        var mons =
            ns.monsters.where((m) => m.uid != battle.defenderUid).toList();
        ns = ns.copyWith(
          monsters: mons,
          log: [...ns.log, '💥 ${battle.defenderEmoji} ${battle.defenderName} 파괴!'],
        );
        ns = _checkWinByMonsters(oi + 1, ns);
      case 'defender_wins':
        var mons =
            ns.monsters.where((m) => m.uid != battle.attackerUid).toList();
        ns = ns.copyWith(
          monsters: mons,
          log: [...ns.log, '💥 ${battle.attackerEmoji} ${battle.attackerName} 역습 파괴!'],
        );
        ns = _checkWinByMonsters(s.turn, ns);
      case 'tie':
        ns = _addLog(ns, '⚖️ 무승부! 양쪽 생존');
    }

    return ns;
  }

  // 전투 확인 이벤트 핸들러
  void _onConfirmBattle(
    DdmConfirmBattleEvent event,
    Emitter<DdmGameState> emit,
  ) {
    emit(_applyBattleResult(state));
  }

  // 몬스터 파괴 후 승리 체크
  DdmGameState _checkWinByMonsters(int destroyedPlayer, DdmGameState s) {
    // 파괴된 플레이어의 남은 몬스터 수 체크
    final remaining =
        s.monsters.where((m) => m.player == destroyedPlayer).length;
    if (remaining == 0) {
      final winner = destroyedPlayer == 1 ? 2 : 1;
      return s.copyWith(
        gameOver: true,
        winner: winner,
        log: [...s.log, '👑 PLAYER $winner 승리! 모든 적 몬스터 파괴!'],
      );
    }
    return s;
  }

  // ════════════════════════════════════════
  // 몬스터 특수효과 — 소환 시
  // ════════════════════════════════════════
  DdmGameState _applySummonEffect(DdmMonster mon, DdmGameState s) {
    final t = mon.player - 1;
    final oi = 1 - t;
    final nc = List<DdmCrests>.from(s.crests);

    switch (mon.id) {
      // 🦔 소환 시: 이동 크레스트 +1
      case 'dice_armadillo':
        nc[t] = nc[t].copyWith(move: nc[t].move + 1);
        return s.copyWith(
          crests: nc,
          log: [...s.log, '🦔 소환 효과: 이동 크레스트 +1'],
        );

      // 🧙 소환 시: 마법 크레스트 +1
      case 'dark_magician':
        nc[t] = nc[t].copyWith(magic: nc[t].magic + 1);
        return s.copyWith(
          crests: nc,
          log: [...s.log, '🧙 소환 효과: 마법 크레스트 +1'],
        );

      // 😈 소환 시: 상대 이동 크레스트 -1
      case 'summon_skull':
        nc[oi] = nc[oi].copyWith(move: max(0, nc[oi].move - 1));
        return s.copyWith(
          crests: nc,
          log: [...s.log, '😈 소환 효과: 상대 이동 크레스트 -1'],
        );

      // 🛡️ 소환 시: 방어 크레스트 +1
      case 'warrior':
        nc[t] = nc[t].copyWith(def: nc[t].def + 1);
        return s.copyWith(
          crests: nc,
          log: [...s.log, '🛡️ 소환 효과: 방어 크레스트 +1'],
        );

      // 🎰 소환 시: 랜덤 크레스트(이동/공격/마법) +1
      case 'slot_machine':
        final pick = _rand.nextInt(3);
        if (pick == 0) {
          nc[t] = nc[t].copyWith(move: nc[t].move + 1);
        } else if (pick == 1) {
          nc[t] = nc[t].copyWith(atk: nc[t].atk + 1);
        } else {
          nc[t] = nc[t].copyWith(magic: nc[t].magic + 1);
        }
        final crestName = ['이동', '공격', '마법'][pick];
        return s.copyWith(
          crests: nc,
          log: [...s.log, '🎰 소환 효과: 슬롯! $crestName 크레스트 +1'],
        );

      // 🧝 소환 시: 현재 셀에 트랩 자동 설치
      case 'witch':
        final newBoard = _copyBoard(s.board);
        final cell = newBoard[mon.r][mon.c];
        if (cell != null && cell.trap == null) {
          newBoard[mon.r][mon.c] =
              cell.copyWith(trap: TrapData(owner: mon.player));
          return s.copyWith(
            board: newBoard,
            log: [...s.log, '🧝 소환 효과: 발판에 트랩 자동 설치!'],
          );
        }
        return s;

      default:
        return s;
    }
  }

  // ════════════════════════════════════════
  // 몬스터 특수효과 — 이동 후
  // ════════════════════════════════════════
  DdmGameState _applyMoveEffect(DdmMonster mon, DdmGameState s) {
    final t = mon.player - 1;
    final nc = List<DdmCrests>.from(s.crests);

    switch (mon.id) {
      // ⚔️ 이동 후: 이동 크레스트 1 회수
      case 'luck_sword':
        nc[t] = nc[t].copyWith(move: nc[t].move + 1);
        return s.copyWith(
          crests: nc,
          log: [...s.log, '⚔️ 이동 효과: 이동 크레스트 1 회수'],
        );

      // 🦅 이동 후: 인접 8방향 적 몬스터 1 HP 피해
      case 'harpy':
        return _splashDamageAdjacent(
            mon, s, 1, '🦅 이동 효과: 바람 공격! 인접 적 1 HP 피해');

      // 🐉 이동 후: 인접 8방향 적 몬스터 1 HP 피해 (불꽃)
      case 'dice_dragon':
        return _splashDamageAdjacent(
            mon, s, 1, '🐉 이동 효과: 불꽃 자국! 인접 적 1 HP 피해');

      // 🔵 이동 후: 인접 8방향 적 몬스터 ATK -300 (위압)
      case 'blue_eyes':
        return _intimidateAdjacent(
            mon, s, 300, '🔵 이동 효과: 위압! 인접 적 ATK -300');

      default:
        return s;
    }
  }

  // 인접 적 몬스터 HP 피해 헬퍼
  DdmGameState _splashDamageAdjacent(
      DdmMonster mon, DdmGameState s, int dmg, String msg) {
    final opponentPlayer = mon.player == 1 ? 2 : 1;
    var newMonsters = List<DdmMonster>.from(s.monsters);
    var logs = List<String>.from(s.log);
    final List<int> destroyedUids = [];

    for (int i = 0; i < newMonsters.length; i++) {
      final m = newMonsters[i];
      if (m.player != opponentPlayer) continue;
      final dr = (m.r - mon.r).abs();
      final dc = (m.c - mon.c).abs();
      if (dr > 1 || dc > 1) continue; // 8방향 인접
      if (dr == 0 && dc == 0) continue; // 자기 자신
      final newHp = max(0, m.hp - dmg);
      newMonsters[i] = m.copyWith(hp: newHp);
      logs.add(msg);
      if (newHp <= 0) destroyedUids.add(m.uid);
    }

    if (destroyedUids.isEmpty) {
      return s.copyWith(monsters: newMonsters, log: logs);
    }

    for (final uid in destroyedUids) {
      final m = newMonsters.firstWhere((m) => m.uid == uid);
      newMonsters.removeWhere((m) => m.uid == uid);
      logs.add('💥 ${m.emoji} ${m.name} 파괴!');
    }

    var ns = s.copyWith(monsters: newMonsters, log: logs);
    ns = _checkWinByMonsters(opponentPlayer, ns);
    return ns;
  }

  // 인접 적 몬스터 ATK 감소 헬퍼
  DdmGameState _intimidateAdjacent(
      DdmMonster mon, DdmGameState s, int reduction, String msg) {
    final opponentPlayer = mon.player == 1 ? 2 : 1;
    var newMonsters = List<DdmMonster>.from(s.monsters);
    var logs = List<String>.from(s.log);
    bool affected = false;

    for (int i = 0; i < newMonsters.length; i++) {
      final m = newMonsters[i];
      if (m.player != opponentPlayer) continue;
      final dr = (m.r - mon.r).abs();
      final dc = (m.c - mon.c).abs();
      if (dr > 1 || dc > 1) continue;
      if (dr == 0 && dc == 0) continue;
      final newAtk = max(0, m.atk - reduction);
      newMonsters[i] = m.copyWith(atk: newAtk);
      logs.add('$msg (${m.emoji} ${m.name}: ${m.atk} → $newAtk)');
      affected = true;
    }

    if (!affected) return s;
    return s.copyWith(monsters: newMonsters, log: logs);
  }
}
