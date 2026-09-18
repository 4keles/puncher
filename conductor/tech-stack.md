# Teknoloji Yığını — Puncher

> Bu yığın, `conductor/research/` altındaki beş araştırma raporunun bulgularına
> dayanır. Değişiklikler implementasyondan **önce** burada belgelenmelidir
> (bkz. `workflow.md` → Yol Gösterici İlkeler).

## Temel Karar: Saf Lua

Eklenti **tamamen Aseprite'ın gömülü Lua ortamında** çalışır. Harici binary,
Python yorumlayıcısı veya başka bir runtime bağımlılığı **yoktur**.

Gerekçe:

- İhtiyaç duyulan tüm ilkel işlemler API'de native mevcut (aşağıdaki tablo).
- `os.execute` / `io.popen` kullanıcıya "Give Script Full Access" izin diyaloğu
  çıkarır; bu, topluluğa dağıtılan bir eklenti için ciddi kurulum sürtünmesidir.
- Aseprite izin sistemini sıkılaştıran bir revizyon yaptı (PR #5965, 14 Eylül
  2026: `permissions.json` + BLAKE3 bütünlük kontrolü) — harici süreç çağırma
  yolu daralıyor.
- Ekosistem normu saf Lua; Python/ImageMagick kullanan bilinen bir Aseprite
  eklentisi bulunamadı. Cross-platform binary paketleme ayrıca bilinen bir
  soruna yol açıyor (GitHub Issue #5162: uzantısız executable'lar kurulumda
  bozuluyor).

## Platform ve Sürüm Hedefi

| Kalem | Karar |
| --- | --- |
| Dil | Lua 5.4 (Aseprite gömülü) |
| Minimum Aseprite | **v1.3-rc7** (API v26 — `canvas` widget bu sürümde geldi) |
| Hedeflenen | **v1.3.11+** (stable; `GraphicsContext` on `Image` dahil) |
| Runtime bağımlılığı | Yok |

Sürüm eşiğinin gerekçesi: `canvas` widget (API v26 / v1.3-rc7), native `json`
(API v25 / v1.3-rc5) ve `Image.bytes` (API v15 / v1.2.30) — üçü birden ancak
v1.3-rc7'den itibaren garanti.

## Kullanılacak API Yüzeyleri

| İhtiyaç | API | Not |
| --- | --- | --- |
| Hızlı piksel işleme | `Image.bytes`, `Image.rowStride` | Ham buffer'ı string olarak al, işle, tek seferde geri yaz. Performans-kritik yol budur. |
| Piksel okuma/yazma (basit) | `image:pixels()`, `Image:getPixel` | Yalnızca küçük bölgelerde. |
| Piksel yazma | `Image:drawPixel` | `putPixel` **kullanılmayacak** — deprecated ve her çağrıda undo kaydı üretiyor. |
| Kompozisyon | `Image:drawImage(img, pos, opacity, blendMode)` | VFX katmanlarının birleştirilmesi. |
| Pixel-art güvenli ölçekleme/döndürme | `Image:resize{ method='rotsprite' }` | RotSprite native olarak mevcut — kendi implementasyonumuza gerek yok. |
| Yerleşik komutlar | `app.command.X{...}` | `Rotate`, `SpriteSize`, `CanvasSize` vb. |
| Non-destructive işlem | `app.transaction(fn, "label")` | Her komut tek transaction; içeride `error()` → otomatik rollback. |
| Arayüz | `Dialog` + `canvas` widget | `onpaint(ev)` → `ev.context` (GraphicsContext); `onmousemove`, `dlg:repaint()`. Canlı önizleme için. |
| Metadata | native `json`, `sprite.properties`, `layer.properties`, user data | Komutlar arası sözleşme + dışa aktarılan game-feel verisi. |
| Anchor/pivot | `Slice` (+ pivot alanı) | Karakter anchor noktalarının saklanması. |
| Dosya sistemi | `app.fs` | Yol işlemleri ve dizin listeleme (yazma için `io.open`, sadece export akışında). |

**Bilinen risk:** `canvas` widget için resmi bir FPS garantisi yok. Canlı
önizleme performansı Faz 1'de erken bir prototiple ölçülecek; yetersizse
önizleme tek kare / düşük çözünürlüğe düşürülür (bkz. `product-guidelines.md`
madde 4).

## Kod Mimarisi

```
core/        Saf Lua. Aseprite API'sine SIFIR referans.
             easing, curves, arcs, squash&stretch, particle sim,
             color (OKLab), quantize, dither, geometry, rng.
             → LuaUnit ile headless test edilir, coverage hedefi >%80.
adapter/     Aseprite API sarmalayıcısı. core'un ürettiği saf veriyi
             (piksel matrisi, transform listesi) Image/Cel/Layer/Tag'e çevirir.
commands/    Menü komutları ve Dialog'lar (Ingest Sheet, Pixelate,
             Apply Motion, Add VFX, Export). Coverage hedefinden muaf.
presets/     Veri: animasyon preset parametreleri, VFX parametreleri, paletler.
assets/      Örnek karakterler, test fixture'ları, referans (altın) çıktılar.
```

