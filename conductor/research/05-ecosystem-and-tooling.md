# Araştırma 05 — Ekosistem, Rekabet ve Araç Seçimi

*Tarih: 2026-09-18 · Amaç: konumlandırma, referans projeler, bağımlılık ve test
stratejisi.*

## 1. Mevcut Aseprite Script/Extension Ekosistemi

| Proje | URL | Bizim için değeri |
| --- | --- | --- |
| **thkwznk/aseprite-scripts** | <https://github.com/thkwznk/aseprite-scripts> | En bilinen genel koleksiyon: advanced scaling, "Add Inbetween Frames" (tween), Analyze Colors. Temiz Lua yapısı ve dialog/GUI pattern'leri için birincil referans. |
| **PKGaspi/AsepriteScripts** | <https://github.com/PKGaspi/AsepriteScripts> | Export araçları + **PathAnimator** (yol tabanlı çoklu-layer animasyon). Path hareketi için doğrudan referans. |
| **projectitis/aseprite-community-script-collection** | <https://github.com/projectitis/aseprite-community-script-collection> | Tween, "Ghost Images" (onion-skin benzeri), Palettize. Topluluk katkı formatı. |
| **sandord/aseprite-scripts** | <https://github.com/sandord/aseprite-scripts> | Genel örnekler. |
| **aseprite/extensions** (resmi) | <https://github.com/aseprite/extensions> | Resmi dağıtım referansı. |
| **aseprite/Aseprite-Script-Examples** | <https://github.com/aseprite/Aseprite-Script-Examples> | Resmi API örnekleri. |
| **Tween Machine** | <https://carbscode.itch.io/the-tween-machine> | Keyframe arası interpolasyon toolbar'ı. |
| **Asepritely** | <https://iivii.itch.io/asepritely> | Pay-what-you-want script kütüphanesi. |
| **Pozac FX serisi** | <https://pozac.itch.io> | **En yakın rakip** — aşağıya bakınız. |
| **JanBremec — Tiny Impact & Motion** | <https://janbremec.itch.io/tiny-impact-motion-pixel-fx> | 18 hazır hit/dash/landing FX (PNG + .aseprite). Prosedürel değil, statik asset paketi. |

## 2. Boşluk Analizi — Dürüst Değerlendirme

