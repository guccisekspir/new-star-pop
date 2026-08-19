/// New Star Pop — kariyer veri modeli
/// NSS'in "16 yaşında alt ligden başla, yıldızlığa yüksel" konseptinin
/// TR Pop karşılığı: bar sahnesinden world tour'a.

/// Kariyer seviyesi (NSS Star Rating karşılığı)
enum CareerStage {
  barSahnesi('Bar / Kafe Sahnesi', 1),
  tvSecme('TV Yetenek Programı', 2),
  ulusalSahne('Ulusal Sahne', 3),
  turne('Ulusal Turne', 4),
  avrupa('Avrupa Turnesi', 5),
  worldTour('World Tour', 6);

  final String label;
  final int level;
  const CareerStage(this.label, this.level);
}

/// Sahne stili (NSS play style / attack-defense karşılığı)
enum StageStyle {
  diva('Diva Stili', 'Daha çok solo şansı, ses sağlığı hızlı tükenir'),
  grupUyumu('Grup Uyumu', 'Dengeli, güvenli, daha az spotlight');

  const StageStyle(this.name, this.description);
  final String name;
  final String description;
}

/// Grup üyesi (NSS takım arkadaşı karşılığı)
class BandMember {
  final String name;
  final String role; // vokalist, dansçı, rapper, ikinci vokal
  int relationship; // 0-100
  int signatureSongs; // kendi "imza" şarkısı sayısı
  BandMember({
    required this.name,
    required this.role,
    this.relationship = 50,
    this.signatureSongs = 1,
  });
}

/// Kariyer durumu (NSS player state karşılığı)
class CareerState {
  String playerName;
  bool isGirlBand; // girl band / boy band seçimi
  CareerStage stage;
  StageStyle style;
  int hype; // 0-100, NSS form/match-rating karşılığı
  int voice; // 0-100, ses sağlığı / stamina
  int fame; // 0-1000, şöhret puanı
  int money; // coin
  int careerScore; // emeklilik/solo geçiş skoru
  int season; // yıl
  List<BandMember> members;
  int managerRelation; // 0-100 (NSS boss karşılığı)
  int fansRelation; // 0-100
  int sponsorRelation; // 0-100
  int mediaRelation; // 0-100
  List<String> learnedSongs; // ezberlenen şarkılar
  List<String> scandals;
  CareerState({
    required this.playerName,
    this.isGirlBand = true,
    this.stage = CareerStage.barSahnesi,
    this.style = StageStyle.grupUyumu,
    this.hype = 40,
    this.voice = 100,
    this.fame = 0,
    this.money = 100,
    this.careerScore = 0,
    this.season = 1,
    List<BandMember>? members,
    this.managerRelation = 55,
    this.fansRelation = 50,
    this.sponsorRelation = 50,
    this.mediaRelation = 50,
    List<String>? learnedSongs,
    List<String>? scandals,
  })  : members = members ?? _defaultMembers(),
        learnedSongs = learnedSongs ?? [],
        scandals = scandals ?? [];

  static List<BandMember> _defaultMembers() => [
        BandMember(name: 'Zeynep', role: 'Dansçı / İkinci Vokal', signatureSongs: 2),
        BandMember(name: 'İlayda', role: 'Rapper', signatureSongs: 1),
        BandMember(name: 'Defne', role: 'İkinci Vokal', signatureSongs: 1),
      ];
}

/// Sahne puanı (NSS match rating karşılığı)
class ShowResult {
  final int score; // 0-100
  final int applause;
  final int viralGain;
  final int moneyEarned;
  final int voiceCost;
  final int hypeChange;
  final String headline; // magazin manşeti
  final Map<String, int> relationChanges;
  ShowResult({
    required this.score,
    required this.applause,
    required this.viralGain,
    required this.moneyEarned,
    required this.voiceCost,
    required this.hypeChange,
    required this.headline,
    required this.relationChanges,
  });
}
