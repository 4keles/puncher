# Puncher — Aseprite Prosedürel Aksiyon Animasyon Eklentisi

## Vizyon

Pixel art sanatçılarının hızlı tempolu aksiyon animasyonlarını (dash, impact,
teleport, jump) elle kare kare çizmek yerine, **matematiksel olarak parametrize
edilmiş hazır hareket şablonlarıyla** saniyeler içinde üretebildiği bir Aseprite
eklentisi.

## Problem

Aksiyon animasyonunda en çok zaman alan kısımlar aslında büyük ölçüde
matematikseldir: in-between üretimi, easing/timing eğrileri, smear kareleri,
squash & stretch, anticipation/overshoot, afterimage ve impact VFX. Sanatçı bu
tekrar eden mekanik işe zaman harcarken karakterin karakteristiğine
odaklanamıyor. "Vuruşun hissi" (game feel) çoğu zaman teknik bilgi eksikliğinden
zayıf kalıyor.

## Ürün Özeti

Ortak bir matematiksel motion çekirdeği üzerine kurulu, Aseprite içinde çalışan
iki araç:

1. **2D Aracı** — Klasik yandan/önden görünüm karakterler için.
2. **2.5D Aracı** — Sahte derinlik (perspektif offset, ölçek, 8 yön, faux-3D
   dönüş) destekli karakterler için.

Akış: **Karakter sheet'i yükle → (belirlenmiş sheet/anchor yapısına göre
normalize et) → algoritmik pixel art dönüşümü → motion uygula → animasyon
preset'i seç → impact VFX katmanı ekle → düzenlenebilir Aseprite katmanları
olarak çıktı al.**

## Hedef Kullanıcı

Genel pixel art topluluğu: indie oyun geliştiricileri, pixel artistler, game jam
katılımcıları. Özellikle platformer, beat'em up, hack & slash gibi hızlı tempolu
türlerde çalışanlar.

## Temel Yetenekler

1. **Sheet Ingest & Normalizasyon** — Tanımlı sprite sheet yapısı: grid,
   pivot/anchor noktaları, iskelet işaretçileri, yön etiketleri.
2. **Pixel Art Dönüştürücü** — Algoritmik: renk kuantizasyonu, palet eşleme,
   dithering, kenar temizleme/outline, downscale.
3. **Motion Motoru (matematiksel çekirdek)** — Easing eğrileri, hareket yayları
   (arcs), anticipation/overshoot, squash & stretch, smear interpolasyonu,
   motion trail, kare zamanlaması (hold/ease frames).
4. **Animasyon Kütüphanesi** — 10-20 parametrik preset: jump, forward dash, back
   dash, punch/vuruş, teleport/ışınlanma, landing, hurt/knockback, dodge roll,
   wind-up, slam vb.
5. **VFX / Impact Katmanı (ürünün kalbi)** — Hit spark, impact ring, speed lines,
   afterimage/echo, flash, dust puff, screen shake verisi, chromatic tear.
6. **2.5D Modu** — Perspektif offset, ölçek, y-sort, 8 yönlü varyantlar.

## Başarı Kriterleri

- Bir karakter sheet'i yüklendikten sonra çalışan bir "dash + impact"
  animasyonu **1 dakikadan kısa** sürede üretilebiliyor.
- Çıktı **non-destructive**: düzenlenebilir Aseprite katmanları ve kareleri
  olarak geliyor.
- Presetler parametrik: hız, ağırlık, abartı (exaggeration), kare sayısı, VFX
  yoğunluğu.
- Aseprite Extension olarak paketlenip toplulukla paylaşılabiliyor.

## Kapsam Dışı (şimdilik)

Gerçek 3D render/rigging, ses, oyun motoru runtime entegrasyonu (sadece export
formatları), karakter tasarımı/çizimi üretmek.

## Yol Haritası

- **Faz 0 — Araştırma (öncelikli):** Aseprite Lua API sınırları, pixel art
  dönüştürme algoritmaları, animasyon matematiği, VFX teknikleri, mevcut eklenti
  ekosistemi, MCP/harici araç entegrasyonları. MVP kapsamı bu fazın çıktısıyla
  netleşecek.
- **Faz 1:** Motion çekirdeği + 2D aracı + sheet ingest.
- **Faz 2:** Animasyon preset kütüphanesinin genişletilmesi.
- **Faz 3:** VFX/impact katmanı.
- **Faz 4:** 2.5D aracı.
- **Faz 5:** Paketleme ve topluluk dağıtımı.
