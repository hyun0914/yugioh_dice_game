import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 효과음 서비스 — WAV 프로그래매틱 생성 방식 (오디오 파일 불필요)
/// 원본 HTML의 Web Audio API 오실레이터 로직을 Dart로 재구현
class SfxService {
  static final SfxService instance = SfxService._();
  SfxService._();

  bool enabled = true;

  static const int _sr = 22050; // sample rate

  final _rand = Random();

  // 플레이어 풀 (동시 재생 지원)
  late final List<AudioPlayer> _pool = List.generate(5, (_) {
    final p = AudioPlayer();
    p.setReleaseMode(ReleaseMode.release);
    return p;
  });
  int _poolIdx = 0;

  // 캐시 (랜덤성 없는 효과음 재사용)
  final Map<String, Uint8List> _cache = {};

  // ─── 공개 효과음 API ─────────────────────────

  /// 주사위 굴리기 (매번 랜덤 주파수 — 캐시 안 함)
  void playDiceRoll() {
    if (!enabled) return;
    final tones = [
      for (int i = 0; i < 8; i++)
        (
          freq: 200.0 + _rand.nextDouble() * 400,
          wave: 'square',
          amp: 0.05,
          dur: 0.12,
          delay: i * 0.06,
        ),
    ];
    _playBytes(_mixTones(tones));
  }

  /// 몬스터 이동
  void playMove() => _playCached('move', () => _mixTones([
        (freq: 600.0, wave: 'sine', amp: 0.08, dur: 0.15, delay: 0.0),
      ]));

  /// 몬스터 소환
  void playSummon() => _playCached('summon', () => _mixTones([
        (freq: 440.0, wave: 'sine', amp: 0.10, dur: 0.25, delay: 0.00),
        (freq: 660.0, wave: 'sine', amp: 0.15, dur: 0.30, delay: 0.15),
        (freq: 880.0, wave: 'sine', amp: 0.20, dur: 0.35, delay: 0.30),
      ]));

  /// 전투 시작
  void playBattle() => _playCached('battle', () => _mixTones([
        (freq: 330.0, wave: 'sawtooth', amp: 0.05, dur: 0.35, delay: 0.00),
        (freq: 220.0, wave: 'sawtooth', amp: 0.05, dur: 0.35, delay: 0.06),
        (freq: 440.0, wave: 'square', amp: 0.08, dur: 0.28, delay: 0.12),
        (freq: 550.0, wave: 'sine', amp: 0.12, dur: 0.30, delay: 0.20),
      ]));

  /// 피해/파괴
  void playDamage() => _playCached('damage', () => _mixTones([
        (freq: 150.0, wave: 'sawtooth', amp: 0.18, dur: 0.45, delay: 0.00),
        (freq: 100.0, wave: 'square', amp: 0.22, dur: 0.35, delay: 0.10),
      ]));

  /// 승리
  void playWin() => _playCached('win', () => _mixTones([
        (freq: 523.0, wave: 'sine', amp: 0.35, dur: 0.35, delay: 0.00),
        (freq: 659.0, wave: 'sine', amp: 0.35, dur: 0.35, delay: 0.11),
        (freq: 784.0, wave: 'sine', amp: 0.35, dur: 0.35, delay: 0.22),
        (freq: 1047.0, wave: 'sine', amp: 0.35, dur: 0.35, delay: 0.33),
      ]));

  /// 마법 사용
  void playMagic() => _playCached('magic', () => _mixTones([
        (freq: 800.0, wave: 'sine', amp: 0.12, dur: 0.20, delay: 0.00),
        (freq: 1000.0, wave: 'sine', amp: 0.10, dur: 0.20, delay: 0.10),
        (freq: 1200.0, wave: 'sine', amp: 0.08, dur: 0.15, delay: 0.20),
      ]));

  /// 트랩 발동
  void playTrap() => _playCached('trap', () => _mixTones([
        (freq: 200.0, wave: 'square', amp: 0.15, dur: 0.30, delay: 0.00),
        (freq: 150.0, wave: 'sawtooth', amp: 0.20, dur: 0.35, delay: 0.08),
      ]));

