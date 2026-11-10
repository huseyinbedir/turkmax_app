# Katkı Kuralları

TurkMax'e katkıda bulunan herkes için proje standartları.

## Ürün kuralları

- **Tek cockpit ekranı.** Yeni dashboard modu, tema, tema galerisi, widget editörü, alternatif
  cockpit tasarımı, oyun/video/tarayıcı/mesajlaşma ekranı, araç telemetrisi (RPM, yakıt) veya
  tam telefon yansıtma modu eklenmez.
- **Tek tema:** Premium Dark Teal. Renkler yalnızca `lib/core/design/app_colors.dart` içinde
  tanımlanır; widget içinde ham renk kodu kullanılmaz.
- Hedef TFT çözünürlüğü 480×234 (`TftSpec`). Cockpit bu ölçüde, sistem yazı ölçeği kapalı çizilir.
- Dil Türkçe; her kullanıcı metni `lib/core/l10n/app_tr.arb` ve `app_en.arb` içinde bulunur.

## Dürüstlük kuralları

- Gerçek motosiklette doğrulanmamış hiçbir şey "test edildi" veya "çalışıyor" diye yazılmaz.
  Belgelerde ve kod yorumlarında `DOĞRULANMADI` etiketi kullanılır.
- Demo/test verisi kullanıcıya gerçek veri gibi gösterilmez: modellerdeki `isSimulated` alanı
  arayüzde görünür bir etikete (DEMO rozeti) dönüşmek zorundadır.
- SDK'nın sağlamadığı navigasyon bilgisi uydurulmaz.
- Yalnızca kaynağı belli protokol bilgisi kullanılır; kaynak `docs/NAVILITE_PROTOCOL.md`'dir.

## Lisans kuralları

- Pillion (PolyForm Noncommercial 1.0.0) kaynak kodu kopyalanmaz, satır satır çevrilmez.
  NaviLite kodu, `docs/NAVILITE_PROTOCOL.md`'deki olgulardan bağımsız olarak yazılır.
- Google harita görüntüsünün TFT'ye aktarımı için izin doğrulanmamıştır. Proje açık
  kaynaktır ve hazır derleme dağıtılmaz: herkes kendi Google API anahtarıyla derler ve bu
  kullanımın sorumluluğu anahtar sahibindedir. Bu durum README ve
  `docs/LICENSE_AND_COMPLIANCE.md` içinde açıkça yazılı kalmalıdır.
- Depoya API anahtarı, imza anahtarı, cihaz kimliği (Bluetooth adı/adresi, ESN) veya kişisel
  yol/hesap bilgisi girmez.
- Google haritasının zorunlu marka, atıf ve güvenlik öğelerine müdahale edilmez.
- Projeye `google_maps_flutter` gibi ikinci bir Google Maps bağımlılığı eklenmez.

## Güvenlik kuralları

- Firmware değiştirme, ECU'ya komut yazma, orijinal göstergeleri kapatma/değiştirme veya güvenlik
  sistemlerini atlatma yapılmaz. Yalnızca navigasyon görüntü alanına içerik gönderilir.
- Sürüş sırasında TFT'de klavye veya dikkat dağıtan etkileşim gösterilmez.
- Bildirim içeriği kalıcı saklanmaz, cihaz dışına gönderilmez.
- API anahtarları depoya girmez (`android/secrets.properties` git dışıdır) ve Dart koduna gömülmez.
- Harita görüntüsü saklanmaz; eşleşmiş göstergeye gönderilmesi dışında cihaz dışına çıkarılmaz.

## Mimari kuralları

- Feature-first Clean Architecture: `lib/features/<feature>/{domain,data,presentation}`.
  `domain` Flutter'a ve platform kanallarına bağımlı olamaz.
- Durum yönetimi Bloc/Cubit + Equatable; DI GetIt + Injectable (`kEnvDevice`, `kEnvFake`).
- Üç kritik soyutlama korunur: `NavigationProvider`, `CockpitFrameSource`, `NaviLiteTransport`.
- UI katmanı protokol paketi üretmez; NaviLite baytları yalnızca Kotlin `navilite` paketinde oluşur.
- Bağlantı motoru ile görüntü üretim motoru birbirini tanımaz.
- `CockpitCubit` yalnızca kompozisyon yapar; iş mantığı ilgili feature'dadır.
- Kanal adları `channel_names.dart` ve `ChannelNames.kt` içinde birlikte güncellenir.
- Bloklayan native işler (Bluetooth, JPEG kodlama) ana thread dışında çalışır.
- Platforma özgü kod arayüzlerin arkasında tutulur; iOS desteği eklenebilir kalmalıdır.

## Kod standartları

- `dart format` ve `flutter analyze` temiz olmalıdır; üretilen dosyalar elle düzenlenmez.
- Her yeni davranış testle gelir: Dart için `test/`, saf Kotlin için `android/app/src/test/`.
- Bağımlılık eklerken güncel sürüm ve proje araç zinciriyle uyum doğrulanır.
- Kod yorumları ve belgeler Türkçe; tanımlayıcılar İngilizce yazılır.

## Göndermeden önce

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
(cd android && ./gradlew :app:testDebugUnitTest)
flutter build apk --debug
```
