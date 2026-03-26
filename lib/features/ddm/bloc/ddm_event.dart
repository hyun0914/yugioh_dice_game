abstract class DdmEvent {
  const DdmEvent();
}

/// 게임 초기화
class DdmInitEvent extends DdmEvent {
  const DdmInitEvent();
}

/// 선공 결정 주사위 굴리기
class DdmCoinRollEvent extends DdmEvent {
  const DdmCoinRollEvent();
}

/// 주사위 선택/해제 토글
class DdmToggleDieEvent extends DdmEvent {
  final int index; // 주사위 풀 인덱스
  const DdmToggleDieEvent(this.index);
}

/// 선택한 주사위 3개 굴리기
class DdmRollDiceEvent extends DdmEvent {
  const DdmRollDiceEvent();
}

/// 소환 패널 열기 (몬스터 선택 목록 표시)
class DdmOpenSummonPanelEvent extends DdmEvent {
  const DdmOpenSummonPanelEvent();
}

/// 소환할 몬스터 선택 (타일 배치 모드 진입)
class DdmSelectMonsterForSummonEvent extends DdmEvent {
  final String monsterId;
  const DdmSelectMonsterForSummonEvent(this.monsterId);
}

/// 타일 회전 (dir: +1=우회전, -1=좌회전)
class DdmRotateTileEvent extends DdmEvent {
  final int dir;
  const DdmRotateTileEvent(this.dir);
}

/// 보드 클릭 (타일 프리뷰 / 이동 / 공격 / 트랩 설치)
class DdmCellClickEvent extends DdmEvent {
  final int r;
  final int c;
  const DdmCellClickEvent(this.r, this.c);
}

/// 타일 배치 확정 (소환)
class DdmConfirmPlaceTileEvent extends DdmEvent {
  const DdmConfirmPlaceTileEvent();
}

/// 소환 취소 (패널 닫기)
class DdmCancelSummonEvent extends DdmEvent {
  const DdmCancelSummonEvent();
}

/// 마법 크레스트 사용 (몬스터 HP +10, 마법 크레스트 2개 소모)
class DdmUseMagicEvent extends DdmEvent {
  final int monsterUid;
  const DdmUseMagicEvent(this.monsterUid);
}

/// 트랩 설치 모드 진입
class DdmStartTrapModeEvent extends DdmEvent {
  const DdmStartTrapModeEvent();
}

/// 트랩 모드 취소
class DdmCancelTrapEvent extends DdmEvent {
  const DdmCancelTrapEvent();
}

/// 턴 종료
class DdmEndTurnEvent extends DdmEvent {
  const DdmEndTurnEvent();
}

/// 게임 재시작
class DdmRestartEvent extends DdmEvent {
  const DdmRestartEvent();
}

/// 게임 모드 선택 (2P 대전 or CPU 대전)
class DdmSetModeEvent extends DdmEvent {
  final bool isCpuMode;
  const DdmSetModeEvent(this.isCpuMode);
}

/// 전투 팝업 확인 (결과 적용)
class DdmConfirmBattleEvent extends DdmEvent {
  const DdmConfirmBattleEvent();
}
