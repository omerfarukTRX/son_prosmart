import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_model.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_service.dart';

// Kullanıcı servisi provider
final kullaniciServiceProvider = Provider<KullaniciService>((ref) {
  return KullaniciService();
});

// Tüm kullanıcılar stream provider
final kullanicilarProvider = StreamProvider<List<KullaniciModel>>((ref) {
  final service = ref.watch(kullaniciServiceProvider);
  return service.getKullanicilarStream();
});

// Kullanıcı ekleme provider
final kullaniciEkleProvider =
    FutureProvider.family<String, KullaniciModel>((ref, kullanici) async {
  final service = ref.watch(kullaniciServiceProvider);
  return service.createKullanici(kullanici);
});

// Kullanıcı güncelleme provider
final kullaniciGuncelleProvider =
    FutureProvider.family<void, KullaniciModel>((ref, kullanici) async {
  final service = ref.watch(kullaniciServiceProvider);
  return service.updateKullanici(kullanici);
});

// Kullanıcı silme provider
final kullaniciSilProvider =
    FutureProvider.family<void, String>((ref, kullaniciId) async {
  final service = ref.watch(kullaniciServiceProvider);
  return service.deleteKullanici(kullaniciId);
});

// Tek kullanıcı getirme provider
final tekKullaniciProvider =
    FutureProvider.family<KullaniciModel?, String>((ref, kullaniciId) async {
  final service = ref.watch(kullaniciServiceProvider);
  return service.getKullaniciById(kullaniciId);
});

// İlgili rollerdeki kullanıcıları getirme provider
final roldekiKullanicilarProvider =
    Provider.family<List<KullaniciModel>, List<String>>((ref, roller) {
  final kullanicilarAsyncValue = ref.watch(kullanicilarProvider);

  return kullanicilarAsyncValue.when(
    data: (kullanicilar) => kullanicilar
        .where((kullanici) => roller.contains(kullanici.rol.ad))
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Kullanıcı arama provider
final kullaniciAramaProvider = StateProvider<String>((ref) => '');

// Filtrelenmiş kullanıcı listesi provider
final filtrelenmisKullanicilarProvider = Provider<List<KullaniciModel>>((ref) {
  final kullanicilarAsyncValue = ref.watch(kullanicilarProvider);
  final aramaMetni = ref.watch(kullaniciAramaProvider);

  return kullanicilarAsyncValue.when(
    data: (kullanicilar) {
      if (aramaMetni.isEmpty) {
        return kullanicilar;
      }

      final aramaLower = aramaMetni.toLowerCase();
      return kullanicilar.where((kullanici) {
        return kullanici.adSoyad.toLowerCase().contains(aramaLower) ||
            kullanici.email.toLowerCase().contains(aramaLower) ||
            kullanici.telefon.contains(aramaMetni);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Aktif kullanıcıları getirme provider
final aktifKullanicilarProvider = Provider<List<KullaniciModel>>((ref) {
  final kullanicilarAsyncValue = ref.watch(kullanicilarProvider);

  return kullanicilarAsyncValue.when(
    data: (kullanicilar) => kullanicilar.where((k) => k.aktif).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Onay bekleyen kullanıcıları getiren provider
final pendingUsersProvider = StreamProvider<List<KullaniciModel>>((ref) {
  final service = ref.watch(kullaniciServiceProvider);
  return service.getPendingUsers();
});

// Kullanıcı rol dağılımı provider
final kullaniciRolDagilimProvider = Provider<Map<String, int>>((ref) {
  final kullanicilarAsyncValue = ref.watch(kullanicilarProvider);

  return kullanicilarAsyncValue.when(
    data: (kullanicilar) {
      final rolDagilim = <String, int>{};

      for (var kullanici in kullanicilar) {
        // Enum'ın string temsilini kullan
        final String rolAdi = _getRolGorunenAd(kullanici.rol);
        rolDagilim[rolAdi] = (rolDagilim[rolAdi] ?? 0) + 1;
      }

      return rolDagilim;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// Yardımcı fonksiyon - Rol görünen adını al
String _getRolGorunenAd(KullaniciRolu rol) {
  switch (rol) {
    case KullaniciRolu.sirketYoneticisi:
      return 'Şirket Yöneticisi';
    case KullaniciRolu.siteYoneticisi:
      return 'Site Yöneticisi';
    case KullaniciRolu.sahaCalisani:
      return 'Saha Personeli';
    case KullaniciRolu.ofisCalisani:
      return 'Ofis Personeli';
    case KullaniciRolu.teknikPersonel:
      return 'Teknik Personel';
    case KullaniciRolu.peyzajPersoneli:
      return 'Peyzaj Personeli';
    case KullaniciRolu.temizlikPersoneli:
      return 'Temizlik Personeli';
    case KullaniciRolu.guvenlikPersoneli:
      return 'Güvenlik Personeli';
    case KullaniciRolu.danismaPersoneli:
      return 'Danışma Personeli';
    case KullaniciRolu.siteSakini:
      return 'Kat Maliki';
    case KullaniciRolu.kiraci:
      return 'Kiracı';
    case KullaniciRolu.usta:
      return 'Usta';
    case KullaniciRolu.tedarikci:
      return 'Tedarikçi';
    case KullaniciRolu.atanmamis:
      return 'Atanmamış';
    default:
      return 'Bilinmeyen Rol';
  }
}
