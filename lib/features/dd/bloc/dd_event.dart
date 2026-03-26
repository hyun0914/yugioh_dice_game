abstract class DdEvent {
  const DdEvent();
}

/// 게임 초기화
class DdInitEvent extends DdEvent {
  const DdInitEvent();
}

/// 선공 결정 주사위 굴리기
class DdCoinRollEvent extends DdEvent {
  const DdCoinRollEvent();
}

/// 핸드오프 확인 (화면 넘기기 확인)
class DdHandoffConfirmEvent extends DdEvent {
  const DdHandoffConfirmEvent();
}

/// 몬스터 세트
class DdSetMonsterEvent extends DdEvent {
  final String monsterId;
  const DdSetMonsterEvent(this.monsterId);
}

/// 몬스터 제거 (변경)
class DdRemoveMonsterEvent extends DdEvent {
  const DdRemoveMonsterEvent();
}

/// 배틀 페이즈로 이동
class DdGoBattleEvent extends DdEvent {
  const DdGoBattleEvent();
}

/// 주사위 굴리기 (배틀)
class DdRollDiceEvent extends DdEvent {
  const DdRollDiceEvent();
}

/// result → preset 페이즈로 이동
class DdGoPresetEvent extends DdEvent {
  const DdGoPresetEvent();
}

/// 턴 종료 (다음 플레이어에게 넘기기)
class DdEndTurnEvent extends DdEvent {
  const DdEndTurnEvent();
}

/// 게임 재시작
class DdRestartEvent extends DdEvent {
  const DdRestartEvent();
}

/// 게임 모드 선택 (2P 대전 or CPU 대전)
class DdSetModeEvent extends DdEvent {
  final bool isCpuMode;
  const DdSetModeEvent(this.isCpuMode);
}
