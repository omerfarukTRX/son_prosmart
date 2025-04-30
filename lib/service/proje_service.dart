import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prosmart/models/proje_model.dart';

class ProjeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'projeler';

  // Tüm projeleri getir
  Stream<List<ProjeModel>> getProjeStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ProjeModel.fromFirestore(doc)).toList());
  }

  // Tek bir projeyi ID'ye göre getir
  Future<ProjeModel?> getProjeById(String projeId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(projeId).get();
      if (doc.exists) {
        return ProjeModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Proje getirme hatası: $e');
      rethrow;
    }
  }

  // Yeni proje oluştur
  Future<String> createProje(ProjeModel proje) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(proje.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Proje oluşturma hatası: $e');
      rethrow;
    }
  }

  // Proje güncelle
  Future<void> updateProje(ProjeModel proje) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(proje.id)
          .update(proje.toFirestore());
    } catch (e) {
      print('Proje güncelleme hatası: $e');
      rethrow;
    }
  }

  // Proje sil
  Future<void> deleteProje(String projeId) async {
    try {
      await _firestore.collection(_collection).doc(projeId).delete();
    } catch (e) {
      print('Proje silme hatası: $e');
      rethrow;
    }
  }

  // Tipe göre projeleri getir
  Stream<List<ProjeModel>> getProjelerByTip(ProjeTipi tip) {
    return _firestore
        .collection(_collection)
        .where('tip', isEqualTo: tip.toString().split('.').last)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProjeModel.fromFirestore(doc)).toList());
  }

  // Tamamlanma oranlarını getir (farklı bir koleksiyondan)
  Future<Map<String, int>> getTamamlanmaOranlari() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('proje_ilerlemeler').get();
      Map<String, int> oranlar = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        oranlar[doc.id] = data['tamamlanmaOrani'] ?? 0;
      }

      return oranlar;
    } catch (e) {
      print('Tamamlanma oranları getirme hatası: $e');
      return {};
    }
  }

  // Proje tamamlanma oranını güncelle
  Future<void> updateTamamlanmaOrani(String projeId, int oran) async {
    try {
      await _firestore.collection('proje_ilerlemeler').doc(projeId).set({
        'tamamlanmaOrani': oran,
        'sonGuncelleme': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Tamamlanma oranı güncelleme hatası: $e');
      rethrow;
    }
  }

  // Yetkili personele göre projeleri getir
  Stream<List<ProjeModel>> getProjelerByPersonel(String personelId) {
    return _firestore
        .collection(_collection)
        .where('yetkiliPersonelIdleri', arrayContains: personelId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProjeModel.fromFirestore(doc)).toList());
  }

  // Aylık proje ekleme istatistiklerini getir
  Future<List<Map<String, dynamic>>> getAylikProjeIstatistikleri() async {
    try {
      // Son 6 ay için başlangıç tarihi
      DateTime baslangic = DateTime.now().subtract(const Duration(days: 180));

      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('olusturulmaTarihi',
              isGreaterThanOrEqualTo: Timestamp.fromDate(baslangic))
          .orderBy('olusturulmaTarihi')
          .get();

      // Aylara göre gruplama
      Map<String, int> aylikSayim = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['olusturulmaTarihi'] != null) {
          Timestamp ts = data['olusturulmaTarihi'] as Timestamp;
          DateTime tarih = ts.toDate();
          String ayYil = '${tarih.month}-${tarih.year}';

          aylikSayim[ayYil] = (aylikSayim[ayYil] ?? 0) + 1;
        }
      }

      // Sıralı liste oluştur
      List<Map<String, dynamic>> sonuc = [];
      aylikSayim.forEach((key, value) {
        final parcalar = key.split('-');
        final ay = int.parse(parcalar[0]);
        final yil = int.parse(parcalar[1]);

        sonuc.add({'ay': _ayAdiGetir(ay), 'yil': yil, 'sayi': value});
      });

      return sonuc
        ..sort((a, b) {
          int yilFark = a['yil'] - b['yil'];
          if (yilFark == 0) {
            return _ayIndex(a['ay']) - _ayIndex(b['ay']);
          }
          return yilFark;
        });
    } catch (e) {
      print('Aylık istatistik hatası: $e');
      return [];
    }
  }

  // Yardımcı metodlar
  String _ayAdiGetir(int ay) {
    const aylar = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    return aylar[ay - 1];
  }

  int _ayIndex(String ay) {
    const aylar = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    return aylar.indexOf(ay);
  }
}
