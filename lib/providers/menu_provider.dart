import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/service/firebase_menu_service.dart';
import '../models/menu_model.dart';

// Firebase servis provider'ı
final menuServiceProvider = Provider<FirebaseMenuService>((ref) {
  return FirebaseMenuService();
});

// Mevcut kullanıcının rolünü getiren provider
final currentUserRoleProvider =
    FutureProvider<List<KullaniciRolu>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return [KullaniciRolu.atanmamis];
  }

  try {
    final userData = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(user.uid)
        .get();

    if (userData.exists) {
      final rolStr = userData.data()?['rol'] as String? ?? 'atanmamis';

      final rol = KullaniciRolu.values.firstWhere(
          (r) => r.toString().split('.').last == rolStr,
          orElse: () => KullaniciRolu.atanmamis);

      return [rol];
    }

    return [KullaniciRolu.atanmamis];
  } catch (e) {
    print('Kullanıcı rolü alınırken hata: $e');
    return [KullaniciRolu.atanmamis];
  }
});

// Menü stream provider'ı - Firestore'dan gelen verileri dinler
final menuStreamProvider = StreamProvider<List<MenuModel>>((ref) {
  final menuService = ref.read(menuServiceProvider);
  return menuService.getMenus();
});

// Rol bazlı filtrelenmiş menü öğeleri provider'ı
final menuItemsProvider = StreamProvider<List<MenuModel>>((ref) {
  final menuService = ref.read(menuServiceProvider);
  final userRoleAsync = ref.watch(currentUserRoleProvider);

  return userRoleAsync.when(
    data: (userRoles) {
      return menuService.getMenus().map((menus) {
        // Rollere göre menüleri filtrele
        final filteredMenus = menus.where((menu) {
          // Menü aktif mi?
          if (!menu.isActive) return false;

          // Menünün rolleri ile kullanıcının rolleri kesişiyor mu?
          final match = menu.roles.any((menuRole) =>
              userRoles.any((userRole) => userRole.ad == menuRole));

          // Debug için eşleşen menüleri yazdır
          if (match) {
            print('Eşleşen Menü: ${menu.title}, Menü Rolleri: ${menu.roles}');
          }

          return match;
        }).toList();

        print('Toplam Filtrelenmiş Menü Sayısı: ${filteredMenus.length}');
        return filteredMenus;
      });
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Menü işlemlerini yöneten provider
final menuNotifierProvider =
    StateNotifierProvider<MenuNotifier, AsyncValue<void>>((ref) {
  final menuService = ref.read(menuServiceProvider);
  return MenuNotifier(menuService);
});

class MenuNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseMenuService _menuService;

  MenuNotifier(this._menuService) : super(const AsyncValue.data(null));

  // Yeni menü ekle
  Future<void> addMenu(MenuModel menu) async {
    state = const AsyncValue.loading();
    try {
      await _menuService.addMenu(menu);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Menü güncelle
  Future<void> updateMenu(MenuModel menu) async {
    state = const AsyncValue.loading();
    try {
      await _menuService.updateMenu(menu);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Menü sil
  Future<void> deleteMenu(String menuId) async {
    state = const AsyncValue.loading();
    try {
      await _menuService.deleteMenu(menuId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Menü sıralamasını güncelle
  Future<void> reorderMenus(List<MenuModel> menus) async {
    state = const AsyncValue.loading();
    try {
      await _menuService.reorderMenus(menus);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Seçili menü id'sini tutan provider
final selectedMenuIdProvider = StateProvider<String?>((ref) => null);

// Loading durumunu kontrol eden provider
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(menuNotifierProvider).isLoading;
});

// Hata durumunu kontrol eden provider
final errorProvider = Provider<String?>((ref) {
  final state = ref.watch(menuNotifierProvider);
  return state.hasError ? state.error.toString() : null;
});
