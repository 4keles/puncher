# Araştırma 04 — Impact VFX Anatomisi ve Pixel Art'ta 2.5D

*Tarih: 2026-09-18 · Amaç: VFX primitif kütüphanesini ve 2.5D aracının
fizibilitesini belirlemek.*

## A) Pixel Art Impact VFX

### 1. Anatomi ve Zamanlama

Impact efektleri genelde impact karesinde (t=0) veya 1 kare önce/sonra tetiklenir.

| Efekt | Kare sayısı | Tetiklenme |
| --- | --- | --- |
| Hit spark | 3-6 | impact anında; ilk kare en parlak/büyük, hızla küçülür-solar |
| White / silhouette flash | 1 (ağır vuruşta 2) | tam impact anı |
| Shockwave ring | 4-8 | impact +0, genişleyerek solar |
| Speed lines | 2-4 | hareketin başlangıcı |
| Radial burst / debris | 6-10 | impact anında patlar, parçacıklar yerçekimiyle düşer |
| Dust puff | 4-6 | temas noktası; yükselip solar |
| Slash / sweep arc | 3-5 | silah hareketiyle senkron |
| Teleport | 4-6 (dağılma) + 4-6 (toplanma) | dikey scanline / noise |

**Genel kural:** setup kareleri kısa (80-100 ms), impact karesi uzun
(150-300 ms) tutularak ağırlık hissi yaratılır — eşit olmayan hold süresiyle
4 kare, 12 kareymiş gibi hissettirilebilir.

Kaynaklar: <https://www.sprite-ai.art/blog/sprite-animation-frames>,
<https://www.youtube.com/watch?v=qcI0mVFZd_U>

### 2. Prosedürel Matematik

- **Shockwave ring:** `radius(t) = r0 + (r1-r0)·easeOutQuad(t)`,
  `alpha = 1 - t²`. Bresenham circle ile çiz, kalınlık 1-2 px sabit.
- **Parçacık sistemi:** `pos += vel·dt; vel.y += gravity·dt; life -= dt`.
  Pixel art'ta parçacık boyutu 1-3 px (çoğu 1 px), sayı 6-16 (fazlası piksel
  çorbası). Ömür ±%20 jitter.
- **Radyal çizgi dağılımı:** N çizgi, `açı = i·(360/N) + random(-jitter, jitter)`,
  jitter 10-20°.
- **Bezier sweep arc:** 3 kontrol noktalı quadratic Bezier; kalınlık başta ince
  sonda kalın (veya tersi) + alfa gradyanı.
- **Teleport dağılma:** her pikseli threshold'lu value/Perlin noise ile rastgele
  sırayla kaybet/göster.

