# Araştırma 01 — Aseprite Lua API: Yetenekler ve Sınırlar

*Tarih: 2026-09-18 · Amaç: mimari kararı (saf Lua mı, harici yardımcı mı) kanıta
bağlamak.*

## 1. API Yüzeyi

`Sprite`, `Image`, `Layer`, `Cel`, `Frame`, `Tag`, `Palette`, `Slice`,
`Selection`, `Color`, `GraphicsContext`, `Timer`, `WebSocket` sınıflarının hepsi
mevcut.

- `Image:getPixel(x, y)` → integer renk değeri.
- `Image:putPixel` **deprecated**; yerine `drawPixel` (undo kaydı üretmez).
- `image:pixels([rect])` iterator: `it()` oku, `it(val)` yaz, `it.x` / `it.y`
  konum.
- `drawImage()` blend mode + opacity ile kompozisyon; `drawSprite()` belirli bir
  frame'i render eder.

Kaynak: <https://github.com/aseprite/api/blob/main/api/image.md>

## 2. Performans

Per-pixel Lua döngüsü çalışır ama yavaştır. Topluluk ölçümleri tutarsız (ör.
tüm piksellerin işlenmesi, seçici işlemeden daha hızlı çıkabiliyor — JIT / undo
tracking artefaktı). 64x64 × 20 kare ölçeği `getPixel/drawPixel` ile muhtemelen
kabul edilebilir, ancak garanti değil.

**Hızlandırma yolu:** `Image.bytes` + `Image.rowStride` (API v15, Aseprite
v1.2.30+) ile ham byte buffer'ı string olarak alıp işlemek ve tek seferde geri
yazmak — C'ye yakın hız.

`putPixel` her çağrıda undo bilgisi ürettiği için performans-kritik yollarda
`drawPixel` kullanılmalı.

Kaynaklar: <https://github.com/haloflooder/Aseprite-Scripts/wiki>,
<https://github.com/aseprite/api/blob/main/api/image.md>

## 3. Dialog API ve Canlı Önizleme

Widget seti: `canvas`, `slider`, `combobox`, `color`, `file`, `shades`, `entry`,
`button`, `check`, `radio`, `separator`, `tab`.

`canvas` widget canlı önizlemeyi destekler:

- `onpaint(ev)` → `ev.context` (GraphicsContext) ile çizim
- `onmousemove` / `onmousedown` / `onmouseup` / `onwheel` / `onkeydown`
- `dlg:repaint()` ile yeniden çizim tetiklenir

**Sınır:** Resmi bir FPS garantisi dokümante edilmemiş. Gerçek zamanlı animasyon
örnekleri toplulukta var, ama sürekli repaint senaryosunda performans deneyle
doğrulanmalı. `canvas` widget API v26 / Aseprite v1.3-rc7'den itibaren mevcut.

Kaynaklar: <https://github.com/aseprite/api/blob/main/api/dialog.md>,
<https://community.aseprite.org>

## 4. Dönüşümler

- `Image:resize()` bilinear **ve `'rotsprite'`** metodunu destekler — RotSprite
  algoritmasına native erişim var, kendi implementasyonumuza gerek yok.
- `flip()` yatay/dikey.
- `app.command.Rotate{angle=...}`, `app.command.SpriteSize`,
  `app.command.CanvasSize`, `app.command.FlattenLayers` gibi düzinelerce
  yerleşik komut `app.command.X{param=...}` sözdizimiyle çağrılabilir;
  `.enabled` ile durum kontrolü yapılabilir.
- Dokümante edilmeyen komut parametreleri için `gui.xml` / kaynak koda bakmak
  gerekiyor.

## 5. Undo / Transaction

`app.transaction(function() ... end, "label")` birden fazla değişikliği tek undo
adımına gruplar. İçeride `error()` fırlatılırsa değişiklikler otomatik geri
alınır. Non-destructive akışın temel yapı taşı.

Kaynak: <https://github.com/aseprite/api/blob/main/api/app.md>

## 6. Sandbox ve Dış Dünya Erişimi

