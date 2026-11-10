# Saha Testi: Gerçek Motosiklet

Bilgisayar olmadan, yalnızca telefonla yapılacak ilk gerçek gösterge testi için adımlar.
Uygulama her bağlantı adımını günlüğe yazar; test sonrası günlük okunarak sonuç değerlendirilir.

**Durum:** Aşağıdaki akış yalnızca telefondaki sahte gösterge ile doğrulandı. Gerçek gösterge
davranışı bilinmiyor; bu test onu öğrenmek için yapılıyor.

## Hazırlık (evde)

1. Motosiklet telefonla eşleşmiş olmalı (Bağlantı sayfasında `YCCU_…` adıyla görünür).
2. Bağlantı sayfası → **Pil optimizasyonu** kartına dokunup TurkMax için kısıtlamayı kaldırın.
3. Telefonda Bluetooth, konum ve internet açık olsun.
4. İsterseniz önce **Sahte CCU** ile bir deneme yapın: Bağlan → Yayını başlat → geri → ana sayfa.

## Motosikletin yanında

1. Kontağı açın. TFT'de **navigasyon ekranını** seçin.
2. Telefonda Garmin StreetCross ve MyRide tamamen kapalı olsun (bağlantıyı aynı anda yalnızca
   bir uygulama kullanabilir).
3. TurkMax → **Motosiklet bağlantısı** → `YCCU_…` satırında **Bağlan**.
4. Durum **Hazır** olunca **Yayını başlat**.
5. TFT'de haritalı cockpit görünmeli. Harita ekran dışında çizildiği için uygulamayı arka plana
   alabilir, başka bir uygulamaya geçebilirsiniz; harita akmaya devam etmelidir.

Arka plan testi: yayın sürerken ana ekrana dönün (uygulamayı kapatmadan) ve TFT'yi en az birkaç
dakika izleyin. Ayrıca telefonun ekranını kilitleyip haritanın sürüp sürmediğine bakın.

## Bir şey ters giderse

Ayarlar bağlantı kesikken değişir: **Bağlantıyı kes** → Bağlantı sayfasında **Yayın ayarları**.

| Belirti | Deneyin |
|---|---|
| "Bağlanılamadı" | Kontak açık mı, StreetCross/MyRide kapalı mı; telefonun Bluetooth'unu kapatıp açın; tekrar Bağlan |
| "Gösterge yanıt vermedi" | Kontağı kapatıp açın, tekrar Bağlan |
| Hazır/Yayın yapılıyor ama TFT'de görüntü yok ya da "Connection Error" | Çözünürlük: **480×240**, olmazsa **480×234** |
| Hâlâ görüntü yok | **NAV_STATUS etkin gönder** anahtarını açın |
| Emin olmak için | Görüntü kaynağı: **Test karesi** (kenar çerçevesi, renk şeritleri, sayaç ve saat içerir) |
| FPS düşük, çok zaman aşımı | JPEG kalitesi **20**, azami FPS **10** |

Her denemeden sonra bağlantıyı **Bağlantıyı kes** ile sonlandırın; kontağı yayın sürerken
kapatmayın. Referans projede, yayın sırasında bağlantı aniden kesilince göstergenin kontak
kapatılıp açılana kadar yanıt vermeyebildiği bildirilmiş.

## Not alınacaklar

- TFT'de ne göründü (bekleme yazısı / harita / test karesi / hata mesajı / hiçbir şey)?
- Görüntü kırpık, kaymış ya da bozuk mu? (Test karesinde dört kenardaki çerçeve görünüyor mu?)
- Bağlantı sayfasındaki FPS, ACK süresi ve zaman aşımı sayısı.
- Hangi ayarla çalıştı?

Mümkünse TFT'nin bir fotoğrafını çekin.

## Günlük

- Bağlantı sayfasının altındaki **Bağlantı günlüğü** kartı son satırları gösterir; **Kopyala** ile
  panoya alınır.
- Tam günlük telefonda saklanır: `Android/data/com.turkmax.app/files/logs/session-*.log`
  (her uygulama açılışında yeni dosya, en yeni 10 dosya tutulur). Uygulamayı kapatmak günlüğü
  silmez.
- Günlükte görüntü verisi ve bildirim içeriği yoktur; yalnızca protokol üst verisi vardır
  (çerçeve türleri, boyutlar, kısa payload'lar, süreler).

Günlükten öğrenilecekler: göstergenin parça numarası (`part='…'`), el sıkışmanın hangi adımda
kaldığı, göstergeden gelen çerçeve türleri (`RX svc=…`), ACK süreleri ve kopma nedeni.

## Sınırlar

- Google harita görüntüsünün motosiklet ekranına aktarımı için izin doğrulanmadı
  (`LICENSE_AND_COMPLIANCE.md`); kullanım sorumluluğu API anahtarının sahibindedir.
- Ekran kilitliyken haritalı yayın henüz denenmedi.
- Uygulamayı son uygulamalar listesinden kaydırarak kapatmayın.
- Sürüş sırasında telefonla etkileşime girmeyin; ilk testi motosiklet dururken yapın.
