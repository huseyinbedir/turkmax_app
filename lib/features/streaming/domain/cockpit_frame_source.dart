import 'cockpit_frame.dart';

/// Kritik soyutlama 2/3: TFT'ye gönderilecek son görüntüyü sağlayan katman.
///
/// Görüntü üretimi bağlantı motorundan bağımsızdır: kaynak, karenin nereye
/// gönderileceğini bilmez. Native tarafta aynı adlı Kotlin arayüzü asıl
/// yakalama/kodlama işini yapar; bu sınıf onun Flutter'daki önizleme ve
/// tanılama görünümüdür.
///
/// Uygulamalar:
/// * `PlatformSyntheticFrameSource` — lisans riski olmayan sentetik test karesi.
/// * Haritalı gerçek cockpit native tarafta üretilir (`OffscreenCockpitFrameSource`)
///   ve bu arayüzden geçmez.
abstract interface class CockpitFrameSource {
  String get id;

  Future<CockpitFrame> captureFrame();
}
