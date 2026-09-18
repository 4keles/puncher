# Project Workflow — Puncher

## Yol Gösterici İlkeler

1. **Plan tek doğruluk kaynağıdır:** Tüm iş `plan.md` içinde takip edilir.
2. **Tech stack bilinçlidir:** Teknoloji yığınındaki değişiklikler implementasyondan
   *önce* `tech-stack.md` içinde belgelenir.
3. **Test-Driven Development:** Fonksiyonellik yazılmadan önce test yazılır.
4. **Kapsam hedefi:** Matematiksel çekirdek (motion, VFX, pixel dönüşüm
   algoritmaları — saf, yan etkisiz fonksiyonlar) için **>%80 coverage**.
   Aseprite `Dialog`/UI katmanı bu hedeften muaftır (headless test edilemez);
   orada manuel doğrulama yapılır.
5. **Sanatçı deneyimi önce gelir:** Her karar `product-guidelines.md` içindeki
   UX prensiplerine (non-destructive, modüler komutlar, makul varsayılanlar)
   uymak zorundadır.
6. **Non-interactive & CI-aware:** Komutlar etkileşimsiz çalışacak şekilde
   seçilir (ör. `aseprite --batch --script ...`).

## Task Workflow

Her task şu yaşam döngüsünü izler:

1. **Task Seç:** `plan.md` içindeki sıradaki task'ı sırayla al.

2. **In Progress İşaretle:** İşe başlamadan önce `plan.md` içinde task'ı
   `[ ]` → `[~]` yap.

3. **Başarısız Test Yaz (Red):**
   - Özellik veya hata düzeltmesi için test dosyası oluştur.
   - Beklenen davranışı ve kabul kriterlerini net tanımlayan testler yaz.
   - **KRİTİK:** Testleri çalıştır ve beklendiği gibi başarısız olduklarını
     doğrula. Başarısız test olmadan devam etme.

4. **Geçecek Kadar Implement Et (Green):**
   - Testleri geçirecek minimum kodu yaz.
   - Test paketini tekrar çalıştır, hepsinin geçtiğini doğrula.

5. **Refactor (opsiyonel, önerilir):**
   - Geçen testlerin güvenliğinde kodu sadeleştir, tekrarı kaldır.
   - Testleri yeniden çalıştır.

6. **Kapsamı Doğrula:** Çekirdek algoritma modülleri için coverage raporu
   çalıştır. Hedef: yeni çekirdek kod için >%80. UI/Dialog dosyaları rapordan
   hariç tutulur.

7. **Sapmaları Belgele:** Implementasyon tech stack'ten sapıyorsa:
   - **DUR**
   - `tech-stack.md` dosyasını yeni tasarımla güncelle
   - Değişikliği açıklayan tarihli not ekle
   - Implementasyona devam et

8. **Kodu Commit'le:**
   - Task'a ait tüm değişiklikleri stage'le.
   - Net bir commit mesajı öner, ör. `feat(motion): Add cubic easing evaluator`.
   - Commit'i yap.

9. **Task Özetini Git Notes ile İliştir:**
   - **9.1:** Commit hash'ini al (`git log -1 --format="%H"`).
   - **9.2:** Task adı, değişiklik özeti, oluşturulan/değiştirilen dosya listesi
     ve değişikliğin "neden"ini içeren detaylı bir not taslağı hazırla.
   - **9.3:** `git notes add -m "<note content>" <commit_hash>` ile iliştir.

10. **Task Commit SHA'sını Kaydet:**
    - **10.1:** `plan.md` içinde tamamlanan task'ı bul, `[~]` → `[x]` yap ve
      commit hash'inin ilk 7 karakterini ekle.
    - **10.2:** Güncellenen içeriği `plan.md` dosyasına yaz.

11. **Plan Güncellemesini Commit'le:**
    - `plan.md` dosyasını stage'le.
    - `conductor(plan): Mark task '<TASK>' as complete` biçiminde commit'le.

### Düzeltme ve Plan Değişikliği Akışları

1. **Uçuş İçi Düzeltmeler:** Task hâlâ `[~]` durumundayken bulunan küçük
   eksikler aktif implementasyon içinde düzeltilir; commit öncesi testler geçmeli.
2. **Code Review Düzeltmeleri (`conductor-review`):** Review sırasında bulunan
   sorunlar için review agent'ı `plan.md` dosyasına bir `Review Fixes` fazı
   ekler; düzeltmeler formel olarak takip edilir.
3. **Mantıksal Geri Alma (`conductor-revert`):** Bir task temelden hatalıysa
   ilgili commit'ler güvenle geri alınır ve task durumu `[ ]` konumuna döner.

### Faz Tamamlama Doğrulama ve Checkpoint Protokolü

