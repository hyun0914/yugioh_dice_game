import 'dart:math';
import '../../../core/constants/game_constants.dart';
import '../../../core/models/ddm_models.dart';

/// CPU(P2) 행동 결정 — 순수 함수들만 포함 (BLoC 내부 메서드 불필요)
class DdmCpu {
  // ─── 주사위 선택 ─────────────────────────────
  /// 미사용 주사위 중 레벨 높은 것 우선 3개 선택
  static List<int> selectDice(DdmGameState s, Random rand) {
    final pool = s.pools[1]; // CPU = P2 (index 1)
    final selected = <int>[];

    // 레벨 3 → 2 → 1 순서로 최대 3개
    for (final lv in [3, 2, 1]) {
      for (int i = 0; i < pool.length && selected.length < 3; i++) {
        if (!pool[i].used && pool[i].level == lv) selected.add(i);
      }
      if (selected.length >= 3) break;
    }
    // 부족하면 남은 미사용 주사위로 보충
    for (int i = 0; i < pool.length && selected.length < 3; i++) {
      if (!pool[i].used && !selected.contains(i)) selected.add(i);
    }

    selected.shuffle(rand); // 연출용 순서 섞기
    return selected;
  }

  // ─── 소환 몬스터 선택 ─────────────────────────
  /// 해당 레벨에서 소환 가능한 몬스터 중 ATK 가장 높은 것
  static String pickMonster(DdmGameState s) {
    final level = s.canSummonLevel ?? 1;
    final available = kMonsters.where((m) {
      if (level == 1) return m.tags.contains('ts');
      if (level == 2) return m.tags.contains('td') || m.tags.contains('ts');
      return true;
    }).toList()
      ..sort((a, b) => b.atk - a.atk);
    return available.isNotEmpty ? available.first.id : kMonsters.first.id;
  }

  // ─── 이동 목표 선택 ──────────────────────────
  /// 이동 후보 중 P1 로드(row 18, col 6)에 가장 가까운 칸
  static ({int r, int c})? pickMoveTarget(
    DdmMonster monster,
    List<({int r, int c})> moveHL,
  ) {
    if (moveHL.isEmpty) return null;

    ({int r, int c}) best = moveHL.first;
    int bestDist = _distToP1Lord(best.r, best.c);

    for (final h in moveHL) {
      final d = _distToP1Lord(h.r, h.c);
      if (d < bestDist) {
        bestDist = d;
        best = h;
      }
    }
    return best;
  }

  // ─── 공격 목표 선택 ──────────────────────────
  /// 우선순위: P1 로드 > HP 낮은 몬스터 > 아무 적
  static ({int r, int c})? pickAttackTarget(
    List<({int r, int c})> attackHL,
    DdmGameState s,
  ) {
    if (attackHL.isEmpty) return null;

    ({int r, int c})? lordPos;
    ({int r, int c})? weakPos;
    int weakestHp = 9999;

    for (final h in attackHL) {
      final cell = s.board[h.r][h.c];
      if (cell?.type == BoardCellType.lord && cell?.player == 1) {
        lordPos = h;
        break; // 로드 발견 즉시 최우선
      }
      final enemy = _monsterAt(s.monsters, h.r, h.c);
      if (enemy != null && enemy.hp < weakestHp) {
        weakestHp = enemy.hp;
        weakPos = h;
      }
    }

    return lordPos ?? weakPos ?? attackHL.first;
  }

  // ─── 마법 힐 대상 ────────────────────────────
  /// HP가 가장 낮은 내 몬스터 (풀이 아닐 때만)
  static DdmMonster? pickMagicTarget(DdmGameState s) {
    final mine = s.monsters.where((m) => m.player == 2).toList();
    if (mine.isEmpty) return null;
    mine.sort((a, b) => a.hp - b.hp);
    final lowest = mine.first;
    return lowest.hp < lowest.maxHp ? lowest : null;
  }

  // ─── 유틸 ────────────────────────────────────
  static int _distToP1Lord(int r, int c) =>
      (kLord1Row - r).abs() + (kLordCol - c).abs();

  static DdmMonster? _monsterAt(List<DdmMonster> monsters, int r, int c) {
    for (final m in monsters) {
      if (m.r == r && m.c == c) return m;
    }
    return null;
  }
}
