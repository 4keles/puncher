# Lua Style Guide — Puncher (Aseprite)

`general.md` kurallarına ek olarak, bu projeye özgü ve Aseprite API
araştırmasından (bkz. `conductor/research/01-aseprite-lua-api.md`) doğrudan
çıkan zorunlu kurallar.

## Katman Disiplini

- **`core/` içinde Aseprite API'sine referans YASAK.** `app`, `Image`, `Sprite`,
  `Dialog` gibi globaller `core/` altında hiçbir dosyada geçmemeli. `core/`
  yalnızca sayı, tablo ve saf fonksiyon üretir (ör. piksel matrisi, transform
  listesi, parametre tablosu).
- Aseprite'a dokunan her şey `adapter/` veya `commands/` altında olur.
- Bu kural test edilebilir: CI'da `core/` üzerinde bir grep kontrolü koşar.

## Aseprite API Kullanımı

- **`Image:putPixel` kullanılmayacak** — deprecated ve her çağrıda undo kaydı
  üretir. Yerine `drawPixel`.
- Performans-kritik piksel işlemleri `Image.bytes` + `rowStride` ham buffer
  üzerinde yapılır; sonuç tek seferde geri yazılır. Yüzlerce piksel üzerinde
  `getPixel`/`drawPixel` döngüsü kod incelemesinde gerekçelendirilmelidir.
- **Kullanıcının belgesini değiştiren her komut `app.transaction` içinde
  çalışır.** İstisna yok. Hata durumunda `error()` fırlatılır; transaction
  otomatik geri alır.
- Rotasyon/ölçekleme için elle interpolasyon yazılmaz; native
  `Image:resize{ method = 'rotsprite' }` kullanılır.
- `os.execute`, `io.popen` ve harici süreç çağrısı **yasak** (izin diyaloğu
  çıkarır, dağıtımı bozar). `io.open` yalnızca kullanıcının açıkça başlattığı
  export akışında kullanılabilir.

## Dil Kuralları

- Her değişken `local`. Global tanımlamak yasak (tek istisna: Aseprite'ın kendi
  sağladığı globaller).
- Modüller bir tablo döndürür: `local M = {} ... return M`.
- Modül yükleme: proje içinde tutarlı olmak kaydıyla `dofile` veya `require`;
  ikisi karıştırılmaz.
- `math.floor` / açık yuvarlama kullanılır; örtük sayı→integer dönüşümüne
  güvenilmez. Piksel koordinatları her zaman integer'a yuvarlanır.
- Karşılaştırmada `nil` ile `false` ayrımına dikkat; opsiyonel parametrelerde
  `if x == nil then x = default end` biçimi tercih edilir (`x = x or default`
  yalnızca `false`'un geçerli değer olmadığı yerlerde).
- String birleştirme döngü içinde `..` ile yapılmaz; `table.concat` kullanılır.

## İsimlendirme

- Dosya ve dizin adları: `snake_case.lua`.
- Fonksiyon ve değişken: `camelCase`.
- Modül tabloları ve "sınıf" benzeri yapılar: `PascalCase`.
- Sabitler: `UPPER_SNAKE_CASE`.
- Kullanıcıya görünen tüm metinler İngilizce (bkz. `product-guidelines.md`).

## Dokümantasyon

- Her public fonksiyonun üstünde kısa bir LuaDoc bloğu: ne yaptığı, parametreler
  (tip + birim + aralık), dönüş değeri.
- Birimler açıkça yazılır: `-- @param distance number  Yer değiştirme (piksel)`.
- Yorum yalnızca "neden" için yazılır; "ne" yaptığını kodun kendisi anlatır.

## Biçimlendirme

- `stylua` varsayılan ayarları; 2 boşluk girinti, satır uzunluğu 100.
- `luacheck` uyarısız geçmeli; `globals` listesi Aseprite globalleriyle
  yapılandırılır (`app`, `Image`, `Sprite`, `Dialog`, `Point`, `Rectangle`,
  `Color`, `json`, ...).

## Test

- `core/` modüllerinin testleri LuaUnit ile yazılır ve sistem Lua'sıyla
  (Aseprite olmadan) koşar.
- Test dosyası adı: `tests/core/<modül>_test.lua`.
- Sayısal testlerde kayan nokta karşılaştırması epsilon ile yapılır
  (`assertAlmostEquals`).
