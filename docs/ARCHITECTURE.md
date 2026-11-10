# TurkMax — Mimari

Feature-first Clean Architecture. Flutter tarafı arayüz ve durum yönetimini, Android native
(Kotlin) tarafı Bluetooth, protokol, kare kodlama ve sistem servislerini üstlenir.

## Veri akışı

```
NavigationProvider ─┐
DeviceStatusRepo  ──┤
TftConnectionRepo ──┼─► CockpitCubit ─► CockpitState ─► CockpitView (480×234)
MediaRepository   ──┤                                         │
NotificationRepo  ──┘                                         ▼
                                              CockpitFrameSource (native kare)
                                                              │
                                              JpegFrameEncoder ─► NaviLiteCodec
                                                              │
                                              NaviLiteTransport ─► XMAX TFT
```

`CockpitView`, `CockpitState`'in saf bir fonksiyonudur ve telefondaki önizlemeyi çizer.
Göstergeye giden kare native tarafta ayrıca üretilir (bkz. "TFT karesinin üretimi").

## Üç kritik soyutlama

| Soyutlama | Yer | Uygulamalar |
|---|---|---|
| `NavigationProvider` | `lib/features/navigation/domain` | `GoogleNavigationProvider` (API anahtarı varsa); `FakeNavigationProvider` (yoksa ve testlerde) |
| `CockpitFrameSource` | Kotlin `streaming/` + Dart `features/streaming/domain` | `OffscreenCockpitFrameSource` (haritalı gerçek cockpit, ekran dışı çizim); `SyntheticFrameSource` (teşhis karesi) |
| `NaviLiteTransport` | Kotlin `bluetooth/` | `BluetoothRfcommTransport` (gerçek gösterge); `PipeTransport` + `FakeCcu` (sahte gösterge) |

Kurallar:

- UI katmanı protokol paketi üretmez. Flutter yalnızca niyet (bağlan/kes) gönderir, durum dinler.
- Bağlantı motoru (`bluetooth`, `navilite`) ile görüntü üretimi (`streaming`) birbirini tanımaz;
  ikisini `FrameStreamingEngine` birleştirir.

## Flutter katmanları

```
lib/
  main.dart
  app/            turkmax_app.dart, di/ (GetIt + Injectable), router/ (GoRouter)
  core/           design/ (token'lar, tema), l10n/ (ARB + üretilen), platform/ (kanal adları)
  features/
    navigation/     domain: NavigationProvider, NavigationState, RouteInfo, ManeuverInfo
    cockpit/        presentation: CockpitCubit, CockpitState, CockpitView, HomePage
    connection/     domain: TftConnectionRepository, TftConnectionState (7 fazlı durum makinesi)
    streaming/      domain: CockpitFrameSource, CockpitFrame
    notifications/  domain: NotificationRepository, NotificationSummary
    media/          domain: MediaRepository, MediaState
    device_status/  domain: DeviceStatusRepository, DeviceStatus
    settings/       SettingsRepository (SharedPreferences), SettingsPage
    diagnostics/    DiagnosticsRepository, DiagnosticsPage
```

Her feature `domain` / `data` / `presentation` alt klasörlerine ayrılır. `domain` saf Dart'tır.

### Bağımlılık enjeksiyonu

`configureDependencies(environment:)` iki ortam tanır:

- `kEnvDevice` — platform kanallarını kullanan uygulamalar (varsayılan).
- `kEnvFake` — native köprü gerektirmeyen sahte uygulamalar (testler).

Navigasyon sağlayıcısı ve yer araması `PlatformModule` içinde seçilir: manifestte geçerli bir
Maps anahtarı varsa (`MapsConfig.hasApiKey`) Google uygulamaları, yoksa sahte uygulamalar
kaydedilir. Medya ve bildirim için şimdilik yalnızca sahte uygulamalar vardır. Sahte kaynakların
ürettiği veriler `isSimulated: true` taşır ve cockpit'te DEMO rozetiyle etiketlenir.

## Android native katmanı

```
android/app/src/main/kotlin/com/turkmax/app/
  MainActivity.kt
  channels/       ChannelRegistry ve kanal işleyicileri
  bluetooth/      NaviLiteTransport, BluetoothRfcommTransport, PipeTransport,
                  BluetoothConnectionManager (7 fazlı durum makinesi), ConnectionRuntime
  navilite/       Crc32Mpeg2, NaviLiteCodec (+Decoder), NaviLiteSession, NaviLiteHandshake,
                  ImageChannel, CcuDeviceProfile, FakeCcu
  streaming/      CockpitFrameSource, SyntheticFrameSource, JpegFrameEncoder,
                  FrameStreamingEngine, StreamingMetrics, OffscreenMapRenderer,
                  CockpitFrameRenderer, CockpitFrameState, OffscreenCockpitFrameSource
  notifications/  TurkMaxNotificationListenerService (devre dışı iskelet)
  media/          MediaSessionMonitor (yer tutucu)
  service/        StreamingForegroundService (connectedDevice)
```

