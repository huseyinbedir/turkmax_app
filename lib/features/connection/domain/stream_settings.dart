import 'package:equatable/equatable.dart';

/// Motosiklete gönderilecek görüntünün kaynağı.
enum FrameSourceKind {
  /// Haritalı gerçek cockpit. Harita görünmez bir sanal ekranda çizildiği için
  /// uygulama arka plandayken de güncellenir. Google harita görüntüsünün
  /// araç ekranına aktarımı için izin doğrulanmadı; sorumluluk, kendi API
  /// anahtarını kullanan kişidedir (bkz. docs/LICENSE_AND_COMPLIANCE.md).
  cockpit,

  /// Üçüncü taraf içerik barındırmayan teşhis karesi.
  synthetic,
}

/// Bir bağlantının akış ayarları. Gerçek göstergede doğrulanmamış noktaları
/// sahada deneyebilmek için kullanıcı tarafından değiştirilebilir.
class StreamSettings extends Equatable {
  const StreamSettings({
    this.source = FrameSourceKind.cockpit,
    this.frameHeight,
    this.quality = 40,
    this.maxFps = 10,
    this.navStatusActive = false,
  });

  final FrameSourceKind source;

  /// Kare yüksekliği (234 veya 240); `null` ise göstergeye göre otomatik.
  final int? frameHeight;
  final int quality;
  final int maxFps;

  /// Kurulumda NAV_STATUS `01 00` gönder (varsayılan `00 00`).
  final bool navStatusActive;

  StreamSettings copyWith({
    FrameSourceKind? source,
    int? Function()? frameHeight,
    int? quality,
    int? maxFps,
    bool? navStatusActive,
  }) => StreamSettings(
    source: source ?? this.source,
    frameHeight: frameHeight != null ? frameHeight() : this.frameHeight,
    quality: quality ?? this.quality,
    maxFps: maxFps ?? this.maxFps,
    navStatusActive: navStatusActive ?? this.navStatusActive,
  );

  Map<String, Object?> toMap() => {
    'source': source.name,
    'frameHeight': frameHeight,
    'quality': quality,
    'maxFps': maxFps,
    'navStatusActive': navStatusActive,
  };

  @override
  List<Object?> get props => [
    source,
    frameHeight,
    quality,
    maxFps,
    navStatusActive,
  ];
}