**Tetikleyici:** Bir fazı da sonlandıran task tamamlandığında çalışır.

1. **Protokolü Duyur:** Kullanıcıya fazın bittiğini ve doğrulama protokolünün
   başladığını bildir.

2. **Faz Değişiklikleri İçin Test Kapsamını Sağla:**
   - **2.1:** `plan.md` içinden önceki fazın checkpoint SHA'sını bul. Yoksa
     kapsam ilk commit'ten itibarendir.
   - **2.2:** `git diff --name-only <previous_checkpoint_sha> HEAD` ile değişen
     dosyaları listele.
   - **2.3:** Kod dosyaları için (`.md`, `.json` gibi kod olmayanları hariç tut)
     karşılık gelen test dosyası var mı bak; yoksa oluştur. Önce repodaki mevcut
     test dosyalarını inceleyip adlandırma ve stil kurallarını öğren. UI/Dialog
     dosyaları bu zorunluluktan muaftır; onlar manuel doğrulama planına girer.

3. **Otomatik Testleri Çalıştır:**
   - Çalıştırmadan önce kullanacağın tam komutu duyur.
   - **Örnek duyuru:** "Testleri çalıştıracağım. **Komut:**
     `aseprite --batch --script tests/run_all.lua`"
   - Komutu çalıştır.
   - Testler başarısız olursa kullanıcıyı bilgilendir ve hata ayıklamaya başla.
     **En fazla iki** düzeltme denemesi yap; hâlâ başarısızsa **dur**, durumu
     raporla ve kullanıcıdan yönlendirme iste.

4. **Manuel Görsel Doğrulama Planı Öner:**
   - Planı üretmek için önce `product.md`, `product-guidelines.md` ve `plan.md`
     dosyalarını analiz ederek fazın kullanıcıya dönük hedeflerini çıkar.
   - Bu proje görsel bir araçtır: doğrulama **üretilen animasyonun görünümü**
     üzerinden yapılır. Plan şu formatta olmalı:

     ```
     Otomatik testler geçti. Manuel doğrulama için:

     **Manuel Doğrulama Adımları:**
     1. **Aseprite'ı aç ve şu örnek dosyayı yükle:** `examples/dummy-character.aseprite`
     2. **Şu komutu çalıştır:** Menü → Puncher → Apply Motion → "Forward Dash"
     3. **Şunu görmelisin:** 8 karelik yeni bir tag, karakterin ileri doğru
        hızlanıp yavaşladığı, 3. ve 4. karelerde smear bulunan bir dash;
        orijinal katman değişmemiş olmalı.
     4. **Geri alma kontrolü:** Tek `Ctrl+Z` tüm üretimi kaldırmalı.
     ```
   - Mümkünse doğrulama için dışa aktarılmış bir GIF üret ve kullanıcıya göster.

5. **Kullanıcı Onayını Bekle:**
   - Planı sunduktan sonra sor: "**Bu beklentini karşılıyor mu? Evet ile
     onayla veya neyin değişmesi gerektiğini yaz.**"
   - **DUR** ve açık onay gelmeden devam etme.

6. **Rapor İçin Hedef Commit'i Belirle:** Checkpoint için boş commit oluşturma;
   fazdaki son fonksiyonel commit'i hedef al.

7. **Doğrulama Raporunu Git Notes ile İliştir:** Otomatik test komutu, manuel
   doğrulama adımları ve kullanıcının onayını içeren raporu hedef commit'e
   `git notes` ile ekle.

8. **Faz Checkpoint SHA'sını Kaydet:** `plan.md` içindeki faz başlığına
   `[checkpoint: <sha>]` ekle.

9. **Plan Güncellemesini Commit'le:**
   `conductor(plan): Mark phase '<PHASE NAME>' as complete`

10. **Tamamlandığını Duyur.**

### Quality Gates

Bir task tamamlandı sayılmadan önce doğrula:

- [ ] Tüm testler geçiyor
- [ ] Çekirdek algoritma kapsamı hedefi karşılıyor (>%80)
- [ ] Kod `code_styleguides/` kurallarına uyuyor
- [ ] Tüm public fonksiyonlar belgelenmiş (LuaDoc/docstring)
- [ ] Lint / statik analiz hatası yok
- [ ] **Non-destructive garantisi korunuyor** (kullanıcının mevcut katmanları
      değiştirilmiyor, tüm üretim tek `app.transaction` içinde, tek Ctrl+Z ile
      geri alınabiliyor)
- [ ] **Pixel bütünlüğü korunuyor** (grid hizası, istenmeyen anti-aliasing yok,
      palet dışı renk sessizce eklenmiyor)
