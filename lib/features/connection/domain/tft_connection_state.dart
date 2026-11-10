import 'package:equatable/equatable.dart';

/// Motosiklet (CCU) bağlantı durum makinesi. Native taraftaki
/// `ConnectionPhase` ile birebir aynıdır.
enum TftConnectionPhase {
  disconnected,
  connecting,
  authenticating,
  ready,
  streaming,
  reconnecting,
  failed;

  static TftConnectionPhase fromWire(String? name) => values.firstWhere(
    (phase) => phase.name == name,
    orElse: () => TftConnectionPhase.disconnected,
  );

  bool get isLinkUp =>
      this == TftConnectionPhase.ready || this == TftConnectionPhase.streaming;

  /// Bağlantı kurulmaya çalışılıyor ya da kurulu (kullanıcı "Kes" diyebilir).
  bool get isActive =>
      this != TftConnectionPhase.disconnected &&
      this != TftConnectionPhase.failed;
}

/// Akış ölçümleri (native `StreamingMetrics.Snapshot`).
class StreamingStats extends Equatable {
  const StreamingStats({
    this.framesSent = 0,
    this.framesAcked = 0,
    this.ackTimeouts = 0,
    this.fps = 0,
    this.averageAckMs = 0,
    this.lastJpegBytes = 0,
    this.quality = 0,
  });

  factory StreamingStats.fromMap(Map<Object?, Object?> map) => StreamingStats(
    framesSent: map['framesSent'] as int? ?? 0,
    framesAcked: map['framesAcked'] as int? ?? 0,
    ackTimeouts: map['ackTimeouts'] as int? ?? 0,
    fps: (map['fps'] as num?)?.toDouble() ?? 0,
    averageAckMs: (map['averageAckMs'] as num?)?.toDouble() ?? 0,
    lastJpegBytes: map['lastJpegBytes'] as int? ?? 0,
    quality: map['quality'] as int? ?? 0,
  );

  final int framesSent;
  final int framesAcked;
  final int ackTimeouts;
  final double fps;
  final double averageAckMs;
  final int lastJpegBytes;
  final int quality;

  @override
  List<Object?> get props => [
    framesSent,
    framesAcked,
    ackTimeouts,
    fps,
    averageAckMs,
    lastJpegBytes,
    quality,
  ];
}

class TftConnectionState extends Equatable {
  const TftConnectionState({
    this.phase = TftConnectionPhase.disconnected,
    this.deviceName,
    this.errorCode,
    this.partNumber,
    this.frameWidth,
    this.frameHeight,
    this.stats,
  });

  factory TftConnectionState.fromMap(Map<Object?, Object?> map) {
    final metrics = map['metrics'];
    return TftConnectionState(
      phase: TftConnectionPhase.fromWire(map['phase'] as String?),
      deviceName: map['deviceName'] as String?,
      errorCode: map['errorCode'] as String?,
      partNumber: map['partNumber'] as String?,
      frameWidth: map['frameWidth'] as int?,
      frameHeight: map['frameHeight'] as int?,
      stats: metrics is Map ? StreamingStats.fromMap(metrics) : null,
    );
  }

  final TftConnectionPhase phase;
  final String? deviceName;

  /// Native tarafın bildirdiği makine tarafından okunabilir hata kodu.
  final String? errorCode;

  /// Göstergenin el sıkışmada bildirdiği parça numarası.
  final String? partNumber;
  final int? frameWidth;
  final int? frameHeight;
  final StreamingStats? stats;

  @override
  List<Object?> get props => [
    phase,
    deviceName,
    errorCode,
    partNumber,
    frameWidth,
    frameHeight,
    stats,
  ];
}
