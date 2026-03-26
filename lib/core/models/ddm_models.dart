import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════
// DDM 화면 모드
// ═══════════════════════════════════════════
enum DdmScreenMode { modeSelect, coinFlip, playing }

// ═══════════════════════════════════════════
// DDM 주사위
// ═══════════════════════════════════════════
class DdmDie extends Equatable {
  final int id;
  final int level;
  final bool used;

  const DdmDie({required this.id, required this.level, this.used = false});

  DdmDie copyWith({bool? used}) =>
      DdmDie(id: id, level: level, used: used ?? this.used);

  @override
  List<Object?> get props => [id, level, used];
}

// ═══════════════════════════════════════════
// DDM 주사위 굴린 결과
// ═══════════════════════════════════════════
class DdmRollResult extends Equatable {
  final int idx; // 주사위 풀 인덱스
  final int level;
  final String crest; // summon | move | attack | magic | def | trap

  const DdmRollResult({
    required this.idx,
    required this.level,
    required this.crest,
  });

  @override
  List<Object?> get props => [idx, level, crest];
}

// ═══════════════════════════════════════════
// DDM 크레스트 풀
// ═══════════════════════════════════════════
class DdmCrests extends Equatable {
  final int move;
  final int atk;
  final int magic;
  final int def;
  final int trap;

  const DdmCrests({
    this.move = 0,
    this.atk = 0,
    this.magic = 0,
    this.def = 0,
    this.trap = 0,
  });

  DdmCrests copyWith({int? move, int? atk, int? magic, int? def, int? trap}) {
    return DdmCrests(
      move: move ?? this.move,
      atk: atk ?? this.atk,
      magic: magic ?? this.magic,
      def: def ?? this.def,
      trap: trap ?? this.trap,
    );
  }

  @override
  List<Object?> get props => [move, atk, magic, def, trap];
}

// ═══════════════════════════════════════════
// DDM 로드 (Monster Lord)
// ═══════════════════════════════════════════
class DdmLord extends Equatable {
  final int hp;
  final int maxHp;

  const DdmLord({this.hp = 3, this.maxHp = 3});

  DdmLord copyWith({int? hp}) => DdmLord(hp: hp ?? this.hp, maxHp: maxHp);

  @override
  List<Object?> get props => [hp, maxHp];
}

// ═══════════════════════════════════════════
// DDM 보드 셀 데이터
// ═══════════════════════════════════════════
enum BoardCellType { lord, tile, summon }

class TrapData extends Equatable {
  final int owner; // 1 or 2
  final bool triggered;

  const TrapData({required this.owner, this.triggered = false});

  TrapData copyWith({bool? triggered}) =>
      TrapData(owner: owner, triggered: triggered ?? this.triggered);

  @override
  List<Object?> get props => [owner, triggered];
}

class BoardCell extends Equatable {
  final BoardCellType type;
  final int player; // 1 or 2
  final TrapData? trap;

  const BoardCell({required this.type, required this.player, this.trap});

  BoardCell copyWith({
    BoardCellType? type,
    int? player,
    TrapData? trap,
    bool clearTrap = false,
  }) {
    return BoardCell(
      type: type ?? this.type,
      player: player ?? this.player,
      trap: clearTrap ? null : (trap ?? this.trap),
    );
  }

  @override
  List<Object?> get props => [type, player, trap];
}

// ═══════════════════════════════════════════
// DDM 보드 위 몬스터
// ═══════════════════════════════════════════
class DdmMonster extends Equatable {
  final int uid;
  final String id;
  final int player;
  final int r;
  final int c;
  final int atk;
  final int hp;
  final int maxHp;
  final String emoji;
  final String name;
  final bool flying;
  final bool hasMoved;
  final bool hasAttacked;

  const DdmMonster({
    required this.uid,
    required this.id,
    required this.player,
    required this.r,
    required this.c,
    required this.atk,
    required this.hp,
    required this.maxHp,
    required this.emoji,
    required this.name,
    required this.flying,
    this.hasMoved = false,
    this.hasAttacked = false,
  });

  DdmMonster copyWith({
    int? r,
    int? c,
    int? hp,
    int? atk,
    bool? hasMoved,
    bool? hasAttacked,
  }) {
    return DdmMonster(
      uid: uid,
      id: id,
      player: player,
      r: r ?? this.r,
      c: c ?? this.c,
      atk: atk ?? this.atk,
      hp: hp ?? this.hp,
      maxHp: maxHp,
      emoji: emoji,
      name: name,
      flying: flying,
      hasMoved: hasMoved ?? this.hasMoved,
      hasAttacked: hasAttacked ?? this.hasAttacked,
    );
  }

  @override
  List<Object?> get props => [
        uid, id, player, r, c, atk, hp, maxHp,
        emoji, name, flying, hasMoved, hasAttacked,
      ];
}

