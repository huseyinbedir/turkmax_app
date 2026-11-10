# NaviLite Protokolü — Bağımsız İmplementasyon Spesifikasyonu

> **Kaynak:** Bu belge, açık kaynak Pillion projesinin (`alexandrevega/pillion`, commit
> `32d3a5daf08d6641947bfcbd86e3971097b756d4`, etiket `v0.3.0-alpha`) kaynak kodu ve belgeleri
> okunarak derlenmiş olgusal bir özettir; kod içermez. `dosya:satır` biçimindeki referanslar o
> commit'e göredir.
>
> **Doğrulama:** TurkMax bu tarife göre yazıldı ve tek bir motosiklette (XMAX 250 Tech MAX 2025)
> denendi; el sıkışma ve görüntü aktarımı çalıştı. O testin sonuçları ve göstergeden gelen
> mesajlara dair yeni gözlemler [FIELD_TEST_RESULTS.md](FIELD_TEST_RESULTS.md) dosyasındadır.
> Aşağıda **DOĞRULANMADI** diye işaretlenen noktalar, aksi o dosyada belirtilmedikçe hâlâ açıktır.

---

## 1. Taşıma katmanı (Transport)

| Özellik | Değer | Kaynak |
|---|---|---|
| Radyo | Bluetooth Classic (BR/EDR), RFCOMM / SPP | `docs/PROTOCOL.md:13`, `RfcommByteChannel.kt:14` |
| Servis UUID | `00007220-0000-1000-8000-00805F9B34FB` (16 bit kısa hali `0x7220`) | `RfcommByteChannel.kt:87-88`, `docs/PROTOCOL.md:14` |
| Roller | Telefon RFCOMM **istemcisi**; gösterge (CCU) servisi yayınlar | `docs/PROTOCOL.md:15` |
| Soket türü | **Insecure** RFCOMM soketi, servis kaydı (SDP) üzerinden UUID ile | `RfcommByteChannel.kt:46`, `docs/PROTOCOL.md:17` |
| Ön koşul | Telefon ile CCU önceden **eşleşmiş (bonded)** olmalı; uygulama tarama yapmaz | `RfcommByteChannel.kt:33-36`, `AndroidManifest.xml:26` |
| Eşzamanlılık | Aynı anda yalnızca **bir** projeksiyon uygulaması RFCOMM bağlantısına sahip olabilir | `docs/PROTOCOL.md:319` |

RFCOMM kanal numarası sabit kodlanmamıştır; SDP kaydından çözülür. Sabit bir kanal numarası **DOĞRULANMADI**.

### 1.1 Cihaz seçimi (CCU algılama)

Pillion, eşleşmiş cihazlar listesinden adaya şu kuralla karar verir (`RfcommByteChannel.kt:29-36`):

- Bluetooth adı `YCCU` ile **başlıyorsa** veya adın herhangi bir yerinde `CCU` **geçiyorsa** adaydır.
- Adında (küçük harfe çevrilmiş halde) `dev` veya `test` geçen cihazlar listenin **sonuna** atılır (geliştirici emülatörleri).
- Adaylar sırayla denenir; ilk başarılı bağlanan kullanılır. Hiç aday yoksa hata verilir.
- Kod yorumunda gerçek motosiklet adı örneği olarak `YCCU_<seri>` biçimi geçer (`RfcommByteChannel.kt:29`).

**DOĞRULANMADI:** XMAX'e özgü bir Bluetooth ad deseni yoktur; XMAX 250 Tech MAX 2025'in yayınladığı adın tam biçimi kaynakta yer almıyor. Model ayrımı ad üzerinden değil, el sıkışmada gelen **CCU parça numarası** üzerinden yapılır (bkz. §5).

---

## 2. Çerçeve (frame) yapısı

Her mesaj tek bir çerçevedir. Çok baytlı tüm tamsayılar **little-endian**'dır.

| Ofset | Boyut | Alan | Değer / açıklama |
|---:|---:|---|---|
| 0 | 4 | magic | `6E 41 6C 40` (ASCII `nAl@`) |
| 4 | 1 | version | `0x01` |
| 5 | 1 | frameType | Telefonun gönderdiği tüm çerçevelerde `6` (bkz. §2.2) |
| 6 | 1 | serviceType | Mesaj tipi / opcode (bkz. §3) |
| 7 | 4 | payloadSize | uint32 LE, yalnızca payload uzunluğu |
| 11 | 1 | payloadDataType | `0` = VALUE, `1` = POINTER |
| 12 | 4 | crc | uint32 LE (bkz. §2.1) |
| 16 | N | payload | `payloadSize` bayt |

