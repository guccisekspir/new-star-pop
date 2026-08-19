# New Star Pop

New Star Soccer'ın TR Pop girl band / boy band üye kariyeri versiyonu — tererpop.com için geliştirilen bir **mobil oyun** (Flutter, Android + iOS).

Flutter **3.47.1 (stable)** ile oluşturulmuştur: Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0.

## Konsept Haritası

NSS'in "maça çık, kritik anları oyna" döngüsü burada "sahneye çık, kritik sahne anlarını oyna" döngüsüne dönüşür:

| NSS | New Star Pop |
|---|---|
| Maç | Konser (Sahneye Çık) |
| Şut anı | Ritim tutma mini-oyunu (Perfect/İYİ/KAÇTI) |
| Frikik | Teleprompter arızası — şarkı sözü ezberleme krizi |
| Pas seçimi | Bridge'de spotlight paylaşımı (hangi üyeye destek) |
| Basın röportajı | Talk show röportajı (medya/menajer/sponsor ilişkileri) |
| Kontrat müzakeresi | Sezon sonu kontrat / yükselme-düşme |
| At yarışı pasif geliri | Hayran kulübü aboneliği |
| Play style seçimi | Sahne stili: Diva Stili / Grup Uyumu |
| Kariyer skoru | Efsane Skoru (solo kariyere geçiş) |

## Kurulum

1. Flutter SDK 3.47+ kur: https://docs.flutter.dev/get-started/install
2. `flutter pub get`
3. **Android:** `flutter run` (emülatör/cihaz) veya `flutter build apk`
4. **iOS:** `flutter build ios` (macOS + Xcode gerekir)

Dikey (portrait) ekran hedeflenmiştir; NSS gibi kısa oturumlu mobil oyun.

## Mimari

- `lib/core/` — kariyer veri modeli, Riverpod StateNotifier, neon sahne teması
- `lib/games/` — ritim oyunu, söz ezberleme, spotlight, röportaj, konser akışı, dilemma kartları
- `lib/screens/` — başlangıç (isim + girl/boy band), ana hub

Durum yönetimi: Riverpod + Flutter Hooks.
