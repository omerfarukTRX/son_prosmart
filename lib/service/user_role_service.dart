import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';

class UserRoleService {
  Future<KullaniciRolu> getCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return KullaniciRolu.atanmamis;
    }

    try {
      final userData = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        final rolStr = userData.data()?['rol'] as String? ?? 'atanmamis';

        return KullaniciRolu.values.firstWhere(
          (r) => r.toString().split('.').last == rolStr,
          orElse: () => KullaniciRolu.atanmamis,
        );
      }

      return KullaniciRolu.atanmamis;
    } catch (e) {
      print('Kullanıcı rolü alınırken hata: $e');
      return KullaniciRolu.atanmamis;
    }
  }
}