Bu ayrım pazarlık konusu değildir: `core/` katmanının Aseprite'tan bağımsız
olması, hem test stratejisinin hem coverage hedefinin ön koşuludur.

## Algoritmik Kararlar

| Alan | Seçim | Elenen |
| --- | --- | --- |
| Renk kuantizasyonu | Wu / median-cut + k-means refinement (libimagequant modeli), `Image.bytes` üzerinde | Gerstner et al. joint superpixel+palet optimizasyonu (NPAR 2012) — kalite en yüksek ama iteratif ve saniyeler mertebesinde → **v2** |
| Renk mesafesi | **OKLab** Öklid mesafesi | RGB (algısal olarak yanlış), CIELAB (mavi bölgede hue kayması) |
| Dithering | **Bayer (ordered)** 4x4/8x8, varsayılan **kapalı** | Floyd-Steinberg — kareler arası "kayan" gürültü animasyonda titreşim yaratıyor |
| Rotasyon/ölçekleme | Native `rotsprite` + pixel-grid snapping + sub-pixel accumulator | Naif nearest/bilinear rotasyon (jaggy, bulanıklık) |
| Deformasyon | Parça bazlı affine (sheet'ten kesilen head/torso/arm/leg + pivot) | Tam mesh warping / ARAP — gereksiz karmaşıklık |
| Pixelization (AI) | Yok | GAN/diffusion pixelization — kareler arası palet ve grid tutarsızlığı, GPU bağımlılığı → **v2 opsiyonu** |
| Screen shake / hitstop | JSON metadata olarak dışa aktarım | Aseprite canvas'ında gerçek ekran sarsıntısı mümkün değil |

## Test ve Kalite Altyapısı

| Katman | Araç | Not |
| --- | --- | --- |
| Çekirdek birim testleri | **LuaUnit** (sistem Lua 5.4 ile) | `core/` Aseprite'a bağımlı olmadığı için CI'da doğrudan çalışır. |
| Entegrasyon testleri | `aseprite --batch --script tests/integration/*.lua` | Headless; exit code + assert tabanlı. |
| Görsel regresyon | Altın PNG karşılaştırma | Referans çıktılar `assets/` altında; kasıtlı değişiklikler commit mesajında belirtilir. |
| Lint | `luacheck` | |
| Format | `stylua` | |
| CI | GitHub Actions | Çekirdek testler + lint CI'da koşar. Aseprite gerektiren entegrasyon testleri yerelde koşar; EULA gereği derlenen Aseprite binary'si public artifact olarak paylaşılmaz. |

## Paketleme ve Dağıtım

- Format: `.aseprite-extension` (zip içinde `package.json` + Lua kaynakları).
- `package.json` → `contributes.scripts: [{ path: "./..." }]`.
- Lisans: **MIT** (ekosistem normu; thkwznk ve diğer büyük koleksiyonlar MIT).
- Kanallar: GitHub Releases + itch.io. Merkezi bir resmi eklenti mağazası yok.
- Aseprite EULA yalnızca Aseprite binary'sinin yeniden dağıtımını yasaklar;
  üçüncü parti eklentilerin satılması/dağıtılması serbesttir.

## Konumlandırma Notu (rekabet)

`pozac.itch.io` prosedürel Aseprite FX araçları satıyor (Impact/Explosion FX,
Spin Motion FX vb.) — "prosedürel VFX üreteci" alanı boş değil. Ancak bu araçlar
karaktere kör: bir cel/selection alıp jenerik transform veya parçacık uygular.
Puncher'ın farkı **character-aware** olmasıdır: karakter sheet'ini okur (silüet,
bbox, anchor), ona özgü aksiyon pose'ları üretir ve VFX'i bu harekete
senkronlar. Bu ayrım hem teknik tasarımı hem de ürünün konumlandırmasını
yönlendirir.

## Referans Alınacak Projeler

| Proje | Ne için |
| --- | --- |
| `thkwznk/aseprite-scripts` | Dialog/GUI kod yapısı, tween ("Add Inbetween Frames") yaklaşımı |
| `PKGaspi/AsepriteScripts` (PathAnimator) | Yol tabanlı çoklu-layer hareket mantığı |
| `aseprite/Aseprite-Script-Examples` | Resmi API örnekleri |
| Pozac FX serisi | Prosedürel VFX parametre tasarımı (seeded RNG, preset yapısı, layer ayrımı) |
| `MalloyTheDev/aseprite-mcp` | Headless batch mimarisi — test harness tasarımı için ilham |
