# Araştırma 02 — Görüntüden Pixel Art'a Dönüşüm Algoritmaları

*Tarih: 2026-09-18 · Amaç: `Pixelate` komutunun algoritmik hattını belirlemek.*

## Renk Kuantizasyonu

Median cut ve Wu, RGB kutusunu böler; k-means piksel kümeler. Median cut en
hızlı, Wu kalite/hız dengesi daha iyi. Küçük paletlerde (8-32 renk) en iyi
sonucu **hibrit** yaklaşımlar veriyor: Wu ile deterministik başlangıç, ardından
k-means / Voronoi iterasyonu ile lokal optimuma çekme.

**libimagequant / pngquant** tam olarak bunu yapar: variance tabanlı median
cut'ı zayıf temsil edilen renklere ağırlık vererek tekrarlar, sonra Voronoi
(k-means) iterasyonuyla düzeltir; dithering'i yalnızca kenar olmayan homojen
bölgelerde uygular (adaptive error diffusion). Saf median cut'tan belirgin daha
temiz sonuç verir.

Kaynaklar: <https://pngquant.org/lib/>,
<http://blog.pkh.me/p/39-improving-color-quantization-heuristics.html>

## Palet Eşleme ve Renk Uzayı

CIELAB mavi tonlarda mor yönüne hue kayması gibi algısal kusurlara sahip.
**OKLab / OKLCh** bunu düzeltir: açıklık/koyulukta hue sapması yok, Öklid
mesafesi doğrudan algısal farkı temsil ediyor, piksel başına maliyeti düşük.
Sabit palete (DB16, PICO-8, AAP-64) eşlemede OKLab mesafesi RGB'den belirgin
daha isabetli.

**Hue shifting** (gölgede soğuk/mora, ışıkta sıcak/sarıya kayma) klasik pixel
art tekniğidir ve matematiksel olarak HSL/OKLCh'de hue açısını value'ya bağlı
lineer/eğrisel kaydırma olarak modellenebilir — ramp üretimi tamamen
otomatikleştirilebilir.

Kaynaklar: <https://bottosson.github.io/posts/oklab/>,
<https://www.pixel-editor.com/articles/color-theory-for-pixel-art>

## Dithering

| Yöntem | Değerlendirme |
| --- | --- |
| **Bayer (ordered)** | Düzenli, tile-friendly, **animasyonda stabil** — kareler arası desen kaymaz. Karakter sprite'ları için en uygun. |
| Floyd-Steinberg | Fotoğrafta iyi, pixel art'ta kirli/gürültülü. Kareler arası "kayan" gürültü **animasyonda titreşim (temporal noise)** yaratır → elendi. |
| Blue noise | En organik ama karakter sprite'ı için fazla; doku/arka plan için uygun. |
| Kapalı | Küçük sprite, az palet, net silüet gereken durumlarda en iyisi. |

En dengeli yöntem libimagequant'ın yaptığı gibi dithering'i yalnızca gradyan
bölgelerde şartlı uygulamaktır.

Kaynaklar: <https://www.ascii-magic.com/blog/complete-guide-to-dithering>,
<https://surma.dev/things/ditherpunk/>

## Downscaling ve Gerstner et al.

"Pixelated Image Abstraction" (Gerstner, DeCarlo, Alexa, Finkelstein, Gingold,
Nealen — **NPAR 2012**) superpixel benzeri bölgeleri ve azaltılmış paleti
**birlikte** optimize eder ("mass-constrained deterministic annealing"): bölge
ataması ve renk merkezleri simultane çözülür. Basit nearest-neighbor veya
area-average ince hatları ve silueti bozarken bu yöntem pixel sanatçılarının
elle yaptığına yakın sonuç verir (kullanıcı çalışmasıyla doğrulanmış).

**Maliyet:** iteratif optimizasyon, saniyeler mertebesinde — gerçek zamanlı
değil. Lua'da pratik değil; v2 hedefi.

Daha ucuz alternatif: kenarları tespit edip downscale kernelini hizaya kaydırmak
(content-adaptive / edge-aware downscaling; Kopf et al. SIGGRAPH Asia 2013 ile
aynı aile).

Kaynaklar:
<https://pixl.cs.princeton.edu/pubs/Gerstner_2012_PIA/index.php>,
<https://pixl.cs.princeton.edu/pubs/Gerstner_2012_PIA/Gerstner_2012_PIA_full.pdf>,
<https://yogthos.net/posts/2025-12-11-edge-aware-pixelation.html>

