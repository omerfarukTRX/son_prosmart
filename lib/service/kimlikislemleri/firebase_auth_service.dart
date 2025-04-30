import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_model.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });
}

enum KullaniciDurumu {
  onayBekliyor,
  onaylandi,
  reddedildi,
}

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcı bilgisini al
  User? get currentUser => _auth.currentUser;

  // Kullanıcı oturum durumu akışı
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Kayıt ol
  Future<AuthResult> register({
    required String email,
    required String password,
    required String adSoyad,
    required String telefon,
    KullaniciRolu rol = KullaniciRolu.atanmamis,
  }) async {
    try {
      // Firebase Auth ile kullanıcı oluştur
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return AuthResult(
          success: false,
          errorMessage: 'Kullanıcı oluşturulamadı',
        );
      }

      final user = userCredential.user!;

      // Kullanıcı profilini güncelle (displayName)
      await user.updateDisplayName(adSoyad);

      // Firestore'a kullanıcı bilgilerini kaydet
      final kullanici = KullaniciModel(
        id: user.uid,
        adSoyad: adSoyad,
        email: email,
        telefon: telefon,
        rol: rol,
        aktif: false, // Yeni kullanıcılar pasif başlar (onay bekliyor)
        kayitTarihi: DateTime.now(),
      );

      await _firestore.collection('kullanicilar').doc(user.uid).set({
        ...kullanici.toFirestore(),
        'durum': KullaniciDurumu.onayBekliyor.toString().split('.').last,
      });

      return AuthResult(
        success: true,
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Bu e-posta adresi zaten kullanılıyor';
          break;
        case 'weak-password':
          errorMessage = 'Şifre çok zayıf, daha güçlü bir şifre oluşturun';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi';
          break;
        default:
          errorMessage = 'Kayıt olurken bir hata oluştu: ${e.message}';
      }

      return AuthResult(
        success: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Kayıt olurken bir hata oluştu: $e',
      );
    }
  }

  // Giriş yap
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return AuthResult(
          success: false,
          errorMessage: 'Giriş yapılamadı',
        );
      }

      // Kullanıcı durumunu ve rol bilgisini Firestore'dan kontrol et
      final kullaniciDoc = await _firestore
          .collection('kullanicilar')
          .doc(userCredential.user!.uid)
          .get();

      if (!kullaniciDoc.exists) {
        // Kullanıcı Firestore'da yok, çıkış yap
        await _auth.signOut();
        return AuthResult(
          success: false,
          errorMessage: 'Kullanıcı bulunamadı',
        );
      }

      final kullaniciData = kullaniciDoc.data() as Map<String, dynamic>;
      final durumStr = kullaniciData['durum'] as String? ?? 'onayBekliyor';
      final aktif = kullaniciData['aktif'] as bool? ?? false;

      // Kullanıcı onay durumunu kontrol et
      if (durumStr != KullaniciDurumu.onaylandi.toString().split('.').last ||
          !aktif) {
        // Otomatik çıkış yapma - kullanıcının giriş yapıp onay bekliyor ekranı
        // görmesine izin vermek için çıkış yapmıyoruz
        return AuthResult(
          success: true,
          user: userCredential.user,
        );
      }

      return AuthResult(
        success: true,
        user: userCredential.user,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu e-posta adresine ait kullanıcı bulunamadı';
          break;
        case 'wrong-password':
          errorMessage = 'Hatalı şifre';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi';
          break;
        case 'user-disabled':
          errorMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış';
          break;
        default:
          errorMessage = 'Giriş yaparken bir hata oluştu: ${e.message}';
      }

      return AuthResult(
        success: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Giriş yaparken bir hata oluştu: $e',
      );
    }
  }

  // Çıkış yap
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Şifre sıfırlama maili gönder
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu e-posta adresine ait kullanıcı bulunamadı';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi';
          break;
        default:
          errorMessage =
              'Şifre sıfırlama maili gönderilirken hata oluştu: ${e.message}';
      }

      return AuthResult(
        success: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Şifre sıfırlama maili gönderilirken hata oluştu: $e',
      );
    }
  }

  // Kullanıcı durumunu kontrol et
  Future<KullaniciDurumu> getUserStatus(String userId) async {
    try {
      final doc = await _firestore.collection('kullanicilar').doc(userId).get();

      if (!doc.exists) {
        return KullaniciDurumu.reddedildi;
      }

      final data = doc.data() as Map<String, dynamic>;
      final durumStr = data['durum'] as String? ?? '';

      switch (durumStr) {
        case 'onayBekliyor':
          return KullaniciDurumu.onayBekliyor;
        case 'onaylandi':
          return KullaniciDurumu.onaylandi;
        case 'reddedildi':
          return KullaniciDurumu.reddedildi;
        default:
          return KullaniciDurumu.onayBekliyor;
      }
    } catch (e) {
      print('Kullanıcı durumu kontrol hatası: $e');
      return KullaniciDurumu.onayBekliyor;
    }
  }

  // Kullanıcı rolünü getir
  Future<KullaniciRolu> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('kullanicilar').doc(userId).get();

      if (!doc.exists) {
        return KullaniciRolu.atanmamis;
      }

      final data = doc.data() as Map<String, dynamic>;
      final rolStr = data['rol'] as String? ?? '';

      // Rol string'ini enum'a dönüştür
      return KullaniciRolu.values.firstWhere(
        (rol) => rol.toString().split('.').last == rolStr,
        orElse: () => KullaniciRolu.atanmamis,
      );
    } catch (e) {
      print('Kullanıcı rolü getirme hatası: $e');
      return KullaniciRolu.atanmamis;
    }
  }

  // Kullanıcıya onay ver
  Future<bool> approveUser(String userId) async {
    try {
      await _firestore.collection('kullanicilar').doc(userId).update({
        'durum': KullaniciDurumu.onaylandi.toString().split('.').last,
        'aktif': true,
      });

      return true;
    } catch (e) {
      print('Kullanıcı onaylama hatası: $e');
      return false;
    }
  }

  // Kullanıcı başvurusunu reddet
  Future<bool> rejectUser(String userId) async {
    try {
      await _firestore.collection('kullanicilar').doc(userId).update({
        'durum': KullaniciDurumu.reddedildi.toString().split('.').last,
        'aktif': false,
      });

      return true;
    } catch (e) {
      print('Kullanıcı reddetme hatası: $e');
      return false;
    }
  }

  // Aktif kullanıcı bilgilerini getir
  Future<KullaniciModel?> getCurrentUserDetails() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final doc =
          await _firestore.collection('kullanicilar').doc(user.uid).get();

      if (!doc.exists) {
        return null;
      }

      return KullaniciModel.fromFirestore(doc);
    } catch (e) {
      print('Kullanıcı detayları getirme hatası: $e');
      return null;
    }
  }
}
