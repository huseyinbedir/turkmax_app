# Saha Testi Sonuçları

## 2026-11-10 — İlk gerçek gösterge testi

Motosiklet: Yamaha XMAX 250 Tech MAX 2025. Telefon: Android 11.
Kaynak: uygulamanın bağlantı günlüğü ve TFT üzerindeki gözlem (görüntü yansıdı, sorun
görülmedi). Motosiklet duruyordu; tek oturum, ~45 saniye yayın.

### Doğrulananlar

| Konu | Sonuç |
|---|---|
| RFCOMM bağlantısı | Insecure soket, UUID 0x7220 ile 0,9 sn'de bağlandı |
| Bluetooth adı | `YCCU_` + 14 karakterlik kimlik |
| El sıkışma | 165 ms'de tamamlandı; belgelenen adımlar aynen çalıştı |
| Parça numarası | `006-B3952` önekiyle başlıyor → XMAX profili (480×234) otomatik seçildi |
| Görüntü | Haritalı cockpit TFT'de göründü; 451 kare gönderildi, 450'si onaylandı, 0 zaman aşımı |
| Kurulum çerçeveleri | NAV_STATUS `00 00` ile çalıştı; alternatif ayarlara gerek kalmadı |
| Gösterge → telefon CRC | Gelen 56 çerçevenin tamamında CRC geçerli (aynı CRC kuralı iki yönde de geçerli) |

### Ölçümler

| Görüntü | JPEG boyutu | Ortalama ACK | FPS |
|---|---|---|---|
| Bekleme karesi (düz renk + yazı) | 1,5–3,9 KB | ~33 ms | 15,0 (sınırda) |
| Haritalı cockpit | 7,4–8,2 KB | 93–128 ms | 6–10,5 |

- Haritalı görüntüde ACK süresi hedefi aştığı için uyarlama JPEG kalitesini 40'tan **10'a**
  indirdi. Bağlantının taşıyabildiği veri kabaca 80 KB/sn düzeyinde görünüyor.
- Çıkarım: haritada 15 FPS gerçekçi değil; kalite ile FPS arasındaki denge yeniden
  ayarlanmalı (ör. daha düşük FPS hedefi, daha yüksek taban kalite).

### Göstergeden gelen mesajlar (yeni bilgi)

| serviceType | frameType | Payload | Sıklık | Yorum |
|---|---|---|---|---|
| 66 ESN_UPDATE | 3 | 10 bayt ASCII rakam | bağlantıda 1 kez | Bağlanınca kendiliğinden geliyor |
| 82 AUTH_ACK | 3 | `01 00` | 2 kez | AUTH_REQUEST ve SEC_DATA_ACK sonrasında |
| 83 SEC_DATA | 3 | 16 bayt | 1 kez | Belgelenen biçimde |
| 80 IMAGE_ACK | 3 | 2 bayt sıra no | her kare | Belgelenen biçimde |
| 65 | 3 | 3 bayt, hep `00 00 00` | ~1 sn'de bir | Büyük olasılıkla **araç hızı**; motosiklet durduğu için biçimi çözülemedi |
| 55 | 1 | `01 00` | yayın başından ~3 sn sonra | İçerik başlat isteği (belgeye göre) |
| 56 | 1 | `01 00` | kopmadan 1,3 sn önce | İçerik durdur isteği (belgeye göre) |

Yakıt, yağ veya tüketim verisi taşıyan bir mesaj bu oturumda **görülmedi**.

### Bulunan sorunlar

1. **Durdurma isteğine uyulmuyor.** Gösterge 56 gönderdikten 1,3 sn sonra bağlantıyı kapattı;
   uygulama o ana dek kare göndermeye devam etti. 56 gelince yayın duraklatılmalı, 55 gelince
   sürdürülmeli.
2. **Yeniden bağlanma döngüsü sınırsız.** Kopmadan sonra 11 dakika boyunca 1,5 sn arayla 852
   başarısız deneme yapıldı (soket oluşturulamadı; büyük olasılıkla kontak ya da Bluetooth
   kapalıydı). Artan bekleme ve azami süre gerekli.
3. **Kalite tabanı çok düşük.** Kalite 10'a kadar inebiliyor.

### Doğrulanmayanlar

- Sürüş sırasında davranış (titreşim, menzil, uzun süre), ısı ve pil tüketimi.
- Kopmanın nedeni (kullanıcı navigasyon ekranından mı çıktı, kontak mı kapandı) günlükten
  kesin olarak anlaşılmıyor.
- 65 mesajının biçimi ve birimi.
- Uygulama arka plandayken haritalı yayın.