// ═══════════════════════════════════════════
// DDM 타일 배치 상태
// ═══════════════════════════════════════════
class PlacingTileState extends Equatable {
  final String monsterId;
  final String monsterEmoji;
  final String monsterName;
  final int monsterAtk;
  final bool monsterFlying;
  final List<List<int>> shape; // 원본 모양 (레벨에 따라 랜덤 선택)
  final int rot; // 0~3 (0=0°, 1=90°, 2=180°, 3=270°)
  final List<({int r, int c})> previewCells;
  final ({int r, int c})? previewAnchor;
  final String? previewError;

  const PlacingTileState({
    required this.monsterId,
    required this.monsterEmoji,
    required this.monsterName,
    required this.monsterAtk,
    required this.monsterFlying,
    required this.shape,
    this.rot = 0,
    this.previewCells = const [],
    this.previewAnchor,
    this.previewError,
  });

  PlacingTileState copyWith({
    int? rot,
    List<({int r, int c})>? previewCells,
    ({int r, int c})? previewAnchor,
    String? previewError,
    bool clearPreviewAnchor = false,
    bool clearPreviewError = false,
  }) {
    return PlacingTileState(
      monsterId: monsterId,
      monsterEmoji: monsterEmoji,
      monsterName: monsterName,
      monsterAtk: monsterAtk,
      monsterFlying: monsterFlying,
      shape: shape,
      rot: rot ?? this.rot,
      previewCells: previewCells ?? this.previewCells,
      previewAnchor:
          clearPreviewAnchor ? null : (previewAnchor ?? this.previewAnchor),
      previewError:
          clearPreviewError ? null : (previewError ?? this.previewError),
    );
  }

  @override
  List<Object?> get props => [
        monsterId, monsterEmoji, monsterName, monsterAtk, monsterFlying,
        shape, rot, previewCells, previewAnchor, previewError,
      ];
}

// ═══════════════════════════════════════════
// DDM 이동/공격 하이라이트
// ═══════════════════════════════════════════
class DdmHighlights extends Equatable {
  final List<({int r, int c})> move;
  final List<({int r, int c})> attack;

  const DdmHighlights({this.move = const [], this.attack = const []});

  static const empty = DdmHighlights();

  @override
  List<Object?> get props => [move, attack];
}

// ═══════════════════════════════════════════
// DDM 전투 결과
// ═══════════════════════════════════════════
class DdmBattleResult extends Equatable {
  final int attackerUid;
  final String attackerEmoji;
  final String attackerName;
  final String attackerMonsterId;
  final int attackerRoll;
  final int attackerFinalAtk;
  final String? attackerEffect;

  final bool isLordAttack;
  final int? defenderUid;
  final String? defenderEmoji;
  final String? defenderName;
  final String? defenderMonsterId;
  final int? defenderRoll;
  final int? defenderFinalAtk;
  final String? defenderEffect;

  /// 'attacker_wins' | 'defender_wins' | 'tie' | 'lord_hit'
  final String outcome;
  final bool usedDefCrest;

  const DdmBattleResult({
    required this.attackerUid,
    required this.attackerEmoji,
    required this.attackerName,
    required this.attackerMonsterId,
    required this.attackerRoll,
    required this.attackerFinalAtk,
    this.attackerEffect,
    required this.isLordAttack,
    this.defenderUid,
    this.defenderEmoji,
    this.defenderName,
    this.defenderMonsterId,
    this.defenderRoll,
    this.defenderFinalAtk,
    this.defenderEffect,
    required this.outcome,
    this.usedDefCrest = false,
  });

  @override
  List<Object?> get props => [
        attackerUid, attackerEmoji, attackerName, attackerMonsterId,
        attackerRoll, attackerFinalAtk, attackerEffect,
        isLordAttack, defenderUid, defenderEmoji, defenderName,
        defenderMonsterId, defenderRoll, defenderFinalAtk, defenderEffect,
        outcome, usedDefCrest,
      ];
}

// ═══════════════════════════════════════════
// DDM 게임 페이즈
// ═══════════════════════════════════════════
enum DdmPhase { select, action }

// ═══════════════════════════════════════════
// DDM 전체 게임 상태
// ═══════════════════════════════════════════
class DdmGameState extends Equatable {
  final int turn; // 1 or 2
  final DdmPhase phase;
  final DdmScreenMode screenMode;

  // 코인플립
  final List<int?> coinFlipRolls;
  final bool coinFlipRolling;
  final String coinFlipResult;

  final List<DdmLord> lords; // [p1, p2]
  final List<List<DdmDie>> pools; // [p1Pool, p2Pool]
  final List<DdmCrests> crests; // [p1Crests, p2Crests]
  final List<int> summonCount; // [p1Count, p2Count]
  final List<int> selectedDice; // 현재 선택된 주사위 인덱스들
  final List<DdmRollResult> lastRolled;
  final int? canSummonLevel; // null이면 소환 불가
  final bool summonPanelOpen; // 몬스터 선택 패널 표시 여부

