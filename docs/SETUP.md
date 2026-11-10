# Kurulum

TurkMax hazır derleme olarak dağıtılmaz; kendi Google Cloud anahtarınızla kendiniz derlersiniz.

## Gerekenler

- Flutter 3.44 veya üstü (geliştirme 3.47.2 ile yapıldı), Android SDK, Java 17.
- Android 7.0 (API 24) veya üstü bir telefon; Google Play Hizmetleri kurulu olmalı.
- Faturalandırması açık bir Google Cloud projesi.
- NaviLite destekleyen bir Yamaha gösterge ünitesi. Yalnızca **XMAX 250 Tech MAX 2025**
  üzerinde denendi; diğer modeller doğrulanmadı.

iOS desteklenmiyor (bkz. README).

## 1. Kaynağı alın

```bash
git clone https://github.com/huseyinbedir/turkmax_app.git
cd turkmax_app
flutter pub get
```

## 2. Google API anahtarı

Adım adım anlatım ve sorun giderme: [GOOGLE_API_SETUP.md](GOOGLE_API_SETUP.md). Özet:

1. Google Cloud'da Navigation SDK, Maps SDK for Android ve Places API (New) etkinleştirin.
2. Bir API anahtarı oluşturun; Android uygulaması olarak `com.turkmax.app` ve kendi imza
   sertifikanızın SHA-1'i ile kısıtlayın.
3. `android/secrets.properties` dosyasını oluşturun (git dışıdır):

   ```
   MAPS_API_KEY=anahtarınız
   ```

Debug imzanızın SHA-1'i:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

Anahtar olmadan da derlenir; uygulama o durumda demo navigasyon ve sentetik harita ile çalışır.

Maliyet: Google, başlatılan her rota ve adres araması için ücretlendirir; aylık ücretsiz kotalar
vardır. Bütçe uyarısı ve günlük kota sınırı koymanız önerilir.

## 3. Derleyin ve kurun

Telefonda USB hata ayıklamayı açın (Xiaomi/MIUI'de ayrıca "USB üzerinden yükle").

```bash
flutter run --release
```

ya da APK üretip kurmak için:

```bash
flutter build apk --release
```

Çıktı: `build/app/outputs/flutter-apk/app-release.apk`.

Depodaki yapılandırmada release derlemesi **debug anahtarıyla** imzalanır. Kendi telefonunuzda
kullanım için yeterlidir ve API anahtarı kısıtlamasındaki SHA-1 ile aynı sertifikadır. Derlemeyi
başkalarıyla paylaşacaksanız kendi imza anahtarınızı oluşturun, `android/app/build.gradle.kts`
içinde tanımlayın ve o anahtarın SHA-1'ini Google Cloud'daki kısıtlamaya ekleyin.

## 4. Motosikleti bağlayın

1. Motosikleti telefonun Bluetooth ayarlarından eşleştirin. İlk eşleştirmeyi Yamaha'nın kendi
   uygulamasıyla yapmanız gerekebilir. Cihaz adı `YCCU_…` biçimindedir.
2. Garmin StreetCross ve Yamaha MyRide'ı kapatın; bağlantıyı aynı anda yalnızca bir uygulama
   kullanabilir.
3. Kontağı açın, TFT'de navigasyon ekranını seçin.
4. TurkMax → **Motosiklet bağlantısı** → cihazınızın yanında **Bağlan** → **Yayını başlat**.
5. Aynı sayfadaki **Pil optimizasyonu** kartından TurkMax için kısıtlamayı kaldırın; aksi halde
   sistem arka planda uygulamayı durdurabilir.

Ayrıntılı test adımları ve sorun giderme: [FIELD_TEST.md](FIELD_TEST.md).

## Geliştirme

```bash
dart run build_runner build --delete-conflicting-outputs   # DI kodu
flutter gen-l10n                                           # çeviriler
flutter analyze
flutter test
(cd android && ./gradlew :app:testDebugUnitTest)
```

Debug derlemesinde motosiklet olmadan deneme için **Sahte CCU** bağlantısı ve rota simülasyonu
bulunur. Katkı kuralları: [CONTRIBUTING.md](../CONTRIBUTING.md).
