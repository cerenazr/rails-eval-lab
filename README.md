# 🥋 Engineering Dojo

**Karpathy'nin [autoresearch](https://github.com/karpathy/autoresearch) pattern'inden ilham alan, Rails için performans optimizasyon dojo'su.**

Kasıtlı olarak kötü yazılmış bir Rails servisini optimize ediyorsun. Her denemende SQL sorgu sayısı ve çalışma süresi ölçülüyor, puanlanıyor ve kalıcı olarak kaydediliyor. **100 kredin var, her deneme 5 kredi. 20 hakkın var — sonra sistem seni kilitliyor.**

Kod yazmadan önce düşün. Düşündüğünü yaz. Sonra çalıştır.

---

## Autoresearch Pattern Nedir?

Karpathy, Mart 2026'da bir deney yayınladı: bir AI agent'a küçük bir LLM eğitim kodu verdi, agent kodu değiştirdi, 5 dakika eğitti, sonuç iyileştiyse tuttu, kötüleştiyse geri aldı. Sabaha kadar 100+ deney çalıştı.

Bu repo aynı pattern'i Rails'e uyguluyor:

| Autoresearch | Engineering Dojo |
|---|---|
| `train.py` — agent'ın değiştirdiği tek dosya | `user_data_fetcher.rb` — senin değiştirdiğin tek dosya |
| `prepare.py` — dokunulmaz evaluation | `scorer.rb` — dokunulmaz ölçüm motoru |
| `program.md` — agent talimatları | `program.md` — optimizasyon kuralları |
| `results.tsv` — deney geçmişi | `run_logs` tablosu — iteration geçmişi |
| Keep / Revert döngüsü | `git commit` / `git checkout --` döngüsü |

Tek fark: burada agent sen değilsin — **sen düşünen insansın.** AI agent kullanabilirsin ama her kararın arkasında bir hipotez olmalı.

---

## Hızlı Başlangıç

### 1. Fork & Clone

```bash
# GitHub'dan fork et, sonra:
git clone https://github.com/seyyah/rails-eval-lab.git
cd rails-eval-lab
```

### 2. Kurulum

```bash
bundle install
rails db:create
rails db:migrate
rails db:seed
```

Seed çıktısında şunu görmelisin:

```
Baseline measured: 1199 queries, xxxxms
Challenge 'n_plus_one_dashboard' ready.
```

Bu sayılar herkes için aynı (deterministic seed).

### 3. Durumunu Kontrol Et

```bash
rails dojo:status
```

```
Credits: 100 / 100 (20 runs left)
Henüz çalıştırma yok.
```

### 4. İlk Optimizasyonunu Yap

`app/services/user_data_fetcher.rb` dosyasını aç, analiz et, değişikliğini yap. Sonra:

```bash
rails dojo:run -- "açıklaman buraya: ne değiştirdin ve neden"
```

```
✅ Iteration #1 Complete
Queries:    4 (baseline: 1199)
Time:       45.2ms (baseline: 1524ms)
Score:      89.72 / 100
```

---

## Kurallar

1. **Sadece değiştir:** `app/services/user_data_fetcher.rb`
2. **Asla değiştirme:** modeller, schema, migration, seed, scorer, evaluation engine
3. **Çıktı sözleşmesi:** `UserDataFetcher.new.call` aynı veri yapısını döndürmeli. Aynı key'ler, aynı değerler, aynı iç içe yapı.
4. **Cache yasak:** Optimizasyon sorgu stratejisinde olmalı, `Rails.cache` veya memoization ile değil.
5. **Strateji notu zorunlu:** Her çalıştırmada ne yaptığını ve neden yaptığını yazmalısın (min 20 karakter).

---

## Komutlar

| Komut | Ne Yapar |
|---|---|
| `rails dojo:run -- "strateji notun"` | Evaluation çalıştırır, score hesaplar, kredi düşer |
| `rails dojo:status` | Tüm iterasyon geçmişini ve kalan krediyi gösterir |

---

## Puanlama (0–100)