- [ ] Görsel çıktı gözle doğrulandı (tek kare değil, animasyonun tamamı)
- [ ] Dokümantasyon güncellendi (gerekliyse)

## Development Commands

> **NOT:** Bu bölüm `tech-stack.md` kesinleştikten sonra doldurulacaktır
> (Faz 0 araştırma çıktısına bağlı).

### Setup

```bash
# TBD — tech-stack.md kesinleştiğinde doldurulacak
```

### Günlük Geliştirme

```bash
# TBD — ör. aseprite --batch --script tests/run_all.lua
```

### Commit Öncesi

```bash
# TBD — lint + test + format
```

## Test Gereksinimleri

### Birim Testleri

- Her çekirdek modülün (easing, arc, squash&stretch, particle, quantizer)
  karşılık gelen testi olmalı.
- Testler saf fonksiyonları hedefler: girdi parametreleri → beklenen sayısal
  çıktı veya piksel matrisi.
- Hem başarı hem hata durumlarını test et (ör. geçersiz frame sayısı, eksik
  anchor).

### Entegrasyon Testleri

- Uçtan uca komut akışı: örnek sheet → ingest → pixelate → motion → VFX.
- Üretilen sprite'ın yapısal doğrulaması: beklenen kare sayısı, katman
  adlandırması, tag'lar, palet boyutu.
- Aseprite headless modda (`--batch --script`) çalıştırılabilir olmalı.

### Görsel Regresyon

- Referans çıktılar (altın dosyalar) örnek karakterlerle saklanır; üretilen
  pikseller hash veya piksel karşılaştırmasıyla doğrulanır.
- Kasıtlı görsel değişikliklerde referans dosyalar açıkça güncellenir ve commit
  mesajında belirtilir.

## Code Review Kontrol Listesi

1. **Fonksiyonellik:** Özellik belirtildiği gibi çalışıyor, sınır durumlar
   (0 kare, tek kare, çok büyük sprite, boş katman) ele alınmış, hata mesajları
   anlaşılır.
2. **Kod Kalitesi:** Stil rehberine uygun, tekrar yok, isimler net, gereksiz
   yorum yok.
3. **Testler:** Kapsamlı birim testleri, entegrasyon testleri geçiyor.
4. **Performans:** Per-pixel döngüler gereksiz tekrar etmiyor, büyük sprite'larda
   kabul edilebilir süre, gereksiz Image kopyası yok.
5. **Sanatçı Deneyimi:** Non-destructive, parametreler anlaşılır, varsayılanlar
   makul, önizleme doğru.

## Commit Kuralları

### Mesaj Formatı

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Tipler

- `feat`: Yeni özellik
- `fix`: Hata düzeltmesi
- `docs`: Sadece dokümantasyon
- `style`: Biçimlendirme
- `refactor`: Davranışı değiştirmeyen kod değişikliği
- `test`: Eksik testlerin eklenmesi
- `chore`: Bakım işleri

### Örnekler

```bash
git commit -m "feat(motion): Add anticipation-overshoot curve generator"
git commit -m "fix(pixelate): Correct palette mapping in OKLab distance"
git commit -m "test(vfx): Add tests for shockwave ring radius falloff"
```

## Definition of Done

Bir task şu koşullarda tamamlanmıştır:

1. Kod belirtime uygun implement edildi
2. Birim testleri yazıldı ve geçiyor
3. Çekirdek kapsam hedefi karşılandı
4. Dokümantasyon tamamlandı (gerekliyse)
5. Lint / statik analiz temiz
6. Görsel çıktı gözle doğrulandı ve non-destructive garantisi korundu
7. Implementasyon notları `plan.md` içine eklendi
8. Değişiklikler uygun mesajla commit'lendi
9. Task özeti git note olarak commit'e iliştirildi

## Sürüm ve Dağıtım

### Sürüm Öncesi Kontrol Listesi

- [ ] Tüm testler geçiyor
- [ ] Çekirdek kapsam hedefi karşılanıyor
- [ ] Lint hatası yok
- [ ] Desteklenen minimum Aseprite sürümünde manuel olarak denendi
- [ ] README ve komut referansı güncel
- [ ] `package.json` (extension manifest) sürümü güncellendi
- [ ] Örnek GIF'ler yeniden üretildi

### Dağıtım Adımları

1. Feature dalını ana dala birleştir
2. Sürümü tag'le (semver)
3. `.aseprite-extension` paketini üret
4. Paketi temiz bir Aseprite kurulumunda test et
5. GitHub release yayınla (changelog ile)

## Sürekli İyileştirme

- Workflow'u düzenli gözden geçir, acı noktalarına göre güncelle
- Öğrenilen dersleri belgele
- Basit ve sürdürülebilir tut