- Script ortamı sandboxed; bazı standart Lua fonksiyonları (`os.exit` vb.) yok.
- `os.execute` / `io.open` / `io.popen` **kullanıcı izni gerektiriyor** ("Give
  Script Full Access" onayı).
- `app.fs` dosya/dizin listeleme ve yol işlemleri sağlar, ancak **rastgele dosya
  yazma fonksiyonu içermez** (yazma için ham `io.open(path, "w")` + izin).
- **Önemli risk:** Aseprite izin sistemini köklü şekilde revize eden PR #5965'i
  (14 Eylül 2026, beta) merge etti: ini tabanlı izinlerden `permissions.json` +
  BLAKE3 bütünlük kontrolü + ayrı "debug" izin katmanına geçiş. Harici binary
  çağırma UX'i yakın gelecekte daha sürtünmeli hale gelebilir.

Kaynaklar: <https://community.aseprite.org>,
<https://github.com/aseprite/aseprite/pull/5965>

## 7. JSON, HTTP, Kütüphane Yükleme

- **Native `json.encode` / `json.decode`** API v25 (v1.3-rc5) itibarıyla global
  `json` namespace olarak mevcut — harici kütüphane gerekmiyor.
- HTTP için native fonksiyon yok; ancak **native `WebSocket` sınıfı** var (API
  v15, v1.2.30+) — harici bir süreçle yerel soket üzerinden haberleşmek için
  `os.execute`'tan daha "izin dostu" bir kanal (bkz. PR #2980).
- `require()` API v23 (v1.3-rc3+) ile mevcut; topluluk pratikte
  `dofile('./lib.lua')` yöntemini daha güvenilir buluyor.

Kaynaklar: <https://github.com/aseprite/api/blob/main/api/json.md>,
<https://github.com/aseprite/aseprite/pull/2980>

## 8. Extension Paketleme ve Dağıtım

`.aseprite-extension` = zip; içinde en az `package.json` (name, displayName,
version, author, categories, contributes). Script kaydı:
`contributes.scripts: [{ path: "./script.lua" }]`. Ayrıca palettes, themes,
languages, keys için ayrı contributes alanları var.

Dağıtım: itch.io (yaygın; kendi lisansınızı koyabiliyorsunuz), GitHub Releases.
Merkezi resmi bir extension store **yok**; paylaşım community.aseprite.org
üzerinden yapılıyor. Aseprite EULA'sı yalnızca Aseprite'ın kendisinin yeniden
dağıtımını yasaklar, eklentileri etkilemez.

Kaynaklar: <https://aseprite.org/docs/extensions>,
<https://github.com/aseprite/aseprite/blob/main/EULA.txt>

## 9. Sürüm Eşikleri

| API | Aseprite | Gelen özellik |
| --- | --- | --- |
| v14 | v1.2.28 | tilemap |
| v15 | v1.2.30 | **Image.bytes + rowStride, WebSocket** |
| v23 | v1.3-rc3 | Editor, `require()` |
| v25 | v1.3-rc5 | **native json** |
| v26 | v1.3-rc7 | **canvas widget** |
| v30-31 | v1.3.11 | Image üzerinde GraphicsContext |

**Önerilen minimum: v1.3-rc7+; ideal: v1.3 stable / v1.3.11+.**

Kaynak: <https://aseprite.org/api/Changes>

## Mimari Çıkarım

1. **Saf Lua yeterli.** Pixel art dönüşümü, prosedürel animasyon ve VFX katmanı
   için gereken tüm ilkel işlemler native mevcut.
2. **Duvara çarpılacak yer per-pixel döngü performansı.** Zorunlu optimizasyon:
   performans-kritik algoritmaları `Image.bytes` ham buffer üzerinde yaz, tek
   seferde geri yaz.
3. **Canlı önizleme mümkün ama FPS garantisiz.** Faz 1'de erken prototiple
   ölçülmeli.
4. **Harici binary'ye gerek yok, hatta kaçınılmalı:** izin diyaloğu, cross-
   platform derleme yükü, dağıtım karmaşıklığı ve izin sistemi sıkılaşması.
5. **Önerilen mimari:** native `rotsprite` + bytes-buffer üzerinde custom
   quantization/dither; saf Lua matematiksel motion engine; `app.transaction`
   ile preset başına tek undo adımı; VFX ayrı layer'larda `drawImage` + blend
   mode; `Dialog` + `canvas` ile önizleme.
