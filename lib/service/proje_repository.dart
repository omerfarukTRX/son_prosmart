import 'package:prosmart/models/proje_model.dart';
import 'package:prosmart/service/proje_service.dart';

class ProjeRepository {
  final ProjeService _projeService = ProjeService();

  // Tüm projeleri getir
  Stream<List<ProjeModel>> getProjeler() {
    return _projeService.getProjeStream();
  }

  // ID'ye göre proje getir
  Future<ProjeModel?> getProjeById(String projeId) {
    return _projeService.getProjeById(projeId);
  }

  // Yeni proje oluştur
  Future<String> createProje(ProjeModel proje) {
    return _projeService.createProje(proje);
  }

  // Proje güncelle
  Future<void> updateProje(ProjeModel proje) {
    return _projeService.updateProje(proje);
  }

  // Proje sil
  Future<void> deleteProje(String projeId) {
    return _projeService.deleteProje(projeId);
  }

  // Tipe göre projeleri getir
  Stream<List<ProjeModel>> getProjelerByTip(ProjeTipi tip) {
    return _projeService.getProjelerByTip(tip);
  }

  // Tamamlanma oranları
  Future<Map<String, int>> getTamamlanmaOranlari() {
    return _projeService.getTamamlanmaOranlari();
  }

  // Tamamlanma oranı güncelle
  Future<void> updateTamamlanmaOrani(String projeId, int oran) {
    return _projeService.updateTamamlanmaOrani(projeId, oran);
  }

  // Personele göre projeleri getir
  Stream<List<ProjeModel>> getProjelerByPersonel(String personelId) {
    return _projeService.getProjelerByPersonel(personelId);
  }

  // Aylık proje istatistikleri
  Future<List<Map<String, dynamic>>> getAylikProjeIstatistikleri() {
    return _projeService.getAylikProjeIstatistikleri();
  }

  // Proje istatistiklerini hesapla
  Future<Map<String, dynamic>> getProjeIstatistikleri() async {
    final projeler = await _projeService.getProjeStream().first;
    final tamamlanmaOranlari = await _projeService.getTamamlanmaOranlari();

    // Toplam bağımsız bölüm sayısı
    int toplamBagimsizBolum = 0;
    // Proje tipi dağılımı
    Map<ProjeTipi, int> tipDagilimi = {
      ProjeTipi.site: 0,
      ProjeTipi.isMerkezi: 0,
      ProjeTipi.karma: 0,
    };
    // Ortalama tamamlanma oranı
    double toplamTamamlanma = 0;
    int tamamlanmaSayisi = 0;

    for (var proje in projeler) {
      // Bağımsız bölüm sayısı
      toplamBagimsizBolum += proje.bagimsizBolumSayisi;

      // Tip dağılımı
      tipDagilimi[proje.tip] = (tipDagilimi[proje.tip] ?? 0) + 1;

      // Tamamlanma oranı
      if (tamamlanmaOranlari.containsKey(proje.id)) {
        toplamTamamlanma += tamamlanmaOranlari[proje.id]!;
        tamamlanmaSayisi++;
      }
    }

    // Ortalama tamamlanma oranı
    double ortalamaTamamlanma =
        tamamlanmaSayisi > 0 ? toplamTamamlanma / tamamlanmaSayisi : 0;

    return {
      'toplamProje': projeler.length,
      'toplamBagimsizBolum': toplamBagimsizBolum,
      'tipDagilimi': {
        'site': tipDagilimi[ProjeTipi.site] ?? 0,
        'isMerkezi': tipDagilimi[ProjeTipi.isMerkezi] ?? 0,
        'karma': tipDagilimi[ProjeTipi.karma] ?? 0,
      },
      'ortalamaTamamlanma': ortalamaTamamlanma,
    };
  }
}
