# Araştırma 03 — Animasyon Matematiği ve Motion Motoru Tasarımı

*Tarih: 2026-09-18 · Amaç: `core/` katmanının matematiksel temelini kurmak.*

## 1. Easing ve Zamanlama

Penner easing aileleri: sine, quad, cubic, quart, quint, expo, circ, back,
elastic, bounce — her biri in / out / in-out formunda. Temel özdeşlik:

```
easeOut(t) = 1 - easeIn(1 - t)
```

Kübik Bezier ile yaklaşık eşlenebilirler (CSS `cubic-bezier(x1,y1,x2,y2)`);
overshoot içeren back/elastic bile kontrol noktalarıyla modellenebilir.

**Düşük kare sayısında (6-12 kare)** sürekli eğri basitçe örneklenmez. İki
teknik birlikte kullanılır:

- **Non-uniform frame duration:** kare süreleri eşit değil; hız düşükken kareler
  sıklaşır (ease-out'ta son karelerde hold/duplicate).
- Pozisyon örnekleme: `t_i = easeFn(i / (N-1))`, `pos_i = lerp(start, end, t_i)`.
- **Moving hold:** ekstremlerde (ilk/son kare) 1-3 kare tekrar.

Kaynaklar: <https://easings.net>, joshondesign.com easing yazısı,
zz85 cubic-bezier approximations.

## 2. 12 İlkenin Formülleştirilmesi

| İlke | Formül / kural |
| --- | --- |
| Anticipation | Hareketten önce ters yönde küçük ofset: `-0.15 * displacement`, 2-3 kare |
| Squash & Stretch | Hacim koruma: `s_x * s_y ≈ 1`. Pratik: `s_y = 1+k`, `s_x = 1/(1+k)`; `k` hıza/momentuma bağlı |
| Overshoot / follow-through | Sönümlü harmonik osilatör: `x(t) = target + A·e^(-ζωt)·cos(ωt)`; pratikte 1-2 overshoot + 1 settle karesi |
| Arcs | Quadratic Bezier: `B(t) = (1-t)²P0 + 2(1-t)t·P1 + t²P2`; `P1` yay tepesini belirler |
| Exaggeration | Tüm ofset/ölçek çarpanlarına uygulanan tek "juice" katsayısı |

3D squash&stretch'in hacim korumalı genel formu (Houdini):
`L'·D'·H' = ((L - L')·Vp + L')·D·H`, `Vp ∈ [0,1]`.

## 3. Dövüş / Aksiyon Kare Yapısı

**Startup / Active / Recovery** üçlemesi evrensel:

- startup: vuruş bağlanmadan önceki kareler
- active: hasar verebilen pencere
- recovery: savunmasız dönüş

Dustloop/SF6 wiki verilerine göre normal saldırılar tipik olarak 3-7 startup /
2-4 active / 8-20 recovery aralığında. 60 FPS'te dash kabaca 10-16 kare (2-4
startup, 6-10 travel, 2-4 recovery).

**Hitstop / hitlag:** vuruş anında her iki karakter donar. Gerçek örnekler:
Street Fighter V hafif 8f, orta 12f, ağır 15f; Final Fight (1989) sabit 6f;
Smash Bros'ta güçlü ataklarda yarım saniyeye kadar.

Kaynaklar: <https://dustloop.com>, <https://www.ssbwiki.com/Hitlag>,
<http://shoryuken.com/2016/06/07/hitstop-in-street-fighter-v-kens-not-so-little-secret/>

## 4. Smear Frame Türleri

- **Stretched/elongated smear:** extreme kareler arası gerilmiş tek kare.
- **Multiple/ghost smear:** aynı pozun alfası azalan birden çok kopyası.
- **Hybrid:** ikisinin karışımı.

Pixel art'ta (klasik Castlevania kırbaç örneği) az piksel ile silüet sweep
yeterli. Prosedürel üretim: hareket vektörü boyunca sprite'ı tek eksende
scale + shear ile ger, alfa gradyanı uygula, ardından pixel-snap.

Kaynaklar: <https://en.wikipedia.org/wiki/Smear_frame>, rebusfarm.net,
animschool.edu

## 5. Afterimage / Motion Trail

2-5 "echo" kare, üstel azalan alfa: `alpha_i = alpha_0 · decay^i`,
`decay ≈ 0.5-0.7`. Opsiyonel renk kayması (hue shift veya beyaza/maviye
yaklaştırma).

## 6. 2D Deformasyon

- **Affine:** 2x2 matris + translate (rotate/scale/skew).
- **Cutout / skeletal** (Spine2D, DragonBones): karakteri parçalara ayır
  (kafa/gövde/kol/bacak), her parçaya pivot ata, bone hiyerarşisiyle FK/IK.
