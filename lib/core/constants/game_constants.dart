import 'dart:math';
import '../models/monster_model.dart';

// ═══════════════════════════════════════════
// 몬스터 목록
// ═══════════════════════════════════════════
final List<MonsterModel> kMonsters = [
  const MonsterModel(
    id: 'luck_sword',
    name: '행운의 철검전사',
    atk: 1000,
    type: '전사족',
    emoji: '⚔️',
    special: 'lucky_sword',
    flying: false,
    effect: '눈 6: ATK×2 + 상대 LP 직접 -400. 리스크 낮고 보너스 강력.',
    tags: ['ts'],
  ),
  const MonsterModel(
    id: 'dice_armadillo',
    name: '다이스키 아르마딜로',
    atk: 800,
    type: '동물족',
    emoji: '🦔',
    special: 'dice_multiply',
    flying: false,
    effect: 'ATK = 주사위 눈 × 200 (200~1200). 평균 기대값 700.',
    tags: ['td', 'ts'],
  ),
  const MonsterModel(
    id: 'dice_dragon',
    name: '다이스키 드래곤',
    atk: 1500,
    type: '드래곤족',
    emoji: '🐉',
    special: 'dragon_ace',
    flying: true,
    effect: '눈 6→ATK 3000 / 눈 1→ATK 0. 고위험 고수익. 비행.',
    tags: ['td', 'ts'],
  ),
  const MonsterModel(
    id: 'blue_eyes',
    name: '청안의 백룡',
    atk: 3000,
    type: '드래곤족',
    emoji: '🔵',
    special: 'blue_shield',
    flying: true,
    effect: '원작 ATK 3000. 눈 1~2도 최소 1500 보장. 비행.',
    tags: ['ts'],
  ),
  const MonsterModel(
    id: 'dark_magician',
    name: '블랙 매지션',
    atk: 2500,
    type: '마법사족',
    emoji: '🧙',
    special: 'mage_bonus',
    flying: false,
    effect: '눈 2·3·4 → ATK +300. 눈 1: ATK 250.',
    tags: ['ts'],
  ),
  const MonsterModel(
    id: 'summon_skull',
    name: '데몬의 소환',
    atk: 2500,
    type: '악마족',
    emoji: '😈',
    special: 'skull_curse',
    flying: true,
    effect: '눈 3: 상대 ATK 절반으로 저주. 눈 1: ATK 250. 비행.',
    tags: ['ts'],
  ),
  const MonsterModel(
    id: 'slot_machine',
    name: '슬롯 머신',
    atk: 1800,
    type: '기계족',
    emoji: '🎰',
    special: 'slot_double',
    flying: false,
    effect: '추가 주사위 1개. 합 12→ATK×3 / 합 7→ATK×2 / 합 2→ATK 0.',
    tags: ['td', 'ts'],
  ),
  const MonsterModel(
    id: 'witch',
    name: '마계의 족쇄사',
    atk: 600,
    type: '마법사족',
    emoji: '🧝',
    special: 'no_half',
    flying: false,
    effect: '눈 5(ATK 70%감소)를 완전 무효. 저ATK지만 안정적.',
    tags: ['ts'],
  ),
  const MonsterModel(
    id: 'harpy',
    name: '하피 레이디',
    atk: 1300,
    type: '조류족',
    emoji: '🦅',
    special: 'harpy_wind',
    flying: true,
    effect: '눈 4~6: 상대 주사위 -2 감소(최소 1). 방해+비행 복합형.',
    tags: ['ts'],
  ),
  const MonsterModel(
    id: 'warrior',
    name: '철갑전사',
    atk: 1200,
    type: '전사족',
    emoji: '🛡️',
    special: 'iron_wall',
    flying: false,
    effect: '원작 ATK 1200. 받는 전투 피해 절반. 생존력 최고.',
    tags: ['ts'],
  ),
];

// ═══════════════════════════════════════════
// DDM 보드 크기
// ═══════════════════════════════════════════
const int kDdmCols = 13;
const int kDdmRows = 11; // 19 → 11 (빠른 전투)

// Lord 위치: P1은 보드 맨 아래(행 index=10), P2는 맨 위(행 index=0) 중앙
const int kLord1Row = kDdmRows - 1; // 10
const int kLord2Row = 0;
const int kLordCol = kDdmCols ~/ 2; // 6

// ═══════════════════════════════════════════
// DDM 주사위 면 구성 (레벨별)
// ═══════════════════════════════════════════
const Map<int, List<String>> kDiceFaces = {
  1: ['summon', 'summon', 'summon', 'summon', 'move', 'def'],
  2: ['summon', 'summon', 'summon', 'move', 'attack', 'def'],
  3: ['summon', 'summon', 'move', 'attack', 'magic', 'trap'],
};

// 레벨별 타일 칸 수
const Map<int, int> kTileCount = {1: 2, 2: 4, 3: 6};

