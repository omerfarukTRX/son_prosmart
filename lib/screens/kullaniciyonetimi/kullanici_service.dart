import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

import 'package:prosmart/screens/kullaniciyonetimi/kullanici_model.dart';
import 'package:prosmart/service/kimlikislemleri/firebase_auth_service.dart';

class KullaniciService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Koleksiyon referansı
  CollectionReference get _kullanicilarCollection =>
      _firestore.collection('kullanicilar');

  // Kullanıcıları stream olarak getir
  Stream<List<KullaniciModel>> getKullanicilarStream() {
    return _kullanicilarCollection.orderBy('adSoyad').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => KullaniciModel.fromFirestore(doc))
            .toList());
  }

  // Tek kullanıcı bilgisini getir
  Future<KullaniciModel?> getKullaniciById(String kullaniciId) async {
    try {
      DocumentSnapshot doc =
          await _kullanicilarCollection.doc(kullaniciId).get();

      if (doc.exists) {
        return KullaniciModel.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      print('Kullanıcı getirme hatası: $e');
      rethrow;
    }
  }

  // Rol bazlı kullanıcıları getir
  Future<List<KullaniciModel>> getKullanicilarByRol(String rol) async {
    try {
      QuerySnapshot query = await _kullanicilarCollection
          .where('rol', isEqualTo: rol)
          .orderBy('adSoyad')
          .get();

      return query.docs
          .map((doc) => KullaniciModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Rolle kullanıcı getirme hatası: $e');
      return [];
    }
  }

  // Kullanıcı oluştur
  Future<String> createKullanici(KullaniciModel kullanici) async {
    try {
      // E-posta adresinin benzersiz olduğunu kontrol et
      QuerySnapshot emailCheck = await _kullanicilarCollection
          .where('email', isEqualTo: kullanici.email)
          .get();

      if (emailCheck.docs.isNotEmpty) {
        throw Exception('Bu e-posta adresi zaten kullanılıyor');
      }

      final docRef = await _kullanicilarCollection.add(kullanici.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Kullanıcı oluşturma hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı güncelle
  Future<void> updateKullanici(KullaniciModel kullanici) async {
    try {
      // E-posta adresinin benzersiz olduğunu kontrol et (kendisi hariç)
      QuerySnapshot emailCheck = await _kullanicilarCollection
          .where('email', isEqualTo: kullanici.email)
          .get();

      bool emailExists = emailCheck.docs.any((doc) => doc.id != kullanici.id);

      if (emailExists) {
        throw Exception('Bu e-posta adresi zaten kullanılıyor');
      }

      await _kullanicilarCollection
          .doc(kullanici.id)
          .update(kullanici.toFirestore());
    } catch (e) {
      print('Kullanıcı güncelleme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı sil
  Future<void> deleteKullanici(String kullaniciId) async {
    try {
      // Kullanıcıya ait profil fotoğrafını da silme
      final kullanici = await getKullaniciById(kullaniciId);
      if (kullanici != null && kullanici.profilFotoUrl != null) {
        try {
          // Storage yolunu URL'den çıkar
          final Uri uri = Uri.parse(kullanici.profilFotoUrl!);
          final path = uri.pathSegments.join('/');

          if (path.isNotEmpty) {
            await _storage.ref(path).delete();
          }
        } catch (e) {
          print('Profil fotoğrafı silme hatası: $e');
        }
      }

      await _kullanicilarCollection.doc(kullaniciId).delete();
    } catch (e) {
      print('Kullanıcı silme hatası: $e');
      rethrow;
    }
  }

  // Profil fotoğrafı yükle
  Future<String> uploadProfilePhoto(
      String kullaniciId, Uint8List imageData) async {
    try {
      final path = 'kullanici_profil_fotograflari/$kullaniciId.jpg';
      final ref = _storage.ref().child(path);

      final uploadTask = ref.putData(
        imageData,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Kullanıcı profilini güncelle
      await _kullanicilarCollection.doc(kullaniciId).update({
        'profilFotoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      print('Profil fotoğrafı yükleme hatası: $e');
      rethrow;
    }
  }

  // Aktif kullanıcı sayısını getir
  Future<int> getAktifKullaniciSayisi() async {
    try {
      final query = await _kullanicilarCollection
          .where('aktif', isEqualTo: true)
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      print('Aktif kullanıcı sayısı getirme hatası: $e');
      return 0;
    }
  }

  // Rol dağılımını getir
  Future<Map<String, int>> getRolDagilimi() async {
    try {
      final snapshot = await _kullanicilarCollection.get();
      final Map<String, int> rolDagilimi = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rol = data['rol'] as String? ?? 'atanmamis';

        rolDagilimi[rol] = (rolDagilimi[rol] ?? 0) + 1;
      }

      return rolDagilimi;
    } catch (e) {
      print('Rol dagilimi getirme hatasi: $e');
      return {};
    }
  }

  // E-posta ile kullanıcı ara
  Future<KullaniciModel?> findKullaniciByEmail(String email) async {
    try {
      final query = await _kullanicilarCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return KullaniciModel.fromFirestore(query.docs.first);
    } catch (e) {
      print('E-posta ile kullanıcı arama hatası: $e');
      return null;
    }
  }

  // Kullanıcı aktivasyon durumunu değiştir
  Future<void> updateKullaniciAktif(String kullaniciId, bool aktif) async {
    try {
      await _kullanicilarCollection.doc(kullaniciId).update({
        'aktif': aktif,
      });
    } catch (e) {
      print('Kullanıcı aktivasyon hatası: $e');
      rethrow;
    }
  }

  // Belirli bir kategorideki kullanıcıları getir
  Future<List<KullaniciModel>> getKullanicilarByCategory(
      List<String> roller) async {
    try {
      // Firestore sorgularında "in" operatörü ile çoklu rol kontrolü
      QuerySnapshot query = await _kullanicilarCollection
          .where('rol', whereIn: roller)
          .orderBy('adSoyad')
          .get();

      return query.docs
          .map((doc) => KullaniciModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Kategori bazlı kullanıcı getirme hatası: $e');
      return [];
    }
  }

  // Kullanıcı ek bilgilerini güncelle
  Future<void> updateKullaniciEkBilgiler(
      String kullaniciId, Map<String, dynamic> ekBilgiler) async {
    try {
      await _kullanicilarCollection.doc(kullaniciId).update({
        'ekBilgiler': ekBilgiler,
      });
    } catch (e) {
      print('Kullanıcı ek bilgileri güncelleme hatası: $e');
      rethrow;
    }
  }

  // Çoklu kullanıcı silme (toplu işlem)
  Future<void> deleteMultipleKullanicilar(List<String> kullaniciIdler) async {
    try {
      final batch = _firestore.batch();

      for (var id in kullaniciIdler) {
        batch.delete(_kullanicilarCollection.doc(id));
      }

      await batch.commit();
    } catch (e) {
      print('Çoklu kullanıcı silme hatası: $e');
      rethrow;
    }
  }

  // Toplu kullanıcı rolü güncelleme
  Future<void> updateMultipleKullaniciRol(
      List<String> kullaniciIdler, String yeniRol) async {
    try {
      final batch = _firestore.batch();

      for (var id in kullaniciIdler) {
        batch.update(_kullanicilarCollection.doc(id), {'rol': yeniRol});
      }

      await batch.commit();
    } catch (e) {
      print('Toplu rol güncelleme hatası: $e');
      rethrow;
    }
  }

  Stream<List<KullaniciModel>> getPendingUsers() {
    return _kullanicilarCollection
        .where('durum',
            isEqualTo: KullaniciDurumu.onayBekliyor.toString().split('.').last)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KullaniciModel.fromFirestore(doc))
            .toList());
  }
}
