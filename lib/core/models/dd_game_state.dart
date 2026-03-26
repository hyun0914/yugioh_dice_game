import 'package:equatable/equatable.dart';
import 'monster_model.dart';

// DD 게임 페이즈
enum DdPhase { set, battle, result, preset }

// 화면 모드 (모드선택 / 선공결정 / 핸드오프 / 플레이)
enum DdScreenMode { modeSelect, coinFlip, handoff, playing }

// DD 게임 전체 상태 (불변 모델)
class DdGameState extends Equatable {
  final int turn; // 1 or 2
  final DdPhase phase;
  final DdScreenMode screenMode;
  final bool firstTurn;
  final bool rolling;
  final List<int> lp; // [p1Lp, p2Lp]
  final List<MonsterModel?> monsters; // 현재 라운드 [p1, p2]
  final List<MonsterModel?> preMonsters; // 다음 라운드 예약 [p1, p2]
  final List<int> curAtk; // 계산된 ATK [p1, p2]
  final int round;
  final List<String> log; // 게임 로그
  final bool gameOver;
  final int? winner; // 1 or 2
  final List<int?> diceRolls; // [p1Roll, p2Roll] — 마지막 굴린 값
  final String resultMessage; // 결과 메시지
  final int? extraRoll; // 슬롯머신 추가 주사위
  final bool logRevealed; // 게임 종료 후 로그 공개 여부

  // 코인플립 관련
  final List<int?> coinFlipRolls; // [p1Roll, p2Roll]
  final bool coinFlipRolling;
  final String coinFlipResult; // 결과 메시지

  // 핸드오프 관련
  final String handoffTitle;
  final String handoffSub;

  // CPU 모드
  final bool isCpuMode;

  const DdGameState({
    required this.turn,
    required this.phase,
    required this.screenMode,
    required this.firstTurn,
    required this.rolling,
    required this.lp,
    required this.monsters,
    required this.preMonsters,
    required this.curAtk,
    required this.round,
    required this.log,
    required this.gameOver,
    this.winner,
    required this.diceRolls,
    required this.resultMessage,
    this.extraRoll,
    required this.logRevealed,
    required this.coinFlipRolls,
    required this.coinFlipRolling,
    required this.coinFlipResult,
    required this.handoffTitle,
    required this.handoffSub,
    this.isCpuMode = false,
  });

  factory DdGameState.initial() => const DdGameState(
        turn: 1,
        phase: DdPhase.set,
        screenMode: DdScreenMode.modeSelect,
        firstTurn: true,
        rolling: false,
        lp: [8000, 8000],
        monsters: [null, null],
        preMonsters: [null, null],
        curAtk: [0, 0],
        round: 1,
        log: [],
        gameOver: false,
        winner: null,
        diceRolls: [null, null],
        resultMessage: '몬스터를 선택하고 세트하세요.',
        extraRoll: null,
        logRevealed: false,
        coinFlipRolls: [null, null],
        coinFlipRolling: false,
        coinFlipResult: '',
        handoffTitle: '',
        handoffSub: '',
      );

  DdGameState copyWith({
    int? turn,
    DdPhase? phase,
    DdScreenMode? screenMode,
    bool? firstTurn,
    bool? rolling,
    List<int>? lp,
    List<MonsterModel?>? monsters,
    List<MonsterModel?>? preMonsters,
    List<int>? curAtk,
    int? round,
    List<String>? log,
    bool? gameOver,
    int? winner,
    List<int?>? diceRolls,
    String? resultMessage,
    int? extraRoll,
    bool? logRevealed,
    List<int?>? coinFlipRolls,
    bool? coinFlipRolling,
    String? coinFlipResult,
    String? handoffTitle,
    String? handoffSub,
    bool? isCpuMode,
    bool clearExtraRoll = false,
    bool clearWinner = false,
  }) {
    return DdGameState(
      turn: turn ?? this.turn,
      phase: phase ?? this.phase,
      screenMode: screenMode ?? this.screenMode,
      firstTurn: firstTurn ?? this.firstTurn,
      rolling: rolling ?? this.rolling,
      lp: lp ?? this.lp,
      monsters: monsters ?? this.monsters,
      preMonsters: preMonsters ?? this.preMonsters,
      curAtk: curAtk ?? this.curAtk,
      round: round ?? this.round,
      log: log ?? this.log,
      gameOver: gameOver ?? this.gameOver,
      winner: clearWinner ? null : (winner ?? this.winner),
      diceRolls: diceRolls ?? this.diceRolls,
      resultMessage: resultMessage ?? this.resultMessage,
      extraRoll: clearExtraRoll ? null : (extraRoll ?? this.extraRoll),
      logRevealed: logRevealed ?? this.logRevealed,
      coinFlipRolls: coinFlipRolls ?? this.coinFlipRolls,
      coinFlipRolling: coinFlipRolling ?? this.coinFlipRolling,
      coinFlipResult: coinFlipResult ?? this.coinFlipResult,
      handoffTitle: handoffTitle ?? this.handoffTitle,
      handoffSub: handoffSub ?? this.handoffSub,
      isCpuMode: isCpuMode ?? this.isCpuMode,
    );
  }

  @override
  List<Object?> get props => [
        turn,
        phase,
        screenMode,
        firstTurn,
        rolling,
        lp,
        monsters,
        preMonsters,
        curAtk,
        round,
        log,
        gameOver,
        winner,
        diceRolls,
        resultMessage,
        extraRoll,
        logRevealed,
        coinFlipRolls,
        coinFlipRolling,
        coinFlipResult,
        handoffTitle,
        handoffSub,
        isCpuMode,
      ];
}