// ═══════════════════════════════════════════
// 타일 모양 (레벨별)
// ═══════════════════════════════════════════
const Map<int, List<List<List<int>>>> kTileShapesByLevel = {
  1: [
    [[0, 0], [0, 1]], // 가로
    [[0, 0], [1, 0]], // 세로
  ],
  2: [
    [[0, 0], [0, 1], [0, 2], [0, 3]], // 일자 가로
    [[0, 0], [1, 0], [2, 0], [3, 0]], // 일자 세로
    [[0, 0], [0, 1], [1, 0], [1, 1]], // 정사각
    [[0, 0], [0, 1], [0, 2], [1, 0]], // L자
    [[0, 0], [0, 1], [0, 2], [1, 2]], // J자
    [[0, 0], [0, 1], [1, 1], [1, 2]], // S자
    [[0, 0], [1, 0], [1, 1], [1, 2]], // T자 변형
    [[0, 0], [0, 1], [0, 2], [1, 1]], // T자
  ],
  3: [
    [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4], [0, 5]], // 일자 6칸
    [[0, 0], [1, 0], [2, 0], [0, 1], [1, 1], [2, 1]], // 2×3 블록
    [[0, 0], [0, 1], [0, 2], [1, 2], [2, 2], [2, 1]], // L자 6칸
    [[0, 0], [0, 1], [0, 2], [0, 3], [1, 3], [1, 2]], // S자 6칸
    [[0, 0], [1, 0], [2, 0], [0, 1], [0, 2], [0, 3]], // T자 6칸
    [[0, 0], [0, 1], [0, 2], [0, 3], [1, 1], [1, 2]], // U자
    [[0, 0], [1, 0], [2, 0], [2, 1], [1, 1], [0, 1]], // 직사각
    [[0, 0], [0, 1], [1, 1], [1, 2], [2, 2], [2, 3]], // 계단
  ],
};

// ═══════════════════════════════════════════
// DD 기본 주사위 룰 적용
// ═══════════════════════════════════════════
int ddBaseRule(int baseAtk, int roll) {
  switch (roll) {
    case 1:
      return (baseAtk * 0.1).floor();
    case 2:
      return (baseAtk * 0.5).floor();
    case 3:
      return baseAtk;
    case 4:
      return baseAtk + (baseAtk * 0.2).floor();
    case 5:
      return (baseAtk * 0.7).floor();
    case 6:
      return baseAtk + (baseAtk * 0.5).floor();
    default:
      return baseAtk;
  }
}

// ═══════════════════════════════════════════
// 타일 회전 로직
// ═══════════════════════════════════════════
List<List<int>> rotateTile(List<List<int>> shape, int rot) {
  final rotated = shape.map((cell) {
    final dr = cell[0];
    final dc = cell[1];
    if (rot == 0) return [dr, dc];
    if (rot == 1) return [dc, -dr];
    if (rot == 2) return [-dr, -dc];
    return [-dc, dr];
  }).toList();

  final minR = rotated.map((c) => c[0]).reduce((a, b) => a < b ? a : b);
  final minC = rotated.map((c) => c[1]).reduce((a, b) => a < b ? a : b);

  final normalized = rotated
      .map((c) => [c[0] - minR, c[1] - minC])
      .toList();

  normalized.sort((a, b) => a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);
  return normalized;
}

// ═══════════════════════════════════════════
// DDM 전투 ATK 계산 (특수효과 포함)
// ═══════════════════════════════════════════
/// ddBaseRule + 몬스터 특수효과 적용
/// Returns (finalAtk, effectMessage)
(int, String?) computeDdmCombatAtk(String monsterId, int baseAtk, int roll) {
  int atk = ddBaseRule(baseAtk, roll);
  String? msg;

  switch (monsterId) {
    case 'luck_sword': // special: lucky_sword
      if (roll == 6) {
        atk = baseAtk * 2;
        msg = '★ 눈 6! ATK ×2';
      }
    case 'dice_armadillo': // special: dice_multiply
      atk = roll * 200;
      msg = '🎲 × 200 = $atk';
    case 'dice_dragon': // special: dragon_ace
      if (roll == 6) {
        atk = 3000;
        msg = '🔥 눈 6! ATK 3000!!';
      } else if (roll == 1) {
        atk = 0;
        msg = '💀 눈 1... ATK 0';
      }
    case 'blue_eyes': // special: blue_shield
      if (atk < 1500) {
        atk = 1500;
        msg = '🔵 최소 1500 보장';
      }
    case 'dark_magician': // special: mage_bonus
      if (roll == 1) {
        atk = 250;
        msg = '🧙 눈 1 → ATK 250';
      } else if (roll >= 2 && roll <= 4) {
        atk += 300;
        msg = '🧙 눈 $roll ATK +300';
      }
    case 'slot_machine': // special: slot_double — 호출 측에서 별도 처리
      break;
  }
  return (atk, msg);
}

// ═══════════════════════════════════════════
// 타일 모양 랜덤 선택 (레벨별)
// ═══════════════════════════════════════════
List<List<int>> rollTileShape(int level, Random rand) {
  final shapes = kTileShapesByLevel[level]!;
  final picked = shapes[rand.nextInt(shapes.length)];
  return picked.map((cell) => List<int>.from(cell)).toList();
}

// ═══════════════════════════════════════════
// DDM 주사위 풀 (각 플레이어 15개: Lv1×5, Lv2×5, Lv3×5)
// ═══════════════════════════════════════════
const int kMaxSummonCount = 10;
const int kLordMaxHp = 3;
const int kMonsterHp = 10; // 30 → 10 (트랩/마법 스케일 조정)
const int kMonsterMaxHp = 10;
const int kTrapDamage = 3; // 트랩 피해
const int kMagicHeal = 4; // 마법 회복
const int kInitialLp = 8000;
const int kDicePoolCount = 15; // 각 플레이어 주사위 수