  /// 주사위 결과 (레벨별 음높이)
  void playResult(int level) {
    final base = 220.0 * pow(2.0, level / 12.0);
    _playCached('result$level', () => _mixTones([
          (freq: base, wave: 'sine', amp: 0.18, dur: 0.35, delay: 0.00),
          (freq: base * 3.0, wave: 'sine', amp: 0.12, dur: 0.30, delay: 0.10),
        ]));
  }

  // ─── 내부 헬퍼 ──────────────────────────────

  void _playBytes(Uint8List wav) {
    if (!enabled) return;
    try {
      final player = _pool[_poolIdx++ % _pool.length];
      player.play(_toSource(wav));
    } catch (_) {}
  }

  void _playCached(String key, Uint8List Function() gen) {
    if (!enabled) return;
    try {
      final wav = _cache.putIfAbsent(key, gen);
      final player = _pool[_poolIdx++ % _pool.length];
      player.play(_toSource(wav));
    } catch (_) {}
  }

  Source _toSource(Uint8List wav) {
    if (kIsWeb) {
      // 웹: base64 data URI 방식
      return UrlSource('data:audio/wav;base64,${base64Encode(wav)}');
    }
    return BytesSource(wav);
  }

  // ─── WAV 생성 ────────────────────────────────

  Uint8List _mixTones(
    List<
            ({
              double freq,
              String wave,
              double amp,
              double dur,
              double delay,
            })>
        tones,
  ) {
    // 총 길이 계산
    double totalDur = 0;
    for (final t in tones) {
      final end = t.delay + t.dur;
      if (end > totalDur) totalDur = end;
    }
    final totalSamples = (totalDur * _sr).ceil();
    final buf = List<double>.filled(totalSamples, 0.0);

    // 각 톤 믹싱
    for (final tone in tones) {
      final start = (tone.delay * _sr).round();
      final len = (tone.dur * _sr).round();
      for (int i = 0; i < len; i++) {
        final idx = start + i;
        if (idx >= totalSamples) break;
        final t = i / _sr;
        final sample = _wave(tone.wave, tone.freq, t);
        // 선형 페이드아웃 envelope
        final env = max(0.0, 1.0 - (i / len));
        buf[idx] += sample * tone.amp * env;
      }
    }

    // 클리핑 방지 정규화
    final peak = buf.fold(0.0, (m, v) => max(m, v.abs()));
    final gain = peak > 0.9 ? 0.9 / peak : 1.0;
    final pcm = buf
        .map((v) => (v * gain * 32767).round().clamp(-32768, 32767))
        .toList();

    return _buildWav(pcm);
  }

  double _wave(String type, double freq, double t) {
    return switch (type) {
      'square' => sin(2 * pi * freq * t) >= 0 ? 1.0 : -1.0,
      'sawtooth' => 2.0 * (t * freq - (t * freq).floor()) - 1.0,
      _ => sin(2 * pi * freq * t), // sine (default)
    };
  }

  Uint8List _buildWav(List<int> samples) {
    final dataSize = samples.length * 2; // 16-bit mono
    final buf = ByteData(44 + dataSize);
    int o = 0;

    void ws(String s) {
      for (final c in s.codeUnits) { buf.setUint8(o++, c); }
    }
    void u16(int v) {
      buf.setUint16(o, v, Endian.little);
      o += 2;
    }
    void u32(int v) {
      buf.setUint32(o, v, Endian.little);
      o += 4;
    }

    // RIFF 헤더
    ws('RIFF'); u32(36 + dataSize); ws('WAVE');
    // fmt 청크
    ws('fmt '); u32(16); u16(1); u16(1); u32(_sr); u32(_sr * 2); u16(2); u16(16);
    // data 청크
    ws('data'); u32(dataSize);
    for (final s in samples) {
      buf.setInt16(o, s, Endian.little);
      o += 2;
    }

    return buf.buffer.asUint8List();
  }
}
