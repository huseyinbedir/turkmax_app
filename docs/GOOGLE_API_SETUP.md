# Google API Yapılandırması

Canlı navigasyon ve adres araması için faturalandırması açık bir Google Cloud projesi ve tek bir
API anahtarı gerekir. Anahtar yoksa uygulama çevrimdışı demo sağlayıcıyla çalışır.

## Kurulum

1. Google Cloud'da proje oluşturun ve faturalandırma hesabına bağlayın.
2. **APIs & Services → Library** içinde etkinleştirin:
   - Navigation SDK
   - Maps SDK for Android
   - Places API (New)
3. **Credentials → Create credentials → API key**, ardından anahtarı kısıtlayın:
   - Application restrictions: Android apps — paket `com.turkmax.app` + imza SHA-1'i
   - API restrictions: yukarıdaki üç API listede seçili olmalı
4. Anahtarı `android/secrets.properties` dosyasına yazın (git dışıdır):
   ```
   MAPS_API_KEY=...
   ```
5. Yeniden derleyin. Anahtar derleme sırasında manifeste gömülür; dosyayı değiştirmek tek
   başına yetmez.

Debug imzasının SHA-1'i:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

Release imzası farklı bir SHA-1 üretir; yayın anahtarı oluşturulunca kısıtlamaya eklenmelidir.

## Anahtar nasıl kullanılıyor

- Manifestte `com.google.android.geo.API_KEY` (Secrets Gradle Plugin; `secrets.properties`
  yoksa `local.defaults.properties` içindeki yer tutucu kullanılır).
- Dart koduna gömülmez. Places REST çağrıları için native taraf (`SystemMethodHandler`)
  anahtarı, paket adını ve imza özetini manifestten okuyup verir; istek `X-Android-Package` ve
  `X-Android-Cert` başlıklarıyla gider, böylece Android kısıtlı anahtar REST'te de çalışır.

## Sorun giderme

| Belirti | Olası neden |
|---|---|
| Logcat: `Google Navigation SDK: Authorization failure` ve koşullar penceresi hiç açılmıyor | Anahtar reddedildi: API etkin değil, kısıtlama listesinde yok, paket/SHA-1 uyuşmuyor **veya anahtar başka bir projeye ait** |
| Places: `SERVICE_DISABLED ... in project <numara>` | Mesajdaki proje numarası anahtarın gerçek projesidir; API'leri etkinleştirdiğiniz projenin numarasıyla karşılaştırın |
| Places: `ACCESS_DENIED` | Anahtarın API kısıtlama listesinde Places API (New) yok ya da uygulama kısıtlaması uyuşmuyor |
| Harita (0,0) noktasında kalıyor / "Konumunuz belirlenemedi" | Telefonda konum servisi kapalı |

Uygulama, koşullar penceresi 12 saniye içinde sonuçlanmazsa "Harita servisi başlatılamadı"
hatasını gösterir; SDK bu durumda Dart tarafına hata bildirmediği için neden logcat'ten okunur.

## Maliyet

Navigasyon hedefleri ve Places istekleri ayrı faturalanır ve her birinin aylık ücretsiz kotası
vardır; güncel rakamlar için Google Maps Platform fiyat sayfasına bakın. Öneriler:

- Faturalandırmada bütçe uyarısı (yalnızca uyarır).
- API bazında günlük kota sınırı (harcamayı gerçekten durdurur).
- Uygulama arama isteklerini 400 ms geciktirir ve en az 3 karakter ister.