**Pixel art kısıtları:** tüm koordinatlar `math.floor`/round ile grid'e
kilitlenmeli; anti-aliasing kullanılmamalı (piksel ya var ya yok); palet 3-5
renkle sınırlı; çizgiler tek piksel kalınlığında ve 45°/dikey/yatay eğilimli
(Bresenham sapması pixel art'ta göze batar).

### 3. Renk ve Palet

Tipik VFX rampası: **beyaz/açık sarı çekirdek → turuncu/kırmızı → koyu
kırmızı/mor dış hat**. Sıcak-soğuk kontrastı derinlik hissi verir.

Additive blending: Aseprite'ta native olarak mevcut —
`layer.blendMode = BlendMode.ADDITION`. Manuel taklit gerekirse `max(src, dst)`
veya renk rampasında bir üst tona atlama.

**Silhouette flash:** sprite'ın tüm opak piksellerini tek renge (genelde beyaz)
boyama; impact karesinde 1 kare, ağır vuruşlarda 2 kare.

### 4. Game Feel Katmanı

- **Hitstop:** SFV hafif 8f / orta 12f / ağır 15f; Final Fight sabit 6f.
- **Screen shake** (Nijman, *The Art of Screenshake*): genlik atak gücüne göre
  ölçeklenir, süre kısa (birkaç yüz ms), üstel/lineer decay ile sıfıra iner;
  küçük ataklarda minik shake, büyük ataklarda kamera zıplaması + kickback.

**Aseprite kısıtı:** canvas statiktir, gerçek ekran sarsıntısı yoktur.
Seçenekler:

1. Sprite'ın kendisini birkaç piksel kaydırarak shake karelerini sheet'e gömmek
   — arka plan sarsılmadığı için sınırlı fayda.
2. **Ayrı bir `camera_shake` JSON/metadata dosyası export etmek** (amplitude,
   frequency, duration, decay eğrisi) ve oyun motorunda (Godot/Unity)
   tüketilmesi — en pratik ve motor-agnostik çözüm. **Seçilen yol budur.**
3. Hitstop için "freeze frame count" değerini aynı JSON'a yazmak.

Zoom punch ve knockback de aynı metadata yaklaşımıyla (scale curve, displacement
vector) dışa aktarılabilir.

Kaynaklar: <https://www.ssbwiki.com/Hitlag>,
<https://www.youtube.com/watch?v=AJdEqssNZ-U>,
<http://notebook.maryrosecook.com/Theartofscreenshake,JanWillemNijman.html>

### 5. Referans Oyunlar ve Araçlar

Nuclear Throne (yoğun hit-spark + knockback), Dead Cells (parlak additive VFX +
3D pipeline), Hyper Light Drifter (renkli slash arc'ları, kısa hitstop),
Street Fighter / KOF (klasik hit spark tasarımı, sarı-turuncu-beyaz rampa),
Vampire Survivors (basit ama yoğun radial burst + screen shake).

Araçlar: <https://github.com/audoraemon/vfxProve> (Godot prosedürel pixel VFX),
<https://halisavakis.com/my-take-on-shaders-shockwave-effect/>

## B) Pixel Art'ta 2.5D

### 6. Sahte Derinlik

8 yönlü setler 45° aralıklarla üretilir (genelde 4 yön çizilip mirror'lanır;
üst-alt ayrı çizim gerektirir).

İzometrik projeksiyon:

```
screenX = (x - y) · tileW/2
screenY = (x + y) · tileH/2 - z · heightScale
```

Y-sort: çizim sırası `sortKey = worldY (+ z katkısı)`; her sprite kendi taban
noktasına göre sıralanır. 3/4 top-down (Zelda tarzı) en yaygın "2.5D" pixel art
stili.

Kaynak: <https://www.slynyrd.com/blog/2025/3/24/pixelblog-55-top-down-character-animation>

### 7. 3D → Pixel Art Pipeline

**Dead Cells modeli:** basit 3D model + iskelet, düşük çözünürlükte (karakter
~50 px boy) anti-aliasing kapalı render + cell shading, homebrew render aracı.
Avantaj: bir animasyonu dakikalar içinde onlarca varyasyona uyarlama.

**Normal map / Sprite Lamp:** 4 yönden gölgelendirilmiş grayscale görüntüler RG
kanallarına gömülerek normal map üretilir; motorda dinamik ışıklandırma sağlar.

**Puncher'a uygulanabilirliği:** Aseprite 3D render yapamaz. Blender render +
palet kuantizasyon adımı eklentinin **dışında** kalmalı; eklenti en fazla
"render edilmiş kareleri palet kuantize edip içe aktaran" bir yardımcı komut
sunabilir. Tam otomasyon mümkün değil.

Kaynaklar:
<https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i->,
<https://www.gameanim.com/2018/01/31/dead-cells-3d-pipeline-2d-animation/>,
<https://arxiv.org/pdf/2212.09692>

### 8. Sahte 3D Dönüş

- **Horizontal squash:** genişliği `cos(angle)` ile ölçekleyip silüet
  değişimiyle yalancı Y-ekseni dönüşü. Basit ve yaygın.
- **Column-based shear:** dikey sütunları farklı miktarda kaydırma (Mode-7 tarzı
  warp). Düz zeminde iyi, karakter sprite'ında distorsiyon yaratır.

**Sınır:** bu teknikler yalnızca ±30-45° aralığında inandırıcı; tam 360° dönüş
için gerçek 3D render veya elle çizilmiş kareler gerekir. Ölçekleme/shear piksel
grid bozulmasına yol açtığından nearest-neighbor + palet snap zorunlu.

## VFX Kütüphanesi Önerisi (12 primitif)

| # | Primitif | Parametreler | Algoritma |
| --- | --- | --- | --- |
| 1 | **HitSpark** | renk rampası (3 ton), kare (3-6), boyut, yön açısı | merkezden radyal yıldız/çizgi; her karede küçült + sönümlendir |
| 2 | **ImpactFlash** | renk (beyaz), süre (1-2 kare) | hedef sprite'ın opak maskesini tek renkle doldur |
| 3 | **ShockwaveRing** | r0, r1, kalınlık, kare (4-8), renk | Bresenham circle + easeOut radius + alfa/kalınlık azaltımı |
| 4 | **RadialBurstLines** | çizgi (6-16), uzunluk, jitter (10-20°), kare | merkezden Bresenham line; uzat sonra sönümlendir |
| 5 | **DustPuff** | parçacık (6-12), yükselme hızı, ömür | yukarı/yanlara rastgele hareket + koyuluk azalışı |
| 6 | **DebrisParticles** | sayı (8-16), hız aralığı, gravity, ömür, boyut (1-3px) | Euler integrasyonlu parçacık sistemi |
| 7 | **SweepArc** | başlangıç/bitiş açısı, kalınlık eğrisi, kare (3-5) | quadratic Bezier + kalınlık modülasyonu + fade trail |
| 8 | **SpeedLines** | çizgi sayısı, uzunluk, yön, kare (2-4) | hareket vektörüne paralel kısa çizgiler, sprite arkasında |
| 9 | **TeleportDisperse / Gather** | noise threshold eğrisi, scanline yönü, kare (4-6 + 4-6) | piksel maskesini noise eşiğine göre kademeli gizle/göster |
| 10 | **KnockbackDisplacement** *(metadata)* | vektör, süre, easing | pozisyon ofseti hesapla → JSON |
| 11 | **CameraShakeMetadata** *(metadata)* | amplitude, frequency, duration, decay | sinüs / random-walk ofset dizisi → JSON |
| 12 | **HitstopMarker** *(metadata)* | kare sayısı (güce göre 3-15f) | animasyona freeze meta-etiketi (tag / user data) |

1-9 doğrudan Lua `Image` API'siyle prosedürel piksel çizimi olarak implement
edilir. 10-12 piksel çizmez; Aseprite'ın canvas sınırlaması nedeniyle metadata /
export katmanı olarak tasarlanır.
