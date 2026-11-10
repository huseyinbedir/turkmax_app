# Lisans ve Uyumluluk Notları

Bu belge hukuki görüş değildir. Projeyi derleyip kullanan herkesin bilmesi gereken açık
noktaları özetler.

## 1. Google Navigation SDK ve harita görüntüsünün araç ekranına aktarımı

TurkMax, haritayı Google Navigation SDK ile çizer ve görüntüsünü Bluetooth üzerinden
motosiklet ekranına gönderir.

- Navigation SDK görüntüsünün Android Auto/CarPlay dışında bir araç ekranına aktarılmasına
  açıkça izin veren bir hüküm bulunamadı.
- Google Maps Platform Koşulları'nda bu kullanımın aleyhine okunabilecek hükümler var: araca
  gömülü sistemlerle bağlantılı kullanım kısıtı (3.2.3(f)) ve içeriğin servis dışına aktarılması
  kısıtı (3.2.3(a)).
- Değerlendirmemiz: belirsiz ile izinsiz arası. Kesin yanıt ancak Google'ın yazılı açıklamasıyla
  alınabilir.

Sonuç: proje hazır derleme ve ortak API anahtarı dağıtmaz. Uygulamayı kendi Google Cloud
anahtarınızla derlersiniz; bu kullanımın Google koşullarına uygunluğu anahtar sahibinin
sorumluluğundadır. Google'ın zorunlu marka ve atıf öğelerine dokunulmaz.

Ek notlar: Navigation SDK ve Places kullanım başına ücretlendirilir. Türkiye kapsamında iki
tekerlekli yönlendirme görünmediği için rota hesabı sürüş modunda yapılır.

## 2. NaviLite protokolü

- Gösterge ile iletişim, Garmin'in Yamaha için geliştirdiği ve kamuya belgelenmemiş bir
  protokole dayanır. TurkMax'teki uygulama bağımsız yazılmıştır.
- Protokol bilgisi, [Pillion](https://github.com/alexandrevega/pillion) projesinin kamuya açık
  kaynak ve belgelerinin incelenmesinden derlenmiştir. Pillion, PolyForm Noncommercial 1.0.0 ile
  lisanslıdır; TurkMax ondan kod içermez, yalnızca protokol olgularını (sabitler, alan düzenleri,
  sıralar) kullanır.
- Bağımsız uygulama lisans riskini azaltır, sıfırlamaz. Belgelenmemiş bir protokolle birlikte
  çalışabilirlik, ülkeye göre değişen hukuki değerlendirmelere konu olabilir.
- Proje yalnızca navigasyon görüntü alanına içerik gönderir. Gösterge yazılımını değiştirmez,
  araca komut yazmaz, güvenlik sistemlerine dokunmaz.

## 3. Markalar

Yamaha, XMAX, Garmin, NaviLite, Google ve diğer adlar sahiplerinin markalarıdır ve yalnızca
uyumluluğu tarif etmek için kullanılır. TurkMax bu şirketlerle bağlantılı değildir ve onlar
tarafından onaylanmamıştır.

## 4. Projenin lisansı

TurkMax GPL-3.0 ile lisanslıdır (`LICENSE`). Değiştirip dağıtan herkes kendi sürümünün kaynağını
aynı lisansla açmak zorundadır.

Açık nokta: uygulama, özgür olmayan Google Navigation SDK'ya bağlanır. GPL, böyle bir bileşenle
birleştirilmiş derlenmiş paketin başkalarınca dağıtımını kısıtlar. Proje hazır derleme
dağıtmadığı için bugün pratik bir sorun yoktur; derlenmiş paket dağıtılacaksa telif sahiplerinin
bu bileşenler için açık bir ek izin (GPL-3.0 madde 7) eklemesi gerekir.

Doğrudan bağımlılıklar (flutter_bloc, equatable, get_it, injectable, go_router,
shared_preferences, intl, http, permission_handler) izin verici açık kaynak lisanslarına
sahiptir. `google_navigation_flutter` Apache-2.0'dır; sarmaladığı Navigation SDK Google'ın kendi
koşullarına tabidir.

## 5. Gizlilik

- Uygulamanın kendi sunucusu yoktur; hesap açmaz, analitik toplamaz.
- Konum, navigasyon için Google Navigation SDK'ya; arama metni Google Places'a gönderilir.
- Bağlantı günlüğü yalnızca telefonda tutulur; görüntü verisi içermez, yalnızca protokol üst
  verisi içerir.
- Motosiklete gönderilen görüntü yalnızca eşleşmiş göstergeye, Bluetooth üzerinden gider.
