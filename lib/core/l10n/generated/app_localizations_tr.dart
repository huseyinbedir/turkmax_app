// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'TurkMax';

  @override
  String get homeCockpitPreview => 'TFT önizleme (480×234)';

  @override
  String get homeConnectionTitle => 'Motosiklet bağlantısı';

  @override
  String get homeDiagnostics => 'Tanılama';

  @override
  String get homeSettings => 'Ayarlar';

  @override
  String get demoBadge => 'DEMO';

  @override
  String get demoDataNotice =>
      'Gösterilen rota, bildirim ve müzik bilgileri demo verisidir.';

  @override
  String get syntheticMapLabel => 'SENTETİK HARİTA';

  @override
  String get connectionDisconnected => 'Bağlı değil';

  @override
  String get connectionConnecting => 'Bağlanıyor';

  @override
  String get connectionAuthenticating => 'Doğrulanıyor';

  @override
  String get connectionReady => 'Hazır';

  @override
  String get connectionStreaming => 'Yayın yapılıyor';

  @override
  String get connectionReconnecting => 'Yeniden bağlanıyor';

  @override
  String get connectionFailed => 'Bağlantı hatası';

  @override
  String get navIdle => 'Rota yok';

  @override
  String get navArrived => 'Varış noktasına ulaşıldı';

  @override
  String get navRerouting => 'Rota yeniden hesaplanıyor';

  @override
  String navEta(String time) {
    return 'Varış $time';
  }

  @override
  String get notificationsEmpty => 'Yeni bildirim yok';

  @override
  String get mediaEmpty => 'Çalan medya yok';

  @override
  String get diagnosticsTitle => 'Tanılama';

  @override
  String get diagnosticsPlatform => 'Platform';

  @override
  String get diagnosticsNativeBridge => 'Native köprü';

  @override
  String get diagnosticsNativeBridgeOk => 'Çalışıyor';

  @override
  String get diagnosticsNativeBridgeUnavailable => 'Kullanılamıyor';

  @override
  String get diagnosticsFrameTitle => 'Sentetik kare testi';

  @override
  String get diagnosticsFrameCapture => 'Kare üret';

  @override
  String diagnosticsFrameInfo(int width, int height, int bytes, String millis) {
    return '$width×$height · $bytes bayt · $millis ms';
  }

  @override
  String get diagnosticsFrameError => 'Kare üretilemedi';

  @override
  String get diagnosticsHardwareNotice =>
      'Gerçek motosiklet üzerinde henüz hiçbir doğrulama yapılmadı.';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsAutoReconnect => 'Otomatik yeniden bağlan';

  @override
  String get settingsAutoReconnectHint =>
      'Bağlantı koptuğunda motosiklete yeniden bağlanmayı dener.';

  @override
  String get settingsAbout => 'Hakkında';

  @override
  String get settingsAboutBody =>
      'TurkMax, Yamaha Motor veya Google ile bağlantılı değildir.';

  @override
  String get navRouting => 'Rota hesaplanıyor';

  @override
  String get mapUnavailable => 'Harita hazır değil';

  @override
  String get searchHint => 'Adres veya işletme adı';

  @override
  String get searchPrompt => 'Varış noktasını yazın (en az 3 harf).';

  @override
  String get searchEmpty => 'Sonuç bulunamadı.';

  @override
  String get searchFailed =>
      'Arama yapılamadı. İnternet bağlantınızı kontrol edin.';

  @override
  String get navCardTitle => 'Navigasyon';

  @override
  String get navWhereTo => 'Nereye?';

  @override
  String get navStop => 'Navigasyonu bitir';

  @override
  String get navRetry => 'Tekrar dene';

  @override
  String get navPreparing => 'Navigasyon hazırlanıyor…';

  @override
  String navTo(String name) {
    return 'Hedef: $name';
  }

  @override
  String navRemaining(String distance, String duration) {
    return '$distance · $duration';
  }

  @override
  String get navSimulate => 'Rotayı simüle et (geliştirici)';

  @override
  String get navSimulatedNotice => 'Konum simüle ediliyor; gerçek sürüş değil.';

  @override
  String get navErrorTerms =>
      'Navigasyonu kullanmak için Google kullanım koşullarını kabul etmelisiniz.';

  @override
  String get navErrorPermission => 'Navigasyon için konum izni gerekli.';

  @override
  String get navErrorLocation =>
      'Konumunuz belirlenemedi. Telefonun konum servisini (GPS) açıp tekrar deneyin.';

  @override
  String get navErrorNetwork =>
      'İnternet bağlantısı yok veya rota servisi yanıt vermedi.';

  @override
  String get navErrorNoRoute => 'Bu hedefe rota bulunamadı.';

  @override
  String get navErrorApiKey =>
      'Harita servisi başlatılamadı. API anahtarı ve etkin API\'ler kontrol edilmeli.';

  @override
  String get navErrorQuota => 'Harita kullanım kotası doldu.';

  @override
  String get navErrorUnknown => 'Navigasyon başlatılamadı.';

  @override
  String get demoDataNoticePartial =>
      'Bildirim ve müzik bilgileri demo verisidir.';

  @override
  String get connectionDisconnect => 'Bağlantıyı kes';

  @override
  String get connectionConnect => 'Bağlan';

  @override
  String get connectionStartStreaming => 'Yayını başlat';

  @override
  String get connectionStopStreaming => 'Yayını durdur';

  @override
  String get connectionPairedDevices => 'Eşleşmiş cihazlar';

  @override
  String get connectionRefresh => 'Yenile';

  @override
  String get connectionNoDevices =>
      'Eşleşmiş cihaz yok. Motosikleti önce telefonun Bluetooth ayarlarından eşleştirin.';

  @override
  String get connectionLikelyCcu => 'Yamaha göstergesi olabilir';

  @override
  String get connectionFakeDeviceHint =>
      'Motosiklet olmadan test (geliştirici)';

  @override
  String get connectionReceiverTitle => 'Sahte göstergenin aldığı görüntü';

  @override
  String connectionLastDevice(String name) {
    return 'Son bağlantı: $name';
  }

  @override
  String connectionStats(String fps, String ackMs, int quality, String kb) {
    return '$fps FPS · ACK $ackMs ms · kalite $quality · $kb KB';
  }

  @override
  String connectionFrameCounts(int acked, int sent, int timeouts) {
    return '$acked/$sent kare onaylandı · $timeouts zaman aşımı';
  }

  @override
  String get connectionErrorConnect =>
      'Bağlanılamadı. Kontağın açık ve motosikletin yakında olduğundan emin olun. Garmin StreetCross veya MyRide açıksa kapatın; bağlantıyı aynı anda yalnızca bir uygulama kullanabilir.';

  @override
  String get connectionErrorHandshakeTimeout =>
      'Gösterge yanıt vermedi. Kontağı kapatıp açın ve tekrar deneyin.';

  @override
  String get connectionErrorHandshake =>
      'Gösterge ile doğrulama tamamlanamadı.';

  @override
  String get connectionErrorLinkLost => 'Bağlantı koptu.';

  @override
  String get connectionErrorPermission => 'Bluetooth izni gerekli.';

  @override
  String get connectionErrorBluetoothOff => 'Bluetooth kapalı. Açıp yenileyin.';

  @override
  String get connectionErrorNoBluetooth => 'Bu cihazda Bluetooth yok.';

  @override
  String connectionErrorUnknown(String code) {
    return 'Bağlantı hatası ($code).';
  }

  @override
  String get connectionUnverifiedNotice =>
      'Gerçek motosiklet üzerinde henüz doğrulanmadı. Sonuçlar bağlantı günlüğüne kaydedilir.';

  @override
  String get streamSettingsTitle => 'Yayın ayarları';

  @override
  String get streamSettingsHint => 'Bir sonraki bağlantıda geçerli olur.';

  @override
  String get streamSettingsLocked => 'Değiştirmek için önce bağlantıyı kesin.';

  @override
  String get streamSettingsSource => 'Görüntü kaynağı';

  @override
  String get streamSettingsSourceCockpit => 'Cockpit (harita)';

  @override
  String get streamSettingsSourceSynthetic => 'Test karesi';

  @override
  String get streamSettingsCockpitNotice =>
      'Harita arka planda çizilir; uygulama arka plandayken de güncellenir.';

  @override
  String get streamSettingsResolution => 'Çözünürlük';

  @override
  String get streamSettingsAuto => 'Otomatik';

  @override
  String get streamSettingsQuality => 'JPEG kalitesi';

  @override
  String get streamSettingsFps => 'Azami FPS';

  @override
  String get streamSettingsNavStatus => 'NAV_STATUS etkin gönder';

  @override
  String get streamSettingsNavStatusHint =>
      'Gösterge görüntü çizmiyorsa deneyin.';

  @override
  String get powerTitle => 'Pil optimizasyonu';

  @override
  String get powerUnrestricted =>
      'Kısıtlama yok. Arka planda yayın için uygun.';

  @override
  String get powerRestricted =>
      'Sistem uygulamayı arka planda durdurabilir. Ayarları açmak için dokunun ve TurkMax için kısıtlamayı kaldırın.';

  @override
  String get logTitle => 'Bağlantı günlüğü';

  @override
  String get logCopy => 'Kopyala';

  @override
  String get logCopied => 'Günlük panoya kopyalandı';

  @override
  String get logEmpty => 'Henüz kayıt yok.';

  @override
  String logSavedTo(String path) {
    return 'Dosya: $path';
  }
}