**Doğrudan rakip var.** Pozac (<https://pozac.itch.io>) bir Aseprite prosedürel
FX stüdyosu işletiyor:

- **Impact/Explosion FX** ($4.99) — flash, shockwave, debris, smoke, bolt;
  seeded RNG, gravity/drag/turbulence/vortex
- **Spin Motion FX** ($1.99) — rotation/scale/orbit/bounce/shake; squash &
  stretch, impact animasyonu için öneriliyor
- Ayrıca Magic Spell FX, Smoke Flow FX, Wave Motion FX, Path Animator FX

Yani "prosedürel impact VFX üretimi" boşluğu **kapalı**.

**Ancak** bu araçlar jenerik transform/parçacık üreteçleri: karaktere ve sheet'e
kördürler, bir cel/selection'ı girdi alıp döndürür veya parçalar. **Karakter
sheet'ini okuyup** (silüet, bbox, anchor noktaları) buna göre dash/punch/jump/
teleport pose'ları otomatik üreten hiçbir araç bulunamadı.

**Farkımız:** *character-aware* prosedürel aksiyon + senkron impact VFX
kombinasyonu — yalnızca bir VFX katmanı değil.

## 3. Aseprite Dışı Araçlar

| Araç | Fiyat | Not |
| --- | --- | --- |
| **PixelOver** (<https://pixelover.io>) | $19-30 | Godot tabanlı; bone rig + IK, non-destructive dithering/indexation, 3D import. En yakın ticari ürün ama ayrı bir editör, Aseprite'a entegre değil. |
| **Juice FX** (CodeManu) | ~$15 | Oyun motoru içi "juice" (flash/shake/wobble); spritesheet export var, Aseprite'ta çalışmıyor. |
| **Pixelorama** | MIT, ücretsiz | Hızla olgunlaşıyor; prosedürel VFX yok. |
| **LibreSprite / Piskel** | ücretsiz | Prosedürel VFX yok; Piskel pasif. |

## 4. Harici Bağımlılık Değerlendirmesi

- FFmpeg bundling örneği var (webm export; PATH'te ffmpeg gerekiyor) — precedent
  mevcut.
- Ancak GitHub Issue #5162: uzantı içine binary gömmek riskli — uzantısız
  executable'lar kurulumda "Aseprite.app Document" formatına dönüştürülüp
  çalışmaz hale geliyor; workaround dosya uzantısı gerektiriyor.
- Python/Pillow/ImageMagick kullanan bilinen bir Aseprite extension **bulunamadı**;
  ekosistem neredeyse tamamen saf Lua.
- Dağıtım maliyeti (cross-platform binary, güvenlik izni istemi, kurulum
  sürtünmesi) yüksek.

**Karar: harici bağımlılıktan kaçınılıyor.**

## 5. MCP ve AI Entegrasyonu

Aseprite'a özel birden fazla MCP server mevcut:

- <https://github.com/MalloyTheDev/aseprite-mcp> (96 tool, headless batch
  üzerinden)
- <https://github.com/willibrandon/pixel-mcp>
- <https://github.com/vchopDev/libresprite-mcp>
- npm: `@iborymagic/aseprite-mcp`

Bunlar doğrudan geliştirme aracımız değil, ancak **"Aseprite'ı headless/batch
modda script üreterek yönetme" mimarisi** test harness tasarımımız için hazır
referans. Blender MCP ayrı bir alan, doğrudan ilgisiz.

## 6. Lisans ve Dağıtım

- Aseprite EULA yalnızca **Aseprite binary'sinin** yeniden dağıtımını yasaklar;
  kendi script/extension'ınızı satmak serbest (Pozac'ın tüm mağazası bunu
  doğruluyor).
- Açık kaynakta **MIT** en yaygın tercih (thkwznk).
- Ücretli + ücretsiz karma model (itch.io) ekosistemde normalleşmiş.

## 7. Test Altyapısı

- `aseprite --batch --script` headless çalışıyor, CI için uygun.
- GitHub Actions ile kaynaktan derleme yaygın ve sahibi tarafından onaylı
  (setup-aseprite-cli-action, aseprite-auto-build). Steam binary'si otomasyona
  kapalı; EULA gereği derlenen binary public artifact olarak paylaşılmamalı.
- **LuaUnit** ve **busted** genel Lua test framework'leri mevcut, ancak
  Aseprite-Lua runtime'ına (app/Sprite gibi özel globaller) doğrudan entegre bir
  örnek bulunamadı.

**Sonuç:** mantığı saf Lua modüllerine ayırıp LuaUnit ile izole test etmek;
Aseprite'a bağımlı kısmı batch-mode script + exit code assertion ile test etmek.

## Stratejik Çıkarım

1. **Rekabet:** Pozac prosedürel FX alanını dolduruyor. "Sadece VFX üretici"
   konumlandırması zayıf. Fark: karakter sheet'ini okuyup ona özgü aksiyon
   pose'ları + senkron VFX üretmek — *character-aware* vurgusu öne çıkmalı.
2. **Öğrenilecekler:** thkwznk'tan dialog/GUI kod yapısı, Gaspi'nin
   PathAnimator'ından path tabanlı hareket mantığı, Pozac'tan prosedürel VFX
   parametre tasarımı (seeded RNG, preset yapısı, layer ayrımı).
3. **Harici bağımlılık:** Kaçın — saf Lua'da kal. Tek gerekçe gelişmiş
   dithering/quantization ihtiyacı olursa yeniden değerlendirilir.
4. **MCP/araçlar:** Aseprite'a özel MCP geliştirme için gerekmiyor;
   `MalloyTheDev/aseprite-mcp` mimarisi test harness tasarımı için incelenmeli.
5. **Test stratejisi:** Mantık katmanı saf Lua + LuaUnit (izole); Aseprite'a
   bağımlı katman `--batch --script` ile entegrasyon testi.
