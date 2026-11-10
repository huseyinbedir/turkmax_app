"""TurkMax uygulama simgesi: koyu teal zemin üzerinde maxi-scooter silueti ve navigasyon oku."""
from PIL import Image, ImageDraw

S = 4            # süper örnekleme
N = 1024
BG_TOP = (16, 52, 54)
BG_BOTTOM = (6, 18, 20)
TEAL = (45, 212, 191)
TEAL_DARK = (20, 184, 166)
LIGHT = (240, 250, 249)
BG_GAP = (9, 28, 30, 255)   # tekerlek çevresindeki zemin rengi


def p(points):
    return [(x * S, y * S) for x, y in points]


def background():
    img = Image.new("RGB", (N * S, N * S))
    d = ImageDraw.Draw(img)
    for y in range(N * S):
        t = y / (N * S - 1)
        d.line([(0, y), (N * S, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM)))
    return img.convert("RGBA")


def bezier(p0, c1, c2, p3, steps=28):
    pts = []
    for k in range(1, steps + 1):
        t = k / steps
        u = 1 - t
        pts.append((
            u**3 * p0[0] + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t**3 * p3[0],
            u**3 * p0[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t**3 * p3[1],
        ))
    return pts


def path(start, *segments):
    """('L', nokta) ve ('C', kontrol1, kontrol2, nokta) parçalarından çokgen üretir."""
    pts = [start]
    for seg in segments:
        if seg[0] == "L":
            pts.append(seg[1])
        else:
            pts.extend(bezier(pts[-1], seg[1], seg[2], seg[3]))
    return pts


def foreground(scale=1.0, dy=0):
    """Saydam zemin üzerinde simge içeriği; [scale] merkez etrafında küçültür."""
    img = Image.new("RGBA", (N * S, N * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def t(points):
        return p([(512 + (x - 512) * scale, 512 + (y - 512) * scale + dy) for x, y in points])

    def circle(cx, cy, r, fill):
        (x0, y0), (x1, y1) = t([(cx - r, cy - r), (cx + r, cy + r)])
        d.ellipse([x0, y0, x1, y1], fill=fill)

    def line(points, width, fill):
        d.line(t(points), fill=fill, width=round(width * S * scale), joint="curve")
        for x, y in points:
            circle(x, y, width / 2, fill)

    rear, front, wy, wr = 292, 748, 676, 102

    # Yol çizgisi.
    line([(150, 792), (874, 792)], 14, (45, 212, 191, 90))

    # Gövde: sivri kuyruk → basamaklı sele → ayaklık → öne uzanan grenaj.
    body = path(
        (128, 470),
        ("C", (190, 440), (250, 420), (318, 410)),      # kuyruk üstü
        ("C", (360, 404), (392, 420), (410, 448)),      # yolcu selesi basamağı
        ("C", (450, 452), (500, 456), (530, 476)),      # sürücü selesi
        ("C", (556, 500), (566, 548), (600, 566)),      # seleden ayaklığa iniş
        ("L", (648, 566)),
        ("C", (676, 520), (694, 440), (712, 368)),      # bacak siperi
        ("C", (740, 350), (772, 352), (792, 372)),      # gidon altı
        ("C", (838, 400), (880, 440), (896, 486)),      # burun
        ("C", (880, 520), (850, 548), (812, 566)),      # far altı
        ("C", (770, 590), (700, 620), (640, 632)),      # ön alt
        ("L", (340, 640)),
        ("C", (270, 632), (210, 600), (176, 552)),      # arka alt
        ("C", (156, 524), (140, 498), (128, 470)),
    )
    d.polygon(t(body), fill=TEAL)

    # Sele.
    seat = path(
        (236, 428),
        ("C", (270, 408), (300, 398), (330, 398)),
        ("C", (366, 398), (394, 414), (412, 440)),
        ("C", (452, 444), (498, 448), (528, 470)),
        ("C", (470, 462), (330, 444), (236, 428)),
    )
    d.polygon(t(seat), fill=LIGHT)

    # Ön cam: geriye yatık, ince.
    screen = path(
        (716, 372),
        ("C", (724, 320), (742, 262), (770, 222)),
        ("L", (792, 232)),
        ("C", (778, 280), (776, 330), (790, 374)),
        ("C", (766, 356), (740, 356), (716, 372)),
    )
    d.polygon(t(screen), fill=TEAL_DARK)

    # Gidon ve ayna.
    line([(676, 366), (734, 352)], 22, LIGHT)
    # Far.
    lamp = path(
        (838, 432),
        ("C", (866, 448), (886, 466), (894, 488)),
        ("C", (876, 496), (856, 494), (840, 484)),
        ("C", (834, 466), (834, 448), (838, 432)),
    )
    d.polygon(t(lamp), fill=LIGHT)
    # Egzoz.
    line([(170, 622), (318, 660)], 36, TEAL_DARK)

    # Tekerlekler: çevresinde boşluk, lastik halkası, jant.
    for cx in (rear, front):
        circle(cx, wy, wr + 18, BG_GAP)
        circle(cx, wy, wr, LIGHT)
        circle(cx, wy, wr - 32, BG_GAP)
        circle(cx, wy, 24, TEAL)
    return img


def rounded_mask(radius):
    m = Image.new("L", (N * S, N * S), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, N * S - 1, N * S - 1], radius=radius * S, fill=255)
    return m


def full_icon():
    img = background()
    img.alpha_composite(foreground(scale=0.84, dy=-40))
    return img


def export_android(res_dir):
    """Android başlatıcı simgeleri: eski tip PNG'ler ve uyarlanabilir simge katmanları."""
    import os

    legacy = full_icon()
    legacy.putalpha(rounded_mask(190))
    adaptive_fg = foreground(scale=0.60, dy=-28)   # içerik güvenli bölgede (orta %66)
    adaptive_bg = background()
    for density, factor in {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}.items():
        folder = os.path.join(res_dir, f"mipmap-{density}")
        os.makedirs(folder, exist_ok=True)
        size = round(48 * factor)
        layer = round(108 * factor)
        legacy.resize((size, size), Image.LANCZOS).save(os.path.join(folder, "ic_launcher.png"))
        adaptive_fg.resize((layer, layer), Image.LANCZOS).save(
            os.path.join(folder, "ic_launcher_foreground.png"))
        adaptive_bg.resize((layer, layer), Image.LANCZOS).convert("RGB").save(
            os.path.join(folder, "ic_launcher_background.png"))
    # Bildirim çubuğu simgesi: tek renk (beyaz) siluet; sistem kendi rengiyle boyar.
    alpha = foreground(scale=0.92, dy=-30).getchannel("A")
    status = Image.new("RGBA", alpha.size, (255, 255, 255, 0))
    status.putalpha(alpha)
    for density, factor in {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}.items():
        folder = os.path.join(res_dir, f"drawable-{density}")
        os.makedirs(folder, exist_ok=True)
        size = round(24 * factor)
        status.resize((size, size), Image.LANCZOS).save(os.path.join(folder, "ic_stat_turkmax.png"))

    anydpi = os.path.join(res_dir, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, "ic_launcher.xml"), "w") as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''')


if __name__ == "__main__":
    # Kullanım: python3 tool/make_icon.py   (depo kökünden; Pillow gerekir)
    export_android("android/app/src/main/res")
    preview = full_icon()
    preview.putalpha(rounded_mask(230))
    preview.resize((512, 512), Image.LANCZOS).save("docs/icon.png")
