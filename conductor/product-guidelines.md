# Ürün Kılavuzları — Puncher

## Dil

- **Arayüz, menü, parametre adları ve son kullanıcı dokümantasyonu: İngilizce.**
  Eklenti genel pixel art topluluğuna dağıtılacak.
- Kod içi identifier ve yorumlar: İngilizce.
- Proje içi `conductor/` belgeleri: Türkçe.

## Ton

Teknik ve net; Aseprite'ın kendi sade diliyle uyumlu. Kısa etiketler (`Speed`,
`Weight`, `Exaggeration`, `VFX Intensity`), abartısız ve jargonsuz. Preset
isimleri açıklayıcı (`Forward Dash`, `Ground Slam`), pazarlama dili yok. Hata
mesajları hem ne olduğunu hem nasıl düzeltileceğini söyler.

## Temel UX Prensipleri

1. **Kesinlikle non-destructive.** Üretilen her şey yeni layer/frame/tag olarak
   eklenir; kullanıcının mevcut çizimi asla üzerine yazılmaz. Her komut tek bir
   `app.transaction` içinde çalışır, tek `Ctrl+Z` ile tamamen geri alınır.
2. **Modüler komut mimarisi.** Her iş ayrı bir menü komutu: `Ingest Sheet`,
   `Pixelate`, `Apply Motion`, `Add VFX`, `Export`. Komutlar bağımsız
   çalışabilir ve zincirlenebilir; kullanıcı istediği adımı atlayabilir veya
   yalnızca tek adımı kullanabilir.
3. **Adımlar arası sözleşme.** Komutlar birbirine katman adlandırma kuralları ve
   sprite metadata'sı (properties / slices / tags) üzerinden konuşur; gizli
   global state yok. Bu, komutları hem bağımsız hem birleştirilebilir yapar.
4. **Önizleme ucuzsa vardır.** Her komut dialog'unda mümkün olan yerde canvas
   önizlemesi; pahalı işlemlerde düşük çözünürlüklü veya tek kare önizleme.
5. **Parametreler görünür ve kaydedilebilir.** Her efekt açık sayısal
   parametrelerle sürülür (gizli sihir yok). Ayarlar preset olarak kaydedilip
   yeniden kullanılabilir.
6. **Sanatçı son sözü söyler.** Çıktı her zaman elle düzenlenebilir katmanlardır;
   eklenti "kapalı kutu" bir render üretmez.
7. **Hız birinci sınıf.** Bir komut tipik bir karakterde birkaç saniyede
   bitmeli; uzun işlemlerde ilerleme geri bildirimi verilir.
8. **Makul varsayılanlar.** Kullanıcı hiçbir slider'a dokunmadan "Apply"
   dediğinde iyi görünen bir sonuç almalı.

## Görsel ve Estetik Kuralları

- Üretilen çıktı belgenin mevcut paletine sadık kalır. VFX için palet dışı renk
  gerektiğinde kullanıcıya sorulur veya palete eklenmesi açıkça bildirilir.
- Piksel bütünlüğü korunur: grid hizası, sub-pixel kayma yok, istenmeyen
  anti-aliasing yok.
- Efektler pixel art kurallarına uyar: sert kenar, sınırlı palet, tutarlı piksel
  yoğunluğu.

## Dokümantasyon Kuralları

- Her preset ve VFX için: ne yaptığı, parametreleri, tipik kare sayısı ve örnek
  GIF.
- README İngilizce; kurulum adımlarıyla başlar, ardından komut referansı gelir.
- Sürüm notları kullanıcıya görünen davranış değişikliklerini açıkça listeler.