- **ARAP** (as-rigid-as-possible) mesh deformasyonu: yerel rijitliği koruyan
  yumuşak deformasyon.

**Puncher için düşük riskli / yüksek getirili seçim:** sheet'i parçalara kesip
(head/torso/arm/leg) her parçaya ayrı `Image` + pivot + affine transform
uygulamak. Tam mesh warping gerekmez.

## 7. Pixel Art Rotasyon Sorunu

Naif rotasyon/ölçekleme jaggy ve renk bulanıklığı üretir.

**RotSprite** (Xenowhirl, 2007): önce Scale2x ile büyüt, büyütülmüş kopyayı
döndür, sonra geri örnekle — orijinal palet korunur, kenarlar temiz kalır.
hqx / Scale2x / Eagle aileleri kenar yönünü tanıyıp yeni pikselleri komşuluk
kurallarına göre atar.

Motor için gerekli üç kural:

1. Küçük açılarda (<15°) RotSprite tarzı upscale → rotate → downscale.
   *(Aseprite'ta bu native: `Image:resize{method='rotsprite'}`.)*
2. Her kare üretiminden sonra **pixel-grid snapping** (pozisyonu tam piksele
   yuvarla).
3. **Sub-pixel accumulator:** yuvarlama artığını bir sonraki kareye taşı, aksi
   halde round-off hatası birikir.

## 8. Referanslar

Steve Swink — *Game Feel*; Jan Willem Nijman — *The Art of Screenshake*
(Vlambeer, INDIGO 2013); Dustloop Wiki "Using Frame Data"; SmashWiki "Hitlag";
<https://easings.net>; RotSprite orijinal forum konusu (Sonic Retro);
Spine2D / DragonBones dokümantasyonu.

## Motion Motoru Tasarım Önerisi

Her preset fonksiyonunun aldığı parametreler:

| Parametre | Tip | Açıklama |
| --- | --- | --- |
| `frameCount` | int | dash≈8, punch≈6, jump≈12 |
| `speed` | 0-2 | zaman ölçeği (düşük = ağır, yüksek = snappy) |
| `weight` | 0-2 | momentum / overshoot / squash şiddeti |
| `exaggeration` | 0-2 | tüm ofset ve ölçek çarpanlarına uygulanan genel katsayı |
| `distance` | px | pivot'a göre hedef yer değiştirme |
| `easingType` | enum | easeOutCubic, easeOutBack, easeInExpo... |
| `anticipationFrames` / `overshootFrames` / `holdFrames` | int | preset başına override edilebilir |
| `smearEnabled`, `trailEnabled` (`echoCount`, `decay`) | bool/param | |

**Forward dash örneği — üretim adımları:**

1. Ana hareket kareleri için normalize zaman dizisi:
   `t_i = easingType(i / (frameCount - anticipationFrames - overshootFrames - 1))`
2. İlk `anticipationFrames` karede ters ofset:
   `offset = -0.15 * distance * exaggeration`; squash uygula
   (`s_y = 0.85`, `s_x = 1/0.85`).
3. Ana karelerde `pos_i = pivot + distance * t_i`. Jump için parabolik arc:
   `y = -4h·t·(1-t)`.
4. Hızın en yüksek olduğu orta karelerde stretch:
   `s_x = 1 + weight·0.3·|v_i|`, `s_y = 1/s_x`; hareket eksenine hizalı, affine
   transform + `rotsprite` ile piksel bütünlüğü korunarak.
5. Punch gibi presetlerde `active` karelerde hitbox flag'i set et; vuruş anında
   `hitstopFrames = round(3 + 5·weight)` kadar hareketi dondur (pozisyon sabit,
   squash artır).
6. Son `overshootFrames` karede sönümlü osilasyon:
   `x(t) = target + A·e^(-ζωt)·cos(ωt)`; `A` ve `ζ` `weight`'e bağlı.
7. Her kareden sonra pozisyonu pixel-grid'e yuvarla, kesir farkını accumulator
   ile bir sonraki kareye taşı.
8. `smearEnabled` ise en hızlı karede stretch smear veya önceki 2-3 karenin alfa
   azalan kopyaları; `trailEnabled` ise ayrı layer'da `echoCount` kopya,
   `alpha_i = 0.5·decay^i`.
9. Kareleri ayrı `Image` nesneleri olarak cel'lere yaz; non-uniform süre ata
   (hold kareler 2x, hızlı geçişler 1x).

Bu parametrik yapı sayesinde 10-20 preset aynı çekirdek fonksiyonlardan
(easing sampler, arc generator, squash&stretch, smear/trail compositor,
pixel-snap) türetilir; presetler yalnızca parametre setleriyle ayrışır.
