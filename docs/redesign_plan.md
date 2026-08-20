# New Star Pop — Görsel Redesign Planı

## Sorunlar (kullanıcı geri bildirimi)
1. UI çok text-based → görsel odaklı, orijinal UI kiti
2. Ritim oyunu çok kötü → fizik tabanlı, akıcı, görsel
3. Prompter'da tıklamaya tepki yok → çalışmayan mini oyunlar

## Yeni UI Kiti: "Neon Sahne" (Stadium Lights / konser atmosferi)

### Renk paleti
- Zemin: derin lacivert-mor gradient (#0a0520 → #1a0b3d → #2d1060), sahne ışıkları glow
- Ana: elektrik pembesi #ff2d95, vurgu: buz mavisi #4de8ff, altın #ffd24a
- Metinler: beyaz, ikincil #a8a0c0
- Kartlar: cam efekti (glassmorphism): yarı şeffaf beyaz-mor + blur + ince neon kenar

### Görsel sistem
- Her stat: renk kodlu gradient progress bar + parlayan (shimmer) dolum
- Karakter avatarları: Emoji + renkli gradient halka + isim rozeti (her üye benzersiz)
- Sahne arka planı: CustomPainter ile spot ışıkları (üç konik gradient), sahne zemin reflektif gradient, havada parçacıklar
- Konfeti/parıltı efektleri: skor ekranlarında parçacık animasyonu
- Butonlar: neon kenar + içeriden glow, basınca pulse animasyonu
- Bildirimler: toast yerine ekran üstü floating feedback (PERFECT vb. büyük tipografi + renk kodlu)
- Font: Poppins (Google Fonts) — başlıklar 900 weight, büyük

### Ekran tasarımı
- Başlangıç: tam ekran gradient + sahne ışıkları painter + boy band / girl band seçimi iki büyük görsel kart (emoji + gradient)
- Hub: üstte avatar + isim + para kapsülü; statlar dikey kart; ilişkiler üye avatarlarıyla yatay kartlar; aksiyonlar 2x3 ikon+etiket grid, her kart görsel (ikon glow, gradient arka plan)
- Mini oyunlar: tam ekran sahne painter üstünde oynanır, UI overlay

## Mini Oyunların Yeni Mekaniği

### 1. Ritim Oyunu (tam yeniden yazım — 4 şerit)
- 4 şerit (pembe/cyan/altın/mor), her şeritte düşen notalar
- Notalar: yuvarlak, glow'lu; şeritlerde dikey gradient iz bırakır
- Hedef çizgisi: parlayan yatay çizgi + 4 hedef halka
- Mekanik: tap / her şeride tek tıklama alanı; şerit alanına tıklanınca o şeritteki en yakın nota değerlendirilir
- Pencereler: <40ms PERFECT (mor parıltı), <90ms İYİ, <140ms PAS, aksi MISS
- Skor: combo sayacı (x combo), büyük tipografi combo popup'ı, şerit patlama parçacıkları
- Akış: BPM 90-130 arası, nota aralıkları ritmik (beat tabanlı), 12-16 nota, başta "3-2-1" countdown, sonda skor sahnesi
- Geri bildirim: hit olunca şeritte patlama halkası (Ripple), miss olunca şerit kırmızı flash

### 2. Prompter (Şarkı Sözü Ezberleme)
- Kelimeler kart olarak görünür: her kelime tap edilebilir GestureDetector
- KURAL (basit ve anlaşılır): sıradaki kelime (altın çerçeve + "şimdi!" etiketi) aktif; diğerleri soluk
- Kelime kartları: büyüklük varyasyonu, hafif tilt, emoji ikonları
- Zamanlayıcı: her kartın üstünde azalan süresiz dairesel progress ring; süre dolunca kart kırmızıya dönüp "kayboldu" animasyonuyla kaybolur (slide + fade)
- Doğru tap: kart cyan patlaması + "kurtarıldı" tick + hafif scale bounce
- Yanlış tap (sıradışı): kart kırmızı shake animasyonu (animasyonla titrer)
- Başlık metni: telkprompter şeridi üstte kayar (bozuk telkprompter efekti: glitch)
- Skor: kurtarılan/kaçan sayaç, süre dolunca final ekranı

### 3. Spotlight Paylaşımı
- 3 üye avatarı (karakterler) sahne üstünde duruyor
- Spotlight halkası aktif üyeyi takip eder (lerp animasyonu)
- Soru kartı: bridge bölümünde "Soloya izin ver / Destek ver" ikilemi — üyeye göre ilişki kazancı/riski gösterilir
- Tıklama: üye kartına tap → ilişki değişimi animasyonlu (kalp/üzüntü emoji uçuşur)

### 4. Röportaj
- Talk show seti: sunucu avatarı sol üst, oyuncu avatarı altta
- Soru balonu + 3 cevap kartı (emoji ikonlu, renkli)
- Cevap: medya/menajer/sponsor değişimi animasyonlu sayaçlarla gösterilir

## Teknik Notlar
- GameState provider aynı kalır (Riverpod), sadece UI katmanı değişir
- Parçacık sistemi: Particle widget (CustomPainter, basit)
- Görsel doğrulama için web build + tarayıcı kontrolü şart (bu sefer boş ekran kalmamalı)