  final List<List<BoardCell?>> board; // [row][col]
  final List<DdmMonster> monsters;
  final DdmMonster? selectedMonster;
  final DdmHighlights highlights;
  final int mUidCounter;
  final bool rolled;
  final PlacingTileState? placingTile;
  final List<({int r, int c})>? trapMode;

  final List<String> log;
  final bool gameOver;
  final int? winner;

  final bool isCpuMode;
  final bool cpuThinking;
  final DdmBattleResult? pendingBattle;

  const DdmGameState({
    required this.turn,
    required this.phase,
    required this.screenMode,
    required this.coinFlipRolls,
    required this.coinFlipRolling,
    required this.coinFlipResult,
    required this.lords,
    required this.pools,
    required this.crests,
    required this.summonCount,
    required this.selectedDice,
    required this.lastRolled,
    this.canSummonLevel,
    required this.summonPanelOpen,
    required this.board,
    required this.monsters,
    this.selectedMonster,
    required this.highlights,
    required this.mUidCounter,
    required this.rolled,
    this.placingTile,
    this.trapMode,
    required this.log,
    required this.gameOver,
    this.winner,
    this.isCpuMode = false,
    this.cpuThinking = false,
    this.pendingBattle,
  });

  DdmGameState copyWith({
    int? turn,
    DdmPhase? phase,
    DdmScreenMode? screenMode,
    List<int?>? coinFlipRolls,
    bool? coinFlipRolling,
    String? coinFlipResult,
    List<DdmLord>? lords,
    List<List<DdmDie>>? pools,
    List<DdmCrests>? crests,
    List<int>? summonCount,
    List<int>? selectedDice,
    List<DdmRollResult>? lastRolled,
    int? canSummonLevel,
    bool? summonPanelOpen,
    List<List<BoardCell?>>? board,
    List<DdmMonster>? monsters,
    DdmMonster? selectedMonster,
    DdmHighlights? highlights,
    int? mUidCounter,
    bool? rolled,
    PlacingTileState? placingTile,
    List<({int r, int c})>? trapMode,
    List<String>? log,
    bool? gameOver,
    int? winner,
    bool? isCpuMode,
    bool? cpuThinking,
    DdmBattleResult? pendingBattle,
    bool clearCanSummonLevel = false,
    bool clearPendingBattle = false,
    bool clearSelectedMonster = false,
    bool clearPlacingTile = false,
    bool clearTrapMode = false,
    bool clearWinner = false,
  }) {
    return DdmGameState(
      turn: turn ?? this.turn,
      phase: phase ?? this.phase,
      screenMode: screenMode ?? this.screenMode,
      coinFlipRolls: coinFlipRolls ?? this.coinFlipRolls,
      coinFlipRolling: coinFlipRolling ?? this.coinFlipRolling,
      coinFlipResult: coinFlipResult ?? this.coinFlipResult,
      lords: lords ?? this.lords,
      pools: pools ?? this.pools,
      crests: crests ?? this.crests,
      summonCount: summonCount ?? this.summonCount,
      selectedDice: selectedDice ?? this.selectedDice,
      lastRolled: lastRolled ?? this.lastRolled,
      canSummonLevel:
          clearCanSummonLevel ? null : (canSummonLevel ?? this.canSummonLevel),
      summonPanelOpen: summonPanelOpen ?? this.summonPanelOpen,
      board: board ?? this.board,
      monsters: monsters ?? this.monsters,
      selectedMonster:
          clearSelectedMonster ? null : (selectedMonster ?? this.selectedMonster),
      highlights: highlights ?? this.highlights,
      mUidCounter: mUidCounter ?? this.mUidCounter,
      rolled: rolled ?? this.rolled,
      placingTile: clearPlacingTile ? null : (placingTile ?? this.placingTile),
      trapMode: clearTrapMode ? null : (trapMode ?? this.trapMode),
      log: log ?? this.log,
      gameOver: gameOver ?? this.gameOver,
      winner: clearWinner ? null : (winner ?? this.winner),
      isCpuMode: isCpuMode ?? this.isCpuMode,
      cpuThinking: cpuThinking ?? this.cpuThinking,
      pendingBattle: clearPendingBattle ? null : (pendingBattle ?? this.pendingBattle),
    );
  }

  @override
  List<Object?> get props => [
        turn, phase, screenMode,
        coinFlipRolls, coinFlipRolling, coinFlipResult,
        lords, pools, crests, summonCount,
        selectedDice, lastRolled, canSummonLevel, summonPanelOpen,
        board, monsters, selectedMonster, highlights,
        mUidCounter, rolled, placingTile, trapMode,
        log, gameOver, winner, isCpuMode, cpuThinking, pendingBattle,
      ];
}