### Platform kanalları

| Kanal | Tür | İçerik | Durum |
|---|---|---|---|
| `turkmax/system` | Method | `getPlatformInfo`, `getMapsConfig`, pil optimizasyonu | Çalışıyor |
| `turkmax/device_status/events` | Event | `{batteryPercent, isCharging}` | Çalışıyor |
| `turkmax/connection` | Method | `getBondedDevices`, `connect`, `disconnect`, `startStreaming`, `stopStreaming`, `getSessionLog`, `getFakeCcuFrame` | Çalışıyor |
| `turkmax/connection/events` | Event | `{phase, deviceName, errorCode, partNumber, frameWidth, frameHeight, metrics}` | Çalışıyor |
| `turkmax/streaming` | Method | `captureSyntheticFrame`, `setCockpitState` | Çalışıyor |

### Bağlantı ve akış

```
ConnectionMethodHandler ─► BluetoothConnectionManager (kendi thread'i)
                              │  CONNECTING → AUTHENTICATING → READY ⇄ STREAMING
                              │        └── hata ──► RECONNECTING / FAILED
                              ├─ NaviLiteSession (okuyucu thread) ─ NaviLiteTransport
                              ├─ NaviLiteHandshake  (≤ 5 sn)
                              └─ FrameStreamingEngine: kare al → JPEG → gönder → ACK bekle (≤ 2 sn)
```

- Aynı anda en fazla bir onaylanmamış görüntü vardır; eski kareler kuyruğa girmez.
- ACK zaman aşımında bağlantı kapatılmaz; JPEG kalitesi düşer ve en taze kare gönderilir.
  ACK süresi normale dönünce kalite yapılandırılan değere kadar geri yükselir.
- Yeniden bağlanma yalnızca en az bir başarılı el sıkışmadan sonra ve ayar açıksa yapılır;
  artan beklemeyle dener ve 5 dakika sonra bırakır. Kullanıcının "Bağlantıyı kes" talebi her
  zaman önceliklidir.
- Gösterge içerik durdurma isteği gönderdiğinde kare gönderimi duraklar, başlatma isteğiyle
  sürer.
- Bağlantı durumu sürece bağlıdır (`ConnectionRuntime`), Flutter motoruna değil; gerçek
  Bluetooth bağlantısında `connectedDevice` türünde ön plan servisi başlatılır.
- Kare kaynağı `frameSourceFactory` ile dışarıdan verilir; bağlantı motoru karenin nasıl
  üretildiğini bilmez.

### TFT karesinin üretimi

```
Flutter: CockpitCubit ─► CockpitFramePublisher ──(setCockpitState)──► CockpitFrameState
                                                                            │
Navigation SDK oturumu ─► OffscreenMapRenderer (sanal ekran + Presentation) │
                                   │ harita bitmap'i                        ▼
                                   └──────────────► CockpitFrameRenderer (Canvas) ─► JPEG
```

- TFT'ye giden kare tümüyle native tarafta üretilir; telefon ekranına ve Flutter'ın kare
  çizmesine bağlı değildir. Bu sayede uygulama arka plandayken de güncellenir.
- Metinler Dart'ta biçimlendirilir (`CockpitFormatters`), native taraf yalnızca çizer. Saat ve
  pil native tarafta okunur.
- Telefondaki önizleme (`CockpitView`) ile TFT karesi (`CockpitFrameRenderer`) iki ayrı
  çizicidir; yerleşim ve renkler elle eşit tutulur. Biri değişirse diğeri de güncellenmelidir.

## Design system

Tek tema: Premium Dark Teal (`AppColors`). Ölçüler `AppSpacing`, `AppRadius`, `TftSpec`;
cockpit metinleri `TftTextStyles`. Cockpit yerleşimi: topbar 26 px; gövdede sol harita %66,
sağ panel %34 (yönlendirme / bildirim / medya ≈ 42 / 26 / 32).

## iOS

iOS kodu yazılmadı. Platforma özgü her şey repository/provider arayüzlerinin arkasındadır;
iOS uygulamaları aynı arayüzleri gerçekleyerek eklenebilir.