| Bileşen | Ağırlık | Formül |
|---|---|---|
| Sorgu Azaltma | %60 | ((baseline_queries − senin_queries) / baseline_queries) × 100 |
| Süre Azaltma | %30 | ((baseline_time − senin_time) / baseline_time) × 100 |
| Kararlılık Bonusu | %10 | Önceki çalıştırmayla tutarlılık (ilk denemede 0) |

**Sorgu azaltmaya odaklan.** Süre azaltmanın iki katı değerinde.

> ⚠️ Süre ölçümü doğası gereği gürültülü — CPU yüküne göre değişir. Aynı kodu iki kez çalıştırsan farklı süre çıkabilir. Sorgu sayısı ise deterministik: her seferinde aynı.

---

## Kredi Sistemi

```
Başlangıç:  100 kredi
Deneme başı: -5 kredi
Toplam hak:  20 deneme
Yenileme:    YOK
```

Kredin bittiğinde sistem seni kilitler. Bu brute-force'u engellemek için var — rastgele denemek yerine düşünmeye zorluyor.

**Strateji önerisi:** İlk birkaç denemeyi büyük iyileştirmelere harca (eager loading). Son denemeleri ince ayar için sakla (select, pluck, batch).

---

## Çalışma Döngüsü

```
1. user_data_fetcher.rb'yi analiz et
2. claude.md'ye hipotezini yaz (ne bekliyorsun?)
3. Kodu değiştir (TEK kavramsal değişiklik)
4. rails dojo:run -- "ne yaptığını açıkla"
5. Sonucu claude.md'ye kaydet
6. Score arttıysa → git commit
   Score düştüyse → git checkout -- app/services/user_data_fetcher.rb
7. Tekrarla
```

Bu Karpathy'nin "keep/revert ratchet loop"u — sadece iyileştirmeleri tut, gerilemeyi geri al.

---

## Dosya Yapısı

```
.
├── program.md                              # Optimizasyon kuralları ve talimatlar
├── claude.md                               # Strateji log'un (sen dolduruyorsun)
├── app/
│   ├── models/
│   │   ├── challenge.rb                    # Baseline metrikleri tutan challenge
│   │   ├── run_log.rb                      # Append-only iterasyon kaydı
│   │   └── user.rb                         # Kredi bakiyesi
│   └── services/
│       ├── user_data_fetcher.rb            # ← SADECE BUNU DEĞİŞTİR
│       ├── scorer.rb                       # Ölçüm motoru (dokunma)
│       └── evaluation_engine/
│           ├── execute_run.rb              # Orkestratör (dokunma)
│           └── score_calculator.rb         # Puan hesaplama (dokunma)
├── db/
│   ├── seeds.rb                            # Deterministik test verisi
│   └── migrate/                            # Schema tanımları
└── lib/
    └── tasks/
        └── dojo.rake                       # CLI komutları
```

---

## Sık Sorulan Sorular

**S: Score'um 0'dan büyük çıktı ama hiçbir şey değiştirmedim?**
Süre ölçümü gürültülü. Baseline'dan daha hızlı çalışırsa süre azaltma puanı alırsın. Gerçek iyileştirme sorgu sayısında görünür.

**S: Kredim bitti, ne yapabilirim?**
Hiçbir şey. Bu tasarım gereği böyle. Bir sonraki challenge'da daha dikkatli ol.

**S: AI agent (Claude Code, Cursor, vb.) kullanabilir miyim?**
Evet, ama agent senin kredinle çalışıyor. Agent'a `program.md`'yi oku dedikten sonra bırakırsan, 20 hakkını 5 dakikada bitirebilir. Agent'ı yönet, yönetilme.

**S: `Scorer.run`'ı direkt çalıştırabilir miyim?**
Teknik olarak evet, ama bu kredi harcamaz ve log tutmaz. Dojo kurallarına göre tüm ölçümler `rails dojo:run` üzerinden yapılmalı.

**S: Modeli veya ilişkileri değiştirebilir miyim?**
Hayır. Gerçek dünyada "schema'yı değiştir" her zaman bir seçenek değildir. Mevcut yapı içinde optimize et.

---

## Lisans

MIT
