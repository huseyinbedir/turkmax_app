import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'TurkMax'**
  String get appTitle;

  /// No description provided for @homeCockpitPreview.
  ///
  /// In tr, this message translates to:
  /// **'TFT önizleme (480×234)'**
  String get homeCockpitPreview;

  /// No description provided for @homeConnectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Motosiklet bağlantısı'**
  String get homeConnectionTitle;

  /// No description provided for @homeDiagnostics.
  ///
  /// In tr, this message translates to:
  /// **'Tanılama'**
  String get homeDiagnostics;

  /// No description provided for @homeSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get homeSettings;

  /// No description provided for @demoBadge.
  ///
  /// In tr, this message translates to:
  /// **'DEMO'**
  String get demoBadge;

  /// No description provided for @demoDataNotice.
  ///
  /// In tr, this message translates to:
  /// **'Gösterilen rota, bildirim ve müzik bilgileri demo verisidir.'**
  String get demoDataNotice;

  /// No description provided for @syntheticMapLabel.
  ///
  /// In tr, this message translates to:
  /// **'SENTETİK HARİTA'**
  String get syntheticMapLabel;

  /// No description provided for @connectionDisconnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı değil'**
  String get connectionDisconnected;

  /// No description provided for @connectionConnecting.
  ///
  /// In tr, this message translates to:
  /// **'Bağlanıyor'**
  String get connectionConnecting;

  /// No description provided for @connectionAuthenticating.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanıyor'**
  String get connectionAuthenticating;

  /// No description provided for @connectionReady.
  ///
  /// In tr, this message translates to:
  /// **'Hazır'**
  String get connectionReady;

  /// No description provided for @connectionStreaming.
  ///
  /// In tr, this message translates to:
  /// **'Yayın yapılıyor'**
  String get connectionStreaming;

  /// No description provided for @connectionReconnecting.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden bağlanıyor'**
  String get connectionReconnecting;

  /// No description provided for @connectionFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı hatası'**
  String get connectionFailed;

  /// No description provided for @navIdle.
  ///
  /// In tr, this message translates to:
  /// **'Rota yok'**
  String get navIdle;

  /// No description provided for @navArrived.
  ///
  /// In tr, this message translates to:
  /// **'Varış noktasına ulaşıldı'**
  String get navArrived;

  /// No description provided for @navRerouting.
  ///
  /// In tr, this message translates to:
  /// **'Rota yeniden hesaplanıyor'**
  String get navRerouting;

  /// No description provided for @navEta.
  ///
  /// In tr, this message translates to:
  /// **'Varış {time}'**
  String navEta(String time);

  /// No description provided for @notificationsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bildirim yok'**
  String get notificationsEmpty;

  /// No description provided for @mediaEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Çalan medya yok'**
  String get mediaEmpty;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tanılama'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsPlatform.
  ///
  /// In tr, this message translates to:
  /// **'Platform'**
  String get diagnosticsPlatform;

  /// No description provided for @diagnosticsNativeBridge.
  ///
  /// In tr, this message translates to:
  /// **'Native köprü'**
  String get diagnosticsNativeBridge;

  /// No description provided for @diagnosticsNativeBridgeOk.
  ///
  /// In tr, this message translates to:
  /// **'Çalışıyor'**
  String get diagnosticsNativeBridgeOk;

  /// No description provided for @diagnosticsNativeBridgeUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Kullanılamıyor'**
  String get diagnosticsNativeBridgeUnavailable;

  /// No description provided for @diagnosticsFrameTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sentetik kare testi'**
  String get diagnosticsFrameTitle;

  /// No description provided for @diagnosticsFrameCapture.
  ///
  /// In tr, this message translates to:
  /// **'Kare üret'**
  String get diagnosticsFrameCapture;

  /// No description provided for @diagnosticsFrameInfo.
  ///
  /// In tr, this message translates to:
  /// **'{width}×{height} · {bytes} bayt · {millis} ms'**
  String diagnosticsFrameInfo(int width, int height, int bytes, String millis);

  /// No description provided for @diagnosticsFrameError.
  ///
  /// In tr, this message translates to:
  /// **'Kare üretilemedi'**
  String get diagnosticsFrameError;

  /// No description provided for @diagnosticsHardwareNotice.
  ///
  /// In tr, this message translates to:
  /// **'Gerçek motosiklet üzerinde henüz hiçbir doğrulama yapılmadı.'**
  String get diagnosticsHardwareNotice;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsAutoReconnect.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik yeniden bağlan'**
  String get settingsAutoReconnect;

  /// No description provided for @settingsAutoReconnectHint.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı koptuğunda motosiklete yeniden bağlanmayı dener.'**
  String get settingsAutoReconnectHint;

  /// No description provided for @settingsAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get settingsAbout;

  /// No description provided for @settingsAboutBody.
  ///
  /// In tr, this message translates to:
  /// **'TurkMax, Yamaha Motor veya Google ile bağlantılı değildir.'**
  String get settingsAboutBody;

  /// No description provided for @navRouting.
  ///
  /// In tr, this message translates to:
  /// **'Rota hesaplanıyor'**
  String get navRouting;

  /// No description provided for @mapUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Harita hazır değil'**
  String get mapUnavailable;

  /// No description provided for @searchHint.
  ///
  /// In tr, this message translates to:
  /// **'Adres veya işletme adı'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Varış noktasını yazın (en az 3 harf).'**
  String get searchPrompt;

  /// No description provided for @searchEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı.'**
  String get searchEmpty;

  /// No description provided for @searchFailed.
  ///
  /// In tr, this message translates to:
  /// **'Arama yapılamadı. İnternet bağlantınızı kontrol edin.'**
  String get searchFailed;

  /// No description provided for @navCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Navigasyon'**
  String get navCardTitle;

  /// No description provided for @navWhereTo.
  ///
  /// In tr, this message translates to:
  /// **'Nereye?'**
  String get navWhereTo;

  /// No description provided for @navStop.
  ///
  /// In tr, this message translates to:
  /// **'Navigasyonu bitir'**
  String get navStop;

  /// No description provided for @navRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get navRetry;

  /// No description provided for @navPreparing.
  ///
  /// In tr, this message translates to:
  /// **'Navigasyon hazırlanıyor…'**
  String get navPreparing;

  /// No description provided for @navTo.
  ///
  /// In tr, this message translates to:
  /// **'Hedef: {name}'**
  String navTo(String name);

  /// No description provided for @navRemaining.
  ///
  /// In tr, this message translates to:
  /// **'{distance} · {duration}'**
  String navRemaining(String distance, String duration);

  /// No description provided for @navSimulate.
  ///
  /// In tr, this message translates to:
  /// **'Rotayı simüle et (geliştirici)'**
  String get navSimulate;

  /// No description provided for @navSimulatedNotice.
  ///
  /// In tr, this message translates to:
  /// **'Konum simüle ediliyor; gerçek sürüş değil.'**
  String get navSimulatedNotice;

  /// No description provided for @navErrorTerms.
  ///
  /// In tr, this message translates to:
  /// **'Navigasyonu kullanmak için Google kullanım koşullarını kabul etmelisiniz.'**
  String get navErrorTerms;

  /// No description provided for @navErrorPermission.
  ///
  /// In tr, this message translates to:
  /// **'Navigasyon için konum izni gerekli.'**
  String get navErrorPermission;

  /// No description provided for @navErrorLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konumunuz belirlenemedi. Telefonun konum servisini (GPS) açıp tekrar deneyin.'**
  String get navErrorLocation;

  /// No description provided for @navErrorNetwork.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok veya rota servisi yanıt vermedi.'**
  String get navErrorNetwork;

  /// No description provided for @navErrorNoRoute.
  ///
  /// In tr, this message translates to:
  /// **'Bu hedefe rota bulunamadı.'**
  String get navErrorNoRoute;

  /// No description provided for @navErrorApiKey.
  ///
  /// In tr, this message translates to:
  /// **'Harita servisi başlatılamadı. API anahtarı ve etkin API\'ler kontrol edilmeli.'**
  String get navErrorApiKey;

  /// No description provided for @navErrorQuota.
  ///
  /// In tr, this message translates to:
  /// **'Harita kullanım kotası doldu.'**
  String get navErrorQuota;

  /// No description provided for @navErrorUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Navigasyon başlatılamadı.'**
  String get navErrorUnknown;

  /// No description provided for @demoDataNoticePartial.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim ve müzik bilgileri demo verisidir.'**
  String get demoDataNoticePartial;

  /// No description provided for @connectionDisconnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı kes'**
  String get connectionDisconnect;

  /// No description provided for @connectionConnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlan'**
  String get connectionConnect;

  /// No description provided for @connectionStartStreaming.
  ///
  /// In tr, this message translates to:
  /// **'Yayını başlat'**
  String get connectionStartStreaming;

  /// No description provided for @connectionStopStreaming.
  ///
  /// In tr, this message translates to:
  /// **'Yayını durdur'**
  String get connectionStopStreaming;

  /// No description provided for @connectionPairedDevices.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşmiş cihazlar'**
  String get connectionPairedDevices;

  /// No description provided for @connectionRefresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get connectionRefresh;

  /// No description provided for @connectionNoDevices.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşmiş cihaz yok. Motosikleti önce telefonun Bluetooth ayarlarından eşleştirin.'**
  String get connectionNoDevices;

  /// No description provided for @connectionLikelyCcu.
  ///
  /// In tr, this message translates to:
  /// **'Yamaha göstergesi olabilir'**
  String get connectionLikelyCcu;

  /// No description provided for @connectionFakeDeviceHint.
  ///
  /// In tr, this message translates to:
  /// **'Motosiklet olmadan test (geliştirici)'**
  String get connectionFakeDeviceHint;

  /// No description provided for @connectionReceiverTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sahte göstergenin aldığı görüntü'**
  String get connectionReceiverTitle;

  /// No description provided for @connectionLastDevice.
  ///
  /// In tr, this message translates to:
  /// **'Son bağlantı: {name}'**
  String connectionLastDevice(String name);

  /// No description provided for @connectionStats.
  ///
  /// In tr, this message translates to:
  /// **'{fps} FPS · ACK {ackMs} ms · kalite {quality} · {kb} KB'**
  String connectionStats(String fps, String ackMs, int quality, String kb);

  /// No description provided for @connectionFrameCounts.
  ///
  /// In tr, this message translates to:
  /// **'{acked}/{sent} kare onaylandı · {timeouts} zaman aşımı'**
  String connectionFrameCounts(int acked, int sent, int timeouts);

  /// No description provided for @connectionErrorConnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlanılamadı. Kontağın açık ve motosikletin yakında olduğundan emin olun. Garmin StreetCross veya MyRide açıksa kapatın; bağlantıyı aynı anda yalnızca bir uygulama kullanabilir.'**
  String get connectionErrorConnect;

  /// No description provided for @connectionErrorHandshakeTimeout.
  ///
  /// In tr, this message translates to:
  /// **'Gösterge yanıt vermedi. Kontağı kapatıp açın ve tekrar deneyin.'**
  String get connectionErrorHandshakeTimeout;

  /// No description provided for @connectionErrorHandshake.
  ///
  /// In tr, this message translates to:
  /// **'Gösterge ile doğrulama tamamlanamadı.'**
  String get connectionErrorHandshake;

  /// No description provided for @connectionErrorLinkLost.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı koptu.'**
  String get connectionErrorLinkLost;

  /// No description provided for @connectionErrorPermission.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth izni gerekli.'**
  String get connectionErrorPermission;

  /// No description provided for @connectionErrorBluetoothOff.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth kapalı. Açıp yenileyin.'**
  String get connectionErrorBluetoothOff;

  /// No description provided for @connectionErrorNoBluetooth.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda Bluetooth yok.'**
  String get connectionErrorNoBluetooth;

  /// No description provided for @connectionErrorUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı hatası ({code}).'**
  String connectionErrorUnknown(String code);

  /// No description provided for @connectionUnverifiedNotice.
  ///
  /// In tr, this message translates to:
  /// **'Gerçek motosiklet üzerinde henüz doğrulanmadı. Sonuçlar bağlantı günlüğüne kaydedilir.'**
  String get connectionUnverifiedNotice;

  /// No description provided for @streamSettingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yayın ayarları'**
  String get streamSettingsTitle;

  /// No description provided for @streamSettingsHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir sonraki bağlantıda geçerli olur.'**
  String get streamSettingsHint;

  /// No description provided for @streamSettingsLocked.
  ///
  /// In tr, this message translates to:
  /// **'Değiştirmek için önce bağlantıyı kesin.'**
  String get streamSettingsLocked;

  /// No description provided for @streamSettingsSource.
  ///
  /// In tr, this message translates to:
  /// **'Görüntü kaynağı'**
  String get streamSettingsSource;

  /// No description provided for @streamSettingsSourceCockpit.
  ///
  /// In tr, this message translates to:
  /// **'Cockpit (harita)'**
  String get streamSettingsSourceCockpit;

  /// No description provided for @streamSettingsSourceSynthetic.
  ///
  /// In tr, this message translates to:
  /// **'Test karesi'**
  String get streamSettingsSourceSynthetic;

  /// No description provided for @streamSettingsCockpitNotice.
  ///
  /// In tr, this message translates to:
  /// **'Harita arka planda çizilir; uygulama arka plandayken de güncellenir.'**
  String get streamSettingsCockpitNotice;

  /// No description provided for @streamSettingsResolution.
  ///
  /// In tr, this message translates to:
  /// **'Çözünürlük'**
  String get streamSettingsResolution;

  /// No description provided for @streamSettingsAuto.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik'**
  String get streamSettingsAuto;

  /// No description provided for @streamSettingsQuality.
  ///
  /// In tr, this message translates to:
  /// **'JPEG kalitesi'**
  String get streamSettingsQuality;

  /// No description provided for @streamSettingsFps.
  ///
  /// In tr, this message translates to:
  /// **'Azami FPS'**
  String get streamSettingsFps;

  /// No description provided for @streamSettingsNavStatus.
  ///
  /// In tr, this message translates to:
  /// **'NAV_STATUS etkin gönder'**
  String get streamSettingsNavStatus;

  /// No description provided for @streamSettingsNavStatusHint.
  ///
  /// In tr, this message translates to:
  /// **'Gösterge görüntü çizmiyorsa deneyin.'**
  String get streamSettingsNavStatusHint;

  /// No description provided for @powerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Pil optimizasyonu'**
  String get powerTitle;

  /// No description provided for @powerUnrestricted.
  ///
  /// In tr, this message translates to:
  /// **'Kısıtlama yok. Arka planda yayın için uygun.'**
  String get powerUnrestricted;

  /// No description provided for @powerRestricted.
  ///
  /// In tr, this message translates to:
  /// **'Sistem uygulamayı arka planda durdurabilir. Ayarları açmak için dokunun ve TurkMax için kısıtlamayı kaldırın.'**
  String get powerRestricted;

  /// No description provided for @logTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı günlüğü'**
  String get logTitle;

  /// No description provided for @logCopy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get logCopy;

  /// No description provided for @logCopied.
  ///
  /// In tr, this message translates to:
  /// **'Günlük panoya kopyalandı'**
  String get logCopied;

  /// No description provided for @logEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kayıt yok.'**
  String get logEmpty;

  /// No description provided for @logSavedTo.
  ///
  /// In tr, this message translates to:
  /// **'Dosya: {path}'**
  String logSavedTo(String path);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
