import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Kimlik doğrulama durumları
enum AuthStatus {
  initial, // Başlangıç durumu
  unauthenticated, // Giriş yapılmamış
  pendingApproval, // Onay bekliyor
  rejected, // Reddedilmiş
  authenticated // Onaylanmış
}

// Login parametreleri
class LoginParams {
  final String email;
  final String password;

  LoginParams({
    required this.email,
    required this.password,
  });
}

// Kayıt parametreleri
class RegisterParams {
  final String email;
  final String password;
  final String displayName;

  RegisterParams({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

// Authentication sonuç sınıfı
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

// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Firebase Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Kullanıcı durumu stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Kullanıcı verileri provider
final userDataProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
  final firestore = ref.watch(firestoreProvider);
  final docSnapshot = await firestore.collection('kullanicilar').doc(uid).get();

  if (docSnapshot.exists) {
    return docSnapshot.data();
  }
  return null;
});

// Kullanıcı durumu provider (onaylanmış, onay bekliyor, reddedilmiş, vb.)
final authStatusProvider = Provider<AuthStatus>((ref) {
  final authState = ref.watch(authStateProvider);

  // Yükleniyor durumu
  if (authState.isLoading) {
    return AuthStatus.initial;
  }

  // Hata durumu
  if (authState.hasError) {
    return AuthStatus.unauthenticated;
  }

  // Kullanıcı giriş yapmamışsa
  if (authState.value == null) {
    return AuthStatus.unauthenticated;
  }

  // Kullanıcı oturum açmışsa, mevcut durumu kontrol et
  final user = authState.value;

  // Mevcut durumu öğrenmek için currentAuthStatusProvider'a bak
  final currentStatus = ref.watch(currentAuthStatusProvider);

  // Initial değilse, mevcut durumu kullan
  if (currentStatus != AuthStatus.initial) {
    return currentStatus;
  }

  // Eğer currentStatus yoksa AuthStatus.pendingApproval'ı göster
  return AuthStatus.pendingApproval;
});

// Anlık kimlik doğrulama durumu provider
final currentAuthStatusProvider = StateProvider<AuthStatus>((ref) {
  return AuthStatus.initial;
});

// Giriş işlemi provider
final loginProvider = FutureProvider.family<AuthResult, LoginParams>(
  (ref, params) async {
    try {
      final userCredential =
          await ref.read(firebaseAuthProvider).signInWithEmailAndPassword(
                email: params.email,
                password: params.password,
              );

      final user = userCredential.user;
      if (user != null) {
        await user.getIdToken(true);
        final userData = await ref
            .read(firestoreProvider)
            .collection('kullanicilar')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          final durum = userData.data()?['durum'] as String?;

          switch (durum) {
            case 'onayBekliyor':
              ref.read(currentAuthStatusProvider.notifier).state =
                  AuthStatus.pendingApproval;
              break;
            case 'reddedildi':
              ref.read(currentAuthStatusProvider.notifier).state =
                  AuthStatus.rejected;
              break;
            case 'onaylandi':
              ref.read(currentAuthStatusProvider.notifier).state =
                  AuthStatus.authenticated;
              break;
            default:
              ref.read(currentAuthStatusProvider.notifier).state =
                  AuthStatus.pendingApproval;
          }
        } else {
          // Kullanıcı verisi yoksa, oluştur ve onay bekliyor olarak işaretle
          await ref
              .read(firestoreProvider)
              .collection('kullanicilar')
              .doc(user.uid)
              .set({
            'email': user.email,
            'durum': 'onayBekliyor',
            'kayitTarihi': FieldValue.serverTimestamp(),
          });
          ref.read(currentAuthStatusProvider.notifier).state =
              AuthStatus.pendingApproval;
        }

        return AuthResult(
          success: true,
          user: user,
        );
      }

      return AuthResult(
        success: false,
        errorMessage: 'Kullanıcı bulunamadı',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  },
);

// Kayıt işlemi provider
final registerProvider = FutureProvider.family<AuthResult, RegisterParams>(
  (ref, params) async {
    try {
      final userCredential =
          await ref.read(firebaseAuthProvider).createUserWithEmailAndPassword(
                email: params.email,
                password: params.password,
              );

      final user = userCredential.user;
      if (user != null) {
        // Kullanıcı bilgilerini Firestore'a kaydet
        await ref
            .read(firestoreProvider)
            .collection('kullanicilar')
            .doc(user.uid)
            .set({
          'email': params.email,
          'adSoyad': params.displayName,
          'durum': 'onayBekliyor', // Varsayılan durum onay bekliyor
          'kayitTarihi': FieldValue.serverTimestamp(),
        });

        // Anlık durumu güncelle
        ref.read(currentAuthStatusProvider.notifier).state =
            AuthStatus.pendingApproval;

        return AuthResult(
          success: true,
          user: user,
        );
      }

      return AuthResult(
        success: false,
        errorMessage: 'Kullanıcı oluşturulamadı',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  },
);

// Çıkış işlemi provider
final logoutProvider = FutureProvider<void>((ref) async {
  await ref.read(firebaseAuthProvider).signOut();
  ref.read(currentAuthStatusProvider.notifier).state =
      AuthStatus.unauthenticated;
});

// Şifre sıfırlama provider
final resetPasswordProvider =
    FutureProvider.family<AuthResult, String>((ref, email) async {
  try {
    await ref.read(firebaseAuthProvider).sendPasswordResetEmail(email: email);
    return AuthResult(success: true);
  } catch (e) {
    return AuthResult(
      success: false,
      errorMessage: e.toString(),
    );
  }
});

// Kullanıcı onaylama provider
final approveUserProvider =
    FutureProvider.family<bool, String>((ref, userId) async {
  try {
    await ref
        .read(firestoreProvider)
        .collection('kullanicilar')
        .doc(userId)
        .update({
      'durum': 'onaylandi',
      'onayTarihi': FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    return false;
  }
});

// Kullanıcı reddetme provider
final rejectUserProvider =
    FutureProvider.family<bool, String>((ref, userId) async {
  try {
    await ref
        .read(firestoreProvider)
        .collection('kullanicilar')
        .doc(userId)
        .update({
      'durum': 'reddedildi',
      'reddedilmeTarihi': FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    return false;
  }
});
