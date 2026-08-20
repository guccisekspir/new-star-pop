import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'career_model.dart';

/// Kariyer durumu — oyunun merkezi state'i (Riverpod StateNotifier)
class CareerNotifier extends StateNotifier<CareerState> {
  CareerNotifier() : super(CareerState(playerName: 'Ayşe', isGirlBand: true));

  /// Yeni kariyer başlat
  void newCareer({required String name, required bool isGirlBand}) {
    state = CareerState(
      playerName: name.isEmpty ? 'Ayşe' : name,
      isGirlBand: isGirlBand,
      members: isGirlBand ? CareerState.defaultMembers() : CareerState.boyMembers(),
    );
  }

  /// Prova: ritim antrenmanı başarısına göre stat ver (1-3 yıldız mantığı)
  void trainingResult(int success, int total) {
    final rating = success >= total - 1 ? 3 : success >= total - 2 ? 2 : 1;
    // başarılı provada ses sağlığı biraz düşer (enerji ekonomisi)
    state.voice = (state.voice - 10).clamp(0, 100);
    state.fame = (state.fame + rating * 2).clamp(0, 1000);
  }

  /// Şarkı ezberle (listeye ekle)
  void learnSong(String song) {
    if (!state.learnedSongs.contains(song)) {
      state.learnedSongs = [...state.learnedSongs, song];
    }
  }

  /// Konser sonucunu uygula (NSS match outcome karşılığı)
  void applyShowResult(ShowResult result) {
    state.voice = (state.voice - result.voiceCost).clamp(0, 100);
    state.hype = (state.hype + result.hypeChange).clamp(0, 100);
    state.fame = (state.fame + result.viralGain).clamp(0, 1000);
    state.money += result.moneyEarned;
    state.careerScore += result.score;

    for (final entry in result.relationChanges.entries) {
      switch (entry.key) {
        case 'group':
          for (final m in state.members) {
            m.relationship = (m.relationship + entry.value).clamp(0, 100);
          }
        case 'manager':
          state.managerRelation = (state.managerRelation + entry.value).clamp(0, 100);
        case 'fans':
          state.fansRelation = (state.fansRelation + entry.value).clamp(0, 100);
        case 'sponsor':
          state.sponsorRelation = (state.sponsorRelation + entry.value).clamp(0, 100);
        case 'media':
          state.mediaRelation = (state.mediaRelation + entry.value).clamp(0, 100);
      }
    }
  }

  /// Kutlama seçimi (NSS goal celebration karşılığı)
  void celebrate(String choice) {
    switch (choice) {
      case 'group':
        for (final m in state.members) {
          m.relationship = (m.relationship + 8).clamp(0, 100);
        }
        state.hype = (state.hype + 2).clamp(0, 100);
      case 'fans':
        state.fansRelation = (state.fansRelation + 10).clamp(0, 100);
      case 'camera':
        state.fame = (state.fame + 12).clamp(0, 1000);
        state.mediaRelation = (state.mediaRelation - 3).clamp(0, 100);
    }
  }

  /// Dilemma kararı (NSS rüşvet/skandal karşılığı)
  void resolveDilemma(String choice) {
    switch (choice) {
      case 'acceptOffer': // gizli kontrat teklifi
        state.money += 500;
        for (final m in state.members) {
          m.relationship = (m.relationship - 15).clamp(0, 100);
        }
        state.scandals = [...state.scandals, 'Sızıntı: ${state.playerName} rakip şirkete gizlice görüşmüş!'];
      case 'honest': // dürüst kal
        state.managerRelation = (state.managerRelation + 10).clamp(0, 100);
        state.fansRelation = (state.fansRelation + 5).clamp(0, 100);
      case 'nightClub': // gece kulübü kavgası
        state.mediaRelation = (state.mediaRelation - 20).clamp(0, 100);
        state.scandals = [...state.scandals, 'PAPARAZZİ: ${state.playerName} gece kulübü kavgasında görüntülendi!'];
      case 'rest': // dinlen
        state.voice = (state.voice + 35).clamp(0, 100);
        state.hype = (state.hype - 5).clamp(0, 100);
      case 'socialMedia': // hayran etkinliği
        state.fansRelation = (state.fansRelation + 8).clamp(0, 100);
        state.voice = (state.voice - 5).clamp(0, 100);
    }
  }

  /// Spotlight paylaşımı — belirli üyeye destek (ilişki değişir)
  void shareSpotlight(int memberIndex, int delta) {
    if (memberIndex < 0 || memberIndex >= state.members.length) return;
    state.members[memberIndex].relationship =
        (state.members[memberIndex].relationship + delta).clamp(0, 100);
  }

  /// İlişki değişikliği (mini oyunların ortak çıktısı)
  void changeRelation(String key, int delta) {
    switch (key) {
      case 'manager':
        state.managerRelation = (state.managerRelation + delta).clamp(0, 100);
      case 'fans':
        state.fansRelation = (state.fansRelation + delta).clamp(0, 100);
      case 'sponsor':
        state.sponsorRelation = (state.sponsorRelation + delta).clamp(0, 100);
      case 'media':
        state.mediaRelation = (state.mediaRelation + delta).clamp(0, 100);
    }
  }

  /// Sahne stilini ayarla (NSS play style karşılığı)
  void setStyle(StageStyle s) {
    state = CareerState(
      playerName: state.playerName,
      isGirlBand: state.isGirlBand,
      stage: state.stage,
      hype: state.hype,
      voice: state.voice,
      fame: state.fame,
      money: state.money,
      careerScore: state.careerScore,
      season: state.season,
      members: state.members,
      managerRelation: state.managerRelation,
      fansRelation: state.fansRelation,
      sponsorRelation: state.sponsorRelation,
      mediaRelation: state.mediaRelation,
      learnedSongs: state.learnedSongs,
      scandals: state.scandals,
      style: s,
    );
  }

  /// Hayran kulübü pasif geliri (NSS at yarışı karşılığı)
  void addFanClubIncome() {
    state = CareerState(
      playerName: state.playerName,
      isGirlBand: state.isGirlBand,
      stage: state.stage,
      hype: state.hype,
      voice: state.voice,
      fame: state.fame,
      money: state.money + 150 + state.fansRelation * 3,
      careerScore: state.careerScore,
      season: state.season,
      members: state.members,
      managerRelation: state.managerRelation,
      fansRelation: state.fansRelation,
      sponsorRelation: state.sponsorRelation,
      mediaRelation: state.mediaRelation,
      learnedSongs: state.learnedSongs,
      scandals: state.scandals,
      style: state.style,
    );
  }

  /// Sezon sonu: ilerleme kontrolü (NSS promotion/relegation karşılığı)
  void seasonEnd() {
    state.season += 1;
    // hype yüksekse yüksel, düşükse düş
    if (state.hype >= 70 && state.stage != CareerStage.worldTour) {
      state.stage = CareerStage.values[state.stage.index + 1];
    } else if (state.hype < 25 && state.stage != CareerStage.barSahnesi) {
      state.stage = CareerStage.values[state.stage.index - 1];
    }
  }

  /// Kontrata imza: yeni sezon, ses sağlığını yenile
  void signContract() {
    state.voice = 100;
    state.money += 200;
    seasonEnd();
  }

  /// Emeklilik / solo kariyere geçiş (NSS career score karşılığı)
  int retire() {
    return state.fame + state.hype + state.careerScore ~/ 10 + state.money;
  }
}

final careerProvider =
    StateNotifierProvider<CareerNotifier, CareerState>((ref) => CareerNotifier());
