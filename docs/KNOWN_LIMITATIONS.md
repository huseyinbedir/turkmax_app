# Bilinen Sınırlamalar

## Doğrulama kapsamı

- Yalnızca tek bir motosiklette (XMAX 250 Tech MAX 2025), motosiklet dururken ve kısa süreli
  denendi. 480×234 profili gösterge parça numarasının `006-B3952` önekine dayanıyor; başka
  modeller doğrulanmadı.
- Sürüş sırasında, uzun süreli kullanımda ve ekran kilitliyken yayın denenmedi.
- Uygulama arka plandayken harita güncellemesi telefonda sahte göstergeyle doğrulandı;
  motosiklette denenmedi.
- Pil tüketimi ve ısınma ölçülmedi. Harita arka planda yüksek kare hızıyla çiziliyor; göstergeye
  bunun küçük bir kısmı gidiyor.
- Yalnızca bir Android 11 telefonda ve bir API 36 emülatöründe çalıştırıldı.
- Protokoldeki açık noktalar: `NAVILITE_PROTOCOL.md` §10.

## Özellikler

- Müzik bilgisi ve bildirim özeti yok. Kartlar boş durur; geliştirici derlemesinde yer tutucu
  demo verisi gösterilir ve DEMO rozetiyle etiketlenir.
- API anahtarı yoksa harita sentetik çizimdir ve navigasyon demo sağlayıcıdan gelir.
- Göstergeye haritalı kare hızı bağlantının taşıyabildiği veriyle sınırlıdır (ilk testte
  6–10 FPS).
- Otomatik bağlanma yok: bağlantıyı her seferinde kullanıcı başlatır. Kopma sonrası yeniden
  bağlanma ayara bağlıdır ve 5 dakika sonra bırakılır.
- Garmin StreetCross / Yamaha MyRide ile çakışma tespit edilmiyor; bağlanamama durumunda olası
  neden olarak gösteriliyor.
- Telefondaki önizleme ile göstergeye giden kare ayrı çizicilerle üretiliyor; küçük görsel
  farklar olabilir.
- Uygulama son uygulamalar listesinden kaydırılarak kapatılırsa arayüz tarafı durur: bağlantı ve
  harita sürebilir, ama dönüş kartı son bilinen bilgide kalır.
- Motosikletin gönderdiği hız mesajı okunuyor ama biçimi çözülmedi; kullanılmıyor.
- iOS desteklenmiyor; `ios/` klasörü proje şablonundan ibarettir.

## Teknik notlar

- `google_navigation_flutter` beta (0.x) sürümdedir ve kırıcı değişiklikler yapabilir.
  0.12.0'da gözlenen iki davranış için önlem alındı: anahtar reddedilince koşullar penceresi
  çağrısı sonuçlanmıyor; konum yokken `getMyLocation` hata fırlatıyor.
- Release derlemesinde kod küçültme (R8) kapalıdır; Navigation SDK'nın iç sınıflarını bozuyor.
- Release derlemesi depodaki yapılandırmada debug anahtarıyla imzalanır (bkz. `SETUP.md`).
- `permission_handler` 13.x Android SDK 37 istediği için 12.x'te tutuluyor.
- Türkiye kapsamında iki tekerlekli yönlendirme ve hız limiti verisi görünmüyor.
- Google harita görüntüsünün araç ekranına aktarımı için izin doğrulanmadı
  (bkz. `LICENSE_AND_COMPLIANCE.md`).