- Başlık = ilk **12 bayt** (ofset 0–11). CRC başlıktan **sonra**, payload'dan **önce** gelir.
- Toplam tel uzunluğu = `16 + payloadSize`.
- Kaynak: `NaviLiteCodec.kt:12-36`, `docs/PROTOCOL.md:23-36`.

### 2.1 CRC

| Parametre | Değer |
|---|---|
| Algoritma | CRC-32/MPEG-2 |
| Polinom | `0x04C11DB7` |
| Başlangıç (init) | `0xFFFFFFFF` |
| RefIn / RefOut | **Hayır / Hayır** (yansıtma yok, MSB-first) |
| XorOut | `0x00000000` |
| Kapsam | **12 baytlık başlık + payload** (CRC alanının kendisi hariç) |
| Yazım | Sonuç uint32 **little-endian** olarak ofset 12–15'e |
| Standart kontrol değeri | `"123456789"` → `0x0376E6E7` |

Kaynak: `Crc32Mpeg2.kt:4-22`, `NaviLiteCodec.kt:28-34`, `docs/PROTOCOL.md:38-45`.

**Test vektörü (Pillion'ın "yakalanmış" dediği vektör, `ProtocolTest.kt:19-23`):**
frameType=6, serviceType=`0x54` (84), payloadDataType=1, payload=`B0 A0 47 56` → tel üzerindeki CRC alanı `24 F0 73 5B`.
Bu vektörü kendi bağımsız CRC hesabımızla (Pillion kodu çalıştırılmadan) yeniden ürettik ve aynı sonucu aldık; `0x0376E6E7` kontrol değeri de tutuyor.

Aynı algoritmayla bizim hesapladığımız örnek tam çerçeve (ESN_ACK, §4 adım 2):
`6E 41 6C 40 01 06 51 02 00 00 00 00 | 1A 4D 1C EC | 01 00`

**Alıcı tarafı notu:** Pillion, göstergeden gelen çerçevelerde CRC'yi, version'ı, frameType'ı ve payloadDataType'ı **doğrulamaz**; yalnızca magic, payloadSize ve serviceType'a bakar (`FrameReader.kt:16-25`, `NaviLiteCodec.kt:40-57`). Dolayısıyla gösterge → telefon yönünde CRC'nin aynı kurala uyduğu Pillion kodundan **DOĞRULANMADI** (belgede CCU'nun CRC hatasını durum kodu 7 ile reddettiği yazıyor; `docs/PROTOCOL.md:62`).

### 2.2 frameType değerleri

Pillion yalnızca `6` sabitini kullanır (`ServiceType.kt:3-4`) ve bunu el sıkışma dahil **her** giden çerçevede yazar (`Handshake.kt:40-42`, `MirrorEngine.kt:238`). Pillion belgesindeki tablo (kaynağı StreetCross incelemesi olarak belirtilmiş, `docs/PROTOCOL.md:74-83`):

| Ad | Değer | Yön (belgeye göre) |
|---|---:|---|
| MOBILE_REQUEST | 1 | gösterge → telefon |
| MOBILE_RESPONSE | 2 | telefon → gösterge |
| MOBILE_UPDATE | 3 | telefon → gösterge |
| MCU_REQUEST | 4 | telefon → gösterge |
| MCU_RESPONSE | 5 | gösterge → telefon |
| MCU_UPDATE | 6 | telefon → gösterge |

**DOĞRULANMADI:** Göstergenin gönderdiği çerçevelerde gerçekte hangi frameType değerinin bulunduğu (Pillion okumuyor). Bağımsız implementasyon gelen frameType'ı yok saymalı, gidenlerde `6` kullanmalıdır.

### 2.3 Çerçeve okuma / yeniden eşzamanlama

Pillion'ın davranışı (`FrameReader.kt:16-38`):

1. En az 16 bayt birikene kadar oku.
2. Tamponun başında magic yoksa **bir bayt at** ve tekrar dene (bayt bayt kaydırarak resync).
3. Ofset 7'deki uint32 LE'den toplam uzunluğu hesapla (`16 + payloadSize`), o kadar bayt birikene kadar oku.
4. serviceType (ofset 6) ve payload'ı (ofset 16'dan itibaren) üst katmana ver.
5. Okuma `-1` dönerse kanal kapanmış sayılır.

Okuma tampon dilimi 8192 bayttır (uygulama ayrıntısı, protokol gereği değil).

---

## 3. Mesaj tipleri (serviceType)

### 3.1 Pillion kodunun gerçekten kullandığı tipler

Kaynak: `ServiceType.kt:11-32`.

| Ad (Pillion) | Değer | Hex | Yön | payloadDataType | Pillion'ın gönderdiği/beklediği payload |
|---|---:|---:|---|---|---|
| IMAGE (IMAGE_FRAME_UPDATE) | 0 | 0x00 | telefon → gösterge | POINTER | §6 |
| NAV_STATUS | 2 | 0x02 | telefon → gösterge | VALUE | `00 00` |
| ROAD (CUR_ROAD_NAME) | 3 | 0x03 | telefon → gösterge | POINTER | boş (0 bayt) |
| HOME | 10 | 0x0A | telefon → gösterge | VALUE | `00 00` |
| OFFICE | 11 | 0x0B | telefon → gösterge | VALUE | `00 00` |
| APP_SETTING | 12 | 0x0C | telefon → gösterge | VALUE | önce `00 00`, sonra `01 00` |
| GPS | 13 | 0x0D | telefon → gösterge | VALUE | `01 00` |
| ZOOM | 14 | 0x0E | telefon → gösterge | POINTER | `07 19 06 00 30 2E 32 20 6D 69` |
| SPEED_LIMIT | 17 | 0x11 | telefon → gösterge | POINTER | `00 00 00 00 03 6D 70 68` |
| DAY_NIGHT | 31 | 0x1F | telefon → gösterge | VALUE | `01 00` |
| AUTH_REQUEST | 33 | 0x21 | telefon → gösterge | POINTER | `1C 07 00 01 00 00 00 00` |
| ESN_UPDATE | 66 | 0x42 | gösterge → telefon | — | içerik okunmuyor |
| IMAGE_ACK | 80 | 0x50 | gösterge → telefon | — | ilk 2 bayt = sıra no (uint16 LE) |
| ESN_ACK | 81 | 0x51 | telefon → gösterge | VALUE | `01 00` |
| AUTH_ACK | 82 | 0x52 | gösterge → telefon | — | Pillion'da tanımlı ama **hiç beklenmiyor/işlenmiyor** |
| SEC_DATA | 83 | 0x53 | gösterge → telefon | — | §4.1 |
| SEC_DATA_ACK | 84 | 0x54 | telefon → gösterge | POINTER | 4 bayt nonce (§4.1) |

Payload anlamları hakkında Pillion'ın notları (kesinlik düzeyi düşük):

- AUTH_REQUEST: ilk iki bayt `0x071C` = 1820 → kod yorumunda "appVersion 1820" (`Handshake.kt:45-46`); belgede native imza `(short, int)` olarak geçiyor (`docs/PROTOCOL.md:120`). Kalan 6 baytın anlamı **DOĞRULANMADI**.
- ZOOM: son 6 bayt ASCII `0.2 mi`; baştaki `07 19 06 00` belgede "current/min/max/label/showLabel" çağrısıyla ilişkilendirilmiş ama alan alan çözümü **DOĞRULANMADI** (`docs/PROTOCOL.md:110`).
- SPEED_LIMIT: 4 bayt float32 LE (`0.0` = bilinen limit yok) + `03` + ASCII `mph` (`docs/PROTOCOL.md:113`). `03` baytının uzunluk öneki olduğu **DOĞRULANMADI** (makul görünüyor ama kaynakta yazmıyor).
- DAY_NIGHT: `00` gündüz, `01` gece (`docs/PROTOCOL.md:118`).
- NAV_STATUS: Pillion **kodu** `00 00` gönderiyor (`Handshake.kt:50`); Pillion **belgesi** kurulumda `01 00` gözlendiğini ve bunun "aktif" gibi davrandığını söylüyor (`docs/PROTOCOL.md:98`). **Çelişki — hangisinin XMAX'te gerekli olduğu DOĞRULANMADI.** Kodun çalışan sürüm olduğu varsayımıyla başlangıç noktası `00 00` olmalı.

### 3.2 Belgede listelenen diğer tipler (Pillion kodu kullanmıyor)

Kaynak: `docs/PROTOCOL.md:94-141`. Pillion bu tabloyu Garmin StreetCross uygulamasının incelenmesine dayandırıyor; Pillion kodunda karşılıkları yok, o yüzden hepsi bizim açımızdan **DOĞRULANMADI** düzeyindedir. JPEG akışı için gerekli değiller.

| Değer | Ad | Yön |
|---:|---|---|
| 1 | ETA_UPDATE | telefon → gösterge |
| 4 | NEXT_TURN_DIST_UPDATE | telefon → gösterge |
| 5 | TBT_LIST_UPDATE | telefon → gösterge |
| 6 | ACTIVE_TURN_LIST_UPDATE | telefon → gösterge |
| 7 / 8 | FAV_POI_LIST_UPDATE / GAS_POI_LIST_UPDATE | telefon → gösterge |
| 9 | NAVI_EVENT_TEXT_UPDATE | telefon → gösterge |
| 15 | ROUTE_CALC_PROGRESS_UPDATE | telefon → gösterge |
| 16 | BT_THROUGHPUT_TIMEOUT_UPDATE | telefon → gösterge |
| 18 | VIA_POINT_COUNT_UPDATE | telefon → gösterge |
| 19 | NAVIGATION_INFO_UPDATE | telefon → gösterge |
| 20 | IMAGE_STOPPED_UPDATE | telefon → gösterge |
| 25 / 32 | DIALOG_LC_PROMPT_UPDATE / DIALOG_PROMPT_UPDATE | telefon → gösterge |
| 48 | APP_START_ROUTE_REQUEST | gösterge → telefon |
| 49 | APP_STOP_ROUTE_REQUEST | gösterge → telefon |
| 50 | APP_SKIP_NEXT_WAYPOINT_REQUEST | gösterge → telefon |
| 51 / 52 | APP_MAP_ZOOM_IN_REQUEST / APP_MAP_ZOOM_OUT_REQUEST | gösterge → telefon |
| 53 / 54 | APP_GO_HOME_REQUEST / APP_GO_OFFICE_REQUEST | gösterge → telefon |
| 55 / 56 | APP_START_CONTENT_UPDATE_REQUEST / APP_STOP_CONTENT_UPDATE_REQUEST | gösterge → telefon |
| 65 | MCU_VEHICLE_SPEED_UPDATE | gösterge → telefon |
| 69 | MCU_SYSINFO_UPDATE | gösterge → telefon |
| 70 | MCU_DIALOG_USER_SELECT_UPDATE | gösterge → telefon |
| 97 / 98 / 99 | TBT / FAV_POI / GAS_POI LIST_DATA_UPDATE | telefon → gösterge |

TurkMax için dikkat çekenler: `55`/`56` (gösterge, navigasyon ekranına girildiğinde/çıkıldığında içerik akışını başlat/durdur ister; içerik tipi `1` = navigasyon görüntüsü, `docs/PROTOCOL.md:159-165, 236-237`) ve `20` (görüntü durdu bildirimi). Pillion bunları **işlemez**; gelen her bilinmeyen çerçeveyi sessizce atlar ve göstergenin isteğini beklemeden görüntü göndermeye başlar.

---

## 4. El sıkışma / kimlik doğrulama

Bisiklete özgü anahtar, sertifika veya eşleşme sırrı **yoktur**; doğrulama sabit bir XOR ile "çöz ve geri yankıla" işlemidir (`Auth.kt:4-8`, `docs/PROTOCOL.md:258-277`).

### 4.1 Adımlar

Kaynak: `Handshake.kt:19-32`.

| # | Yön | serviceType | PDT | Payload | Not |
|---:|---|---|---|---|---|
| 0 | — | — | — | — | RFCOMM bağlantısı açılır |
| 1 | gösterge → telefon | 66 ESN_UPDATE | — | (okunmuyor; belgeye göre string) | Telefon bunu **bekler**; arada gelen başka tipler atlanır |
| 2 | telefon → gösterge | 81 ESN_ACK | VALUE | `01 00` | |
| 3 | telefon → gösterge | 33 AUTH_REQUEST | POINTER | `1C 07 00 01 00 00 00 00` | Adım 2'nin hemen ardından, yanıt beklemeden |
| 4 | gösterge → telefon | 83 SEC_DATA | — | `(ASCII parça no ‖ 4 bayt nonce)`, her bayt `XOR 0x0A` | Telefon bunu bekler; aradaki diğer tipler (ör. 82 AUTH_ACK) atlanır |
| 5 | telefon → gösterge | 84 SEC_DATA_ACK | POINTER | SEC_DATA payload'ının **son 4 baytı**, her biri `XOR 0x0A` | |
| 6 | telefon → gösterge | kurulum patlaması | — | §4.2 | 11 çerçeve art arda, yanıt beklenmeden |
| 7 | — | — | — | — | Oturum "doğrulanmış" kabul edilir; görüntü akışı başlar |

SEC_DATA çözümü:

- Parça numarası = payload'ın **son 4 bayt hariç** kısmı, bayt bayt `XOR 0x0A`, ASCII olarak okunur (`Auth.kt:21-26`).
- Nonce uzunluğu = 4 bayt (`Auth.kt:13`).
- Parça numarası uzunluğu sabit kodlanmamıştır (örneklerde 12 karakter).

Test vektörleri (`ProtocolTest.kt:26-46`; Pillion bunları gerçek cihazdan yakalanmış olarak tanımlıyor):

| SEC_DATA payload (hex) | Çözülen parça no | SEC_DATA_ACK payload (hex) |
|---|---|---|
| `3A3A3C27483E3B3C3A273A3A` + `BAAA4D5C` | `006-B4160-00` (MT-07) | `B0A04756` |
| `3A3A3C27483E3B3C3A273A3A` + `C12B8A7B` | `006-B4160-00` | `CB218071` |
| `3A3A3C27483E3B3C3A273A3A` + `43719E55` | `006-B4160-00` | `497B945F` |
| `3A3A3C274839333F38273A39` + `2504211C` | `006-B3952-03` (XMAX, issue #7) | `2F0E2B16` |

**DOĞRULANMADI:**
- Göstergenin SEC_DATA_ACK'ye açık bir "başarılı" yanıtı gönderip göndermediği (Pillion beklemiyor).
- AUTH_ACK (82) içeriği ve zorunluluğu.
- ESN_UPDATE'in bağlantıdan sonra kendiliğinden mi geldiği sorusu: Pillion öyle varsayıyor; issue #26'da XMAX'te bazen RFCOMM bağlandığı halde ESN_UPDATE'in **hiç gelmediği** bildiriliyor (bkz. §7.3).

### 4.2 Kurulum patlaması (setup burst)

Pillion bu 11 çerçeveyi tam bu sırayla, aralarında gecikme olmadan gönderir (`Handshake.kt:48-61`). Kod yorumuna göre gösterge görüntü çizmeden önce bunları bekler.

| Sıra | serviceType | PDT | Payload |
|---:|---|---|---|
| 1 | 2 NAV_STATUS | VALUE | `00 00` |
| 2 | 31 DAY_NIGHT | VALUE | `01 00` |
| 3 | 10 HOME | VALUE | `00 00` |
| 4 | 11 OFFICE | VALUE | `00 00` |
| 5 | 13 GPS | VALUE | `01 00` |
| 6 | 12 APP_SETTING | VALUE | `00 00` |
| 7 | 14 ZOOM | POINTER | `07 19 06 00 30 2E 32 20 6D 69` |
| 8 | 3 ROAD | POINTER | (boş) |
| 9 | 17 SPEED_LIMIT | POINTER | `00 00 00 00 03 6D 70 68` |
| 10 | 13 GPS | VALUE | `01 00` |
| 11 | 12 APP_SETTING | VALUE | `01 00` |

El sıkışma boyunca telefon toplam **14 çerçeve** yazar (3 + 11) — `FrameReaderHandshakeTest.kt:62-63`.

**DOĞRULANMADI:** Bu 11 çerçevenin hangilerinin gerçekten zorunlu olduğu; değerlerin (ör. `mph`, `0.2 mi`, gece modu) XMAX'te görünür bir etkisi olup olmadığı.

---

## 5. Gösterge profilleri ve çözünürlük

Çözünürlük tel üzerinde ilan edilmez; SEC_DATA'dan çözülen CCU parça numarasından türetilir. Gösterge, boyutu uymayan JPEG'i reddeder ve navigasyon ekranına girildiğinde "Connection Error" gösterir (`NaviLiteDisplay.kt:8-15, 26-28`).

### 5.1 Pillion kodundaki kural

Kaynak: `NaviLiteDisplay.kt:18-30`, `ProtocolTest.kt:48-53`.

| Parça no koşulu | Genişlik × Yükseklik | Açıklama |
|---|---|---|
| `006-B3952` ile **başlıyor** | **480 × 234** | XMAX / NMAX scooter CCU'su (yakalanan örnek: `006-B3952-03`) |
| diğer her şey (bilinmeyen dahil) | 480 × 240 | Varsayılan (MT-07, MT-09, XSR900, R9, Tracer…; MT-07 örneği `006-B4160-00`) |

### 5.2 Pillion belgesindeki model tablosu (StreetCross incelemesine atfen)

Kaynak: `docs/PROTOCOL.md:145-155`.

| StreetCross model adı | Sıra | Parça no alt dizgisi | Görüntü boyutu | Metin navigasyon servisi |
|---|---:|---|---|---|
| MODEL_IXWW22 | 0 | `006-B3952` | 480 × 234 | 4 (NEXT_TURN_DIST_UPDATE) |
| MODEL_IMWW23 | 1 | `006-B4160` veya `006-B4920` | 480 × 240 | 19 (NAVIGATION_INFO_UPDATE) |
| MODEL_INVALID | 2 | diğer / yok | temel boyutlara düşer | — |

Not: `006-B4920` Pillion **kodunda** ayrıca ele alınmaz (varsayılan 480×240'a düşer, sonuç aynıdır).

**Belge içi tutarsızlık:** `docs/PROTOCOL.md:315` özet akışta "480×236" yazıyor; kod, testler ve belgenin geri kalanı **234** diyor. 236 bir yazım hatası gibi görünüyor; bağlayıcı olan kod değeri **480×234**'tür.

**DOĞRULANMADI:**
- "XMAX 250 Tech MAX 2025" modelinin parça numarasının `006-B3952-xx` olduğu. Kaynakta yalnızca genel "XMAX / NMAX scooter CCU" ifadesi, "XMAX (2025)", "XMAX 300 (2024)", "TechMAX 125 (2025)" raporları ve issue #7'de "Xmax Tech Max 2025" kullanıcı bildirimi var; 250 cc varyantı adıyla geçmiyor.
- 480×234 alanının fiziksel panelde tam olarak nereye oturduğu, piksel en-boy oranı, güvenli kenar boşlukları.

TurkMax için öneri (olgu değil, tasarım notu): çözünürlüğü sabit kodlamak yerine el sıkışmada çözülen parça numarasına göre seçmek ve parça numarasını kullanıcıya/loga göstermek.

---

## 6. Görüntü kanalı

### 6.1 Görüntü çerçevesi

serviceType `0`, payloadDataType POINTER (`1`), frameType `6`. Payload düzeni (`MirrorEngine.kt:231-238`, `docs/PROTOCOL.md:288-295`):

| Ofset | Boyut | Alan | Değer |
|---:|---:|---|---|
| 0 | 1 | imageType | `3` (Pillion yorumunda "NAVIGATION_EXPANDED") |
| 1 | 2 | sequence | uint16 LE |
| 3 | N | JPEG verisi | Tam bir JPEG dosyası (SOI…EOI) |

- **Parçalama (chunking) yoktur:** Her JPEG, tek bir NaviLite çerçevesinin payload'ına bütün olarak konur; `payloadSize = 3 + JPEG uzunluğu`. RFCOMM akışına tek seferde yazılıp flush edilir (`RfcommByteChannel.kt:69-73`). Protokol düzeyinde ayrı bir chunk başlığı/boyutu Pillion'da **yoktur**.
- Azami JPEG/çerçeve boyutu için bir sınır kaynakta **DOĞRULANMADI** (alan 32 bit; pratik sınır bilinmiyor).
- Sıra numarası her (yeniden) bağlantıda `1`'den başlar, her gönderimde 1 artar, 16 bite sarılır (`MirrorEngine.kt:42, 79, 186, 234-237`). `0`'dan başlamanın sakıncası olup olmadığı **DOĞRULANMADI**.
- JPEG: Pillion Android'in standart Bitmap JPEG sıkıştırıcısını kullanır, varsayılan kalite 40, kullanıcı aralığı 10–80 (`MediaProjectionScreenSource.kt:99, 137`; `MirrorSettings.kt:6, 11`). Belge "baseline JPEG" der (`docs/PROTOCOL.md:294`). Progressive JPEG'in, 4:4:4 alt örneklemenin, EXIF/JFIF başlık çeşitlerinin kabul edilip edilmediği **DOĞRULANMADI** — güvenli yol: baseline, 4:2:0, standart JFIF.
- Diğer imageType değerleri **DOĞRULANMADI**.

### 6.2 IMAGE_ACK

| Özellik | Değer | Kaynak |
|---|---|---|
| serviceType | 80 | `ServiceType.kt:21` |
| Yön | gösterge → telefon | |
| Payload | En az 2 bayt; ilk 2 bayt = onaylanan görüntünün sıra numarası, uint16 LE | `MirrorEngine.kt:267-270`, `ImageAckWaitTest.kt:59-62` |

Not: Pillion belgesi ACK payload'ını "çoğunlukla bir bayt" diye tarif eder (`docs/PROTOCOL.md:134`); güncel **kod** ise 2 bayttan kısa ACK'yi "bozuk" sayıp yok sayar. Kod daha yeni olduğundan (v0.3.0 değişiklik günlüğü: "doğrulanmış 16 bit sıra numarası") kod davranışı esas alınmalı. 2 bayttan sonraki olası ek baytların anlamı **DOĞRULANMADI**.

### 6.3 Akış kontrolü (stop-and-wait)

Pillion'ın kuralları (`MirrorEngine.kt:145-229, 249-265`):

1. Aynı anda bağlantı üzerinde **en fazla bir** onaylanmamış görüntü bulunur. Kayan pencere bilinçli olarak kullanılmıyor (yavaş göstergelerde sabit gecikme yarattığı not edilmiş).
2. Gönderimden önce en güncel kare alınır (eski kareler kuyruğa girmez; "en taze kare" modeli).
3. Görüntü gönderilir, ardından **yalnızca aynı sıra numarasını taşıyan** IMAGE_ACK beklenir.
   - Farklı sıra numaralı veya bozuk ACK'ler yok sayılır (bir sonraki görüntünün kilidini açamaz).
   - Bu sırada gelen diğer servis tipleri yok sayılır ve zaman aşımını **sıfırlamaz**.
4. ACK zaman aşımı: **2000 ms**. Aşılırsa bağlantı **kapatılmaz**; sayaç artırılır ve sıradaki en taze kare yeni sıra numarasıyla gönderilir.
5. Kanal kapanırsa (okuma hatası) hata yukarı taşınır ve yeniden bağlanma döngüsü devreye girer.
6. Hız sınırı: ardışık iki gönderim arasında en az `1000 / maxFps` ms (tamsayı bölme; varsayılan 15 fps → 66 ms). `maxFps` 1–59 dışında ise sınır uygulanmaz.
7. Kare henüz yoksa 15 ms aralıkla yoklanır.

Gerçek FPS komutla belirlenmez; kodlama süresi + Bluetooth veri hızı + göstergenin ACK gecikmesinden doğar (`docs/PROTOCOL.md:301-303`).

---

## 7. Durum makinesi ve zamanlamalar

### 7.1 Durumlar

```
BOŞTA
  └─ başlat ─▶ BAĞLANIYOR (RFCOMM connect, adayları sırayla dene)
                 ├─ başarısız ─▶ [ilk bağlantı ise ve yeniden deneme kapalıysa] HATA
                 │               [aksi halde] 1500 ms bekle ─▶ BAĞLANIYOR
                 └─ bağlandı ─▶ EL SIKIŞMA
                                  ├─ ESN_UPDATE bekle ─▶ ESN_ACK + AUTH_REQUEST gönder
                                  ├─ SEC_DATA bekle   ─▶ SEC_DATA_ACK + kurulum patlaması gönder
                                  ├─ 5000 ms içinde bitmezse: soketi kapat ─▶ (yeniden bağlan)
                                  └─ tamam ─▶ AKIŞ (sıra no = 1, çıktı boyutu = profil)
                                                ├─ görüntü gönder ─▶ ACK bekle (≤2000 ms) ─▶ tekrar
                                                ├─ okuma/yazma hatası ─▶ soketi kapat, 1500 ms bekle ─▶ BAĞLANIYOR
                                                └─ durdur ─▶ soketi kapat ─▶ BOŞTA
```

Kaynak: `MirrorEngine.kt:44-143`.

### 7.2 Zamanlama sabitleri

| Sabit | Değer | Kaynak |
|---|---:|---|
| El sıkışma gözetim süresi (tüm el sıkışma için) | 5000 ms | `MirrorEngine.kt:244` |
| IMAGE_ACK zaman aşımı | 2000 ms | `MirrorEngine.kt:245` |
| Yeniden bağlanma bekleme süresi | 1500 ms (100 ms'lik dilimlerle, durdurma isteğine duyarlı) | `MirrorEngine.kt:243, 99-104` |
| Kare yokken yoklama aralığı | 15 ms | `MirrorEngine.kt:177` |
| Varsayılan azami FPS | 15 (min. aralık 66 ms) | `MirrorEngine.kt:30, 38` |
| Varsayılan JPEG kalitesi | 40 | `MirrorSettings.kt:11` |

Uygulama notları:

- Engelleyen (blocking) soket okuması korutin zaman aşımıyla kesilemediği için, Pillion hem el sıkışma zaman aşımında hem durdurmada **soketi kapatarak** okuyucunun kilidini açar (`MirrorEngine.kt:118-136, 222-228`).
- Otomatik yeniden bağlanma yalnızca **en az bir başarılı el sıkışmadan sonra** devrededir (yanlış cihazda sonsuz döngüyü önlemek için); "dash/VD" modunda ilk bağlantı da tekrar denenir (`MirrorEngine.kt:32-33, 84-86`; `CHANGELOG.md:18-19`).
- Bağlanma sırasında durdurma gelirse, bağlanmakta olan soket de kapatılır (`RfcommByteChannel.kt:21-23, 78-84`).

### 7.3 Bilinen açık sorun: görüntüden hemen sonra bağlantıyı kapatma (XMAX)

GitHub issue #26 (açık, 2026-11-09, bir katkıcı tarafından XMAX üzerinde raporlandı; HEAD commit'inde **düzeltilmemiş**):

- Görüntü akışı sırasında RFCOMM kapatılırsa, sonraki bağlantıda CCU bazen ESN_UPDATE veya SEC_DATA göndermiyor.
- Raporlanan deney: son IMAGE yazımından 0/10/30 ms sonra kapatma → 133 denemede 9 takılma; 100/300 ms sonra → 141 denemede 0. (Raporu yazan kişi bunun kontrollü bir istatistik olmadığını belirtiyor.)
- Bazı takılmalar telefonun Bluetooth'unu kapatıp açmakla veya telefonu yeniden başlatmakla geçmemiş; ancak **motosikletin kontağını kapatıp açınca** düzelmiş.
- Normal ACK gecikmelerinin zaman zaman ~200–300 ms'ye çıktığı not edilmiş.
- Önerilen (deneysel, ana depoya girmemiş) çözüm: durdurmada yeni görüntü göndermeyi kes, bekleyen son görüntünün ACK'sini en fazla 500 ms bekle, sonra kapat.

Bunlar üçüncü taraf saha gözlemleridir; bizim tarafımızdan **DOĞRULANMADI**. Yine de bağımsız implementasyonda "durdururken bekleyen ACK'yi sınırlı süre bekle, sonra kapat" kuralını baştan tasarlamak mantıklıdır.

---

## 8. Göstergeden gelen diğer mesajlar

Pillion'ın akış sırasındaki tutumu: IMAGE_ACK dışındaki her şeyi yok say (`MirrorEngine.kt:259-262`). Belgeye göre gösterge şunları gönderebilir: içerik başlat/durdur istekleri (55/56), yakınlaştırma istekleri (51/52), hız (65), sistem bilgisi (69) (`docs/PROTOCOL.md:121-133`).

**DOĞRULANMADI:** XMAX'in navigasyon ekranı açık değilken görüntüleri ACK'leyip ACK'lemediği; 55/56 isteklerine uymamanın yan etkisi; 56 sonrası görüntü göndermeye devam etmenin sonuçları. README kullanıcıdan önce TFT'de navigasyon ekranını seçmesini, sonra uygulamada Başlat'a basmasını ister (`README.md:63-66`).

---

## 9. Bağımsız implementasyon için asgari kontrol listesi

1. Eşleşmiş cihazlardan adı `YCCU…` / `…CCU…` olanı bul; UUID `0x7220` ile insecure RFCOMM istemci soketi aç.
2. Çerçeve kodlayıcı/çözücü: magic, version=1, frameType=6, serviceType, payloadSize (LE), PDT, CRC-32/MPEG-2 (başlık+payload, LE), payload.
3. CRC'yi §2.1'deki iki vektörle birim testine bağla.
4. El sıkışma: 66 bekle → 81 (`01 00`) → 33 (8 bayt) → 83 bekle → son 4 baytı `XOR 0x0A` ile 84'te yankıla → 11 çerçevelik kurulum.
5. Auth'u §4.1'deki dört vektörle birim testine bağla.
6. Parça numarasından boyut seç: `006-B3952*` → 480×234, aksi halde 480×240.
7. Görüntü: `[03][seq LE16][JPEG]`, servis 0, POINTER. Sıra 1'den başlar.
8. Her görüntüden sonra eşleşen sıra numaralı servis 80'i ≤2000 ms bekle; zaman aşımında bağlantıyı koparmadan devam et.
9. Zaman aşımları: el sıkışma 5 s, yeniden bağlanma 1,5 s.
10. Durdururken bekleyen ACK için kısa, sınırlı bir bekleme uygula (§7.3).

---

## 10. DOĞRULANMADI özeti

- TurkMax'in kendi gerçek gösterge testi tek bir motosikletle sınırlıdır; sonuçları ve o testte
  doğrulanan/yeni öğrenilen noktalar `FIELD_TEST_RESULTS.md` dosyasındadır. Aşağıdaki maddeler o
  test dışında kalanlardır.
- Gösterge → telefon çerçevelerindeki frameType/PDT/CRC değerleri (Pillion okumuyor/doğrulamıyor).
- AUTH_REQUEST'in son 6 baytının, ZOOM ve SPEED_LIMIT payload alanlarının anlamı.
- NAV_STATUS için `00 00` mı `01 00` mı gerektiği (kod/belge çelişkisi).
- Kurulum patlamasındaki çerçevelerin hangilerinin zorunlu olduğu.
- AUTH_ACK (82) içeriği; SEC_DATA_ACK sonrası açık başarı yanıtı.
- Azami JPEG/payload boyutu; progressive JPEG, kroma alt örnekleme ve diğer imageType değerleri.
- IMAGE_ACK payload'ının 2 bayttan sonraki kısmı.
- 55/56 (içerik başlat/durdur) isteklerinin akışa etkisi; navigasyon ekranı kapalıyken davranış.
- §3.2'deki tüm ek servis tipleri ve payload düzenleri (Pillion kodunda kullanılmıyor).
- RFCOMM kanal numarası (SDP ile çözülüyor).
- Y-Connect / MyRide uygulamalarının Android'de aynı RFCOMM servisini kullanıp kullanmadığı.