## Temizlik Adımları

Anti-aliasing kaldırma, jaggy düzeltme, outline üretimi ve izole piksel
temizliği açık kaynak bir araçta birleşik olarak mevcut: **PixelRefiner**
(tarayıcı tabanlı) — OKLab + k-means kuantizasyon, 8-way/4-way outline üretimi,
"Off/Light/Auto/Strong" gürültü temizleme modları. Mimari referans olarak
değerli.

Kaynak: <https://github.com/HappyOnigiri/PixelRefiner>

## Alfa

Basit eşikleme yaygın pratik: `alpha < eşik` → tamamen şeffaf, üstü → tam opak.
Kenar bulanıklığını (alpha bleed) 1-bit alfaya indirger. Pixel art nadiren
gradyan alfa gerektirir.

## AI Yaklaşımları ve Temporal Consistency

"Make Your Own Sprites: Aliasing-Aware and Cell-Controllable Pixelization"
(SIGGRAPH Asia 2022) süreci cell-aware ve aliasing-aware iki aşamaya ayırır;
referans pixel art ile grid/cell yapısını regularize eder. Ancak bu ve diffusion
tabanlı yaklaşımlar (Sprite Sheet Diffusion, arXiv 2412.03685) **kare-kare
bağımsız üretimde palet ve grid hizasını kaydırabiliyor.**

Tutarlılık için gerekenler: (a) paleti bir kez sabitleyip tüm karelere zorla
eşlemek, (b) grid hizasını ilk karede tespit edip sabit tutmak, (c) karakter
kimliği kısıtları. Pratikte AI adımı yalnızca ilk taslak olabilir; ardından
deterministik post-processing (palet kilitleme + grid hizalama) zorunludur.

Kaynaklar: <https://github.com/WuZongWei6/Pixelization>,
<https://arxiv.org/pdf/2412.03685>

## Kütüphaneler

Python tarafında Pillow, numpy/scikit-image (`skimage.segmentation.slic`),
**hitherdither** (<https://github.com/hbldh/hitherdither>), libimagequant
bağlamaları mevcut. Lua'da median cut / k-means yazılabilir; SLIC tabanlı
superpixel optimizasyonu Lua'nın performans sınırları nedeniyle pratik değil.

## Önerilen Pipeline

Etiketler: **[L]** = Lua'da yapılabilir · **[X]** = harici araç gerektirir
(bizim kararımız: **[X]** adımlar v2'ye ertelendi, MVP yalnızca **[L]**
adımlarla kurulur).

1. **[L]** Girdi normalizasyonu (opsiyonel blur/resize temizliği).
2. **[X]** Hedef çözünürlük tespiti (kenar-frekans / Fourier analizi) — MVP'de
   kullanıcıdan alınır.
3. **[X]** Edge-aware veya Gerstner tarzı downscale — MVP'de basit area-average
   + kenar koruma heuristiği.
4. **[L/X]** Renk kuantizasyonu: Wu ile başlangıç paleti (8-32 renk) + k-means
   refinement, mesafe ölçütü OKLab. `Image.bytes` üzerinde Lua'da yapılabilir;
   çok renkli büyük görsellerde yavaşlayabilir.
5. **[L]** Sabit palete eşleme (kullanıcı DB16/PICO-8/AAP-64 seçtiyse): OKLab
   mesafesiyle en yakın renge snap.
6. **[L]** Dithering kararı: karakter sprite'ları için **varsayılan kapalı**;
   istenirse Bayer 4x4/8x8. Floyd-Steinberg asla.
7. **[L]** Anti-aliasing / jaggy temizliği: 3x3 komşuluk çoğunluk oyu ile izole
   piksel temizliği.
8. **[L]** Outline üretimi (opsiyonel): 4-way/8-way sabit veya koyulaştırılmış
   kontur.
9. **[L]** Alfa eşikleme (ör. %25 altı → 0, üstü → 255).
10. **[L]** **Palet ve grid kilitleme:** 4-5. adımda üretilen palet ve grid
    hizası TÜM karelere zorla uygulanır. Animasyon tutarlılığı için kritik.
11. **[X, v2]** AI tabanlı ön-taslak (GAN/diffusion pixelization) + 4-10 arası
    deterministik pipeline'dan geçirme.

MVP notu: 3-5. adımların en pahalı kısmı atlanabilir; Wu + k-means tek başına,
basit downscale ile kabul edilebilir sonuç verir.
