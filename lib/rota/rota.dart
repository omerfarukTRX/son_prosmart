import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/admin/menu_manager_screen.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/form/form_builder.dart';
import 'package:prosmart/rota/temelekranlar.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_yonetim_page.dart';
import 'package:prosmart/screens/main_container.dart';
import 'package:prosmart/screens/projeisleri/proje_liste.dart';
import 'package:prosmart/screens/sitesakini/sitesakini.dart';
import 'package:prosmart/service/kimlikislemleri/auth_provider.dart';
import 'package:prosmart/service/kimlikislemleri/kullanici_onaylama_screen.dart';
import 'package:prosmart/service/kimlikislemleri/login_screen.dart';
import 'package:prosmart/service/kimlikislemleri/onay_bekleme_screen.dart';
import 'package:prosmart/service/kimlikislemleri/register_screen.dart';
import '../providers/menu_provider.dart';

class AppRoutes {
  // Sayfa için route belirleme metodu
  static Widget _getPageForRoute(String route) {
    switch (route) {
      case '/dashboard':
        return DashboardScreen();
      case '/kullanici-yonetimi':
        return KullaniciYonetimSayfasi();
      case '/projeler':
        return ProjeListeSayfasi();
      case '/customers':
        return CustomersScreen();
      case '/orders':
        return OrdersScreen();
      case '/settings':
        return SettingsScreen();
      case '/menu-manager':
        return MenuManagerScreen();
      case '/form':
        return FormBuilderScreen(projectId: "U1yAFkROLeFaRkIk2qIg");
      case '/site-sakini-kiraci':
        return SiteSakiniKiraciDashboard();
      default:
        return DashboardScreen();
    }
  }

  // GoRouter yapılandırmasını oluştur
  static GoRouter createRouter(ProviderRef ref) {
    // Kimlik doğrulama durumunu izle
    final authStateAsync = ref.watch(authStateProvider);
    final currentAuthStatus = ref.watch(currentAuthStatusProvider);

    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) async {
        // Mevcut yol
        final path = state.uri.path;

        // Kimlik doğrulama yükleniyor ise
        if (authStateAsync.isLoading) {
          return null; // Yükleme sırasında yönlendirme yapma
        }

        // Kullanıcı oturum açmamış ise
        if (authStateAsync.value == null) {
          // Kullanıcı giriş yapmamış, kimlik doğrulama sayfalarını kontrol et
          if (path == '/login' || path == '/register') {
            return null; // Bu zaten kimlik doğrulama sayfası, yönlendirme yok
          }

          // Diğer tüm sayfalar için giriş sayfasına yönlendir
          return '/login';
        } else {
          // Kullanıcı giriş yapmış, durumunu kontrol et
          switch (currentAuthStatus) {
            case AuthStatus.pendingApproval:
              // Onay bekleyen kullanıcılar sadece onay bekliyor sayfasına erişebilir
              if (path != '/pending-approval') {
                return '/pending-approval';
              }
              return null;

            case AuthStatus.rejected:
              // Reddedilen kullanıcılar sadece reddedildi sayfasına erişebilir
              if (path != '/rejected') {
                return '/rejected';
              }
              return null;

            case AuthStatus.authenticated:
              // Onaylanmış kullanıcılar kimlik doğrulama sayfalarına erişemez
              if (path == '/login' ||
                  path == '/register' ||
                  path == '/pending-approval' ||
                  path == '/rejected') {
                return '/'; // Ana sayfaya yönlendir
              }

              return null; // Diğer sayfalara normal erişim

            case AuthStatus.initial:
            case AuthStatus.unauthenticated:
              // Yükleniyor veya giriş yapmamış durumda
              if (path != '/login' && path != '/register') {
                return '/login';
              }
              return null;
          }
        }

        return null; // Varsayılan durum: Yönlendirme yok
      },
      routes: [
        // Ana sayfa - Rol kontrolü burada yapılıyor
        GoRoute(
          path: '/',
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: Consumer(
                builder: (context, ref, child) {
                  // Kullanıcı rolünü al
                  final userRoleAsync = ref.watch(getCurrentUserRoleProvider);

                  return userRoleAsync.when(
                    loading: () => MainContainer(
                      title: 'Yükleniyor',
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => MainContainer(
                      title: 'Hata',
                      child: Center(
                        child: Text('Rol bilgisi alınamadı: $error'),
                      ),
                    ),
                    data: (userRole) {
                      // Site sakini veya kiracı ise direkt o sayfaya yönlendir
                      if (userRole == KullaniciRolu.siteSakini ||
                          userRole == KullaniciRolu.kiraci) {
                        return MainContainer(
                          title: 'Ana Sayfa',
                          child: const SiteSakiniKiraciDashboard(),
                        );
                      }

                      // Diğer roller için normal menü sistemini kullan
                      final menuItemsAsync = ref.watch(menuItemsProvider);

                      return menuItemsAsync.when(
                        data: (menuItems) {
                          // İlk menü öğesinin route'unu al
                          if (menuItems.isNotEmpty) {
                            final firstMenuRoute = menuItems.first.route;

                            return MainContainer(
                              title: menuItems.first.title,
                              child: _getPageForRoute(firstMenuRoute),
                            );
                          }

                          // Menü öğesi yoksa
                          return MainContainer(
                            title: 'Sayfa Bulunamadı',
                            child: Center(
                              child: Text('Görüntülenecek menü bulunamadı'),
                            ),
                          );
                        },
                        loading: () => MainContainer(
                          title: 'Yükleniyor',
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, stack) => MainContainer(
                          title: 'Hata',
                          child: Center(
                            child: Text('Menü yüklenirken hata oluştu: $error'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),

        // Kimlik doğrulama sayfaları
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => NoTransitionPage(
            child: LoginScreen(),
          ),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (context, state) => NoTransitionPage(
            child: RegisterScreen(),
          ),
        ),
        GoRoute(
          path: '/pending-approval',
          pageBuilder: (context, state) => NoTransitionPage(
            child: PendingApprovalScreen(),
          ),
        ),
        GoRoute(
          path: '/rejected',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Hesap Reddedildi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Üzgünüz, hesap başvurunuz reddedildi. Daha fazla bilgi için yönetici ile iletişime geçin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(logoutProvider.future);
                        context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Kullanıcı onaylama ekranı
        GoRoute(
          path: '/approve-users',
          pageBuilder: (context, state) => NoTransitionPage(
            child: MainContainer(
              title: 'Kullanıcı Onaylama',
              child: ApproveUsersScreen(),
            ),
          ),
        ),

        // Diğer uygulama sayfaları
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => NoTransitionPage(
            child: MainContainer(
              title: 'Gösterge Paneli',
              child: DashboardScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/projeler',
          pageBuilder: (context, state) => NoTransitionPage(
            child: MainContainer(
              title: 'Projeler',
              child: ProjeListeSayfasi(),
            ),
          ),
        ),
        GoRoute(
          path: '/kullanici-yonetimi',
          pageBuilder: (context, state) => NoTransitionPage(
            child: MainContainer(
              title: 'Kullanıcı Yönetimi',
              child: KullaniciYonetimSayfasi(),
            ),
          ),
        ),
        GoRoute(
          path: '/menu-manager',
          pageBuilder: (context, state) => NoTransitionPage(
            child: MainContainer(
              title: 'Menü Yönetimi',
              child: MenuManagerScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/form',
          pageBuilder: (context, state) => NoTransitionPage(
            child: MainContainer(
              title: 'Form Oluşturucu',
              child: FormBuilderScreen(projectId: "U1yAFkROLeFaRkIk2qIg"),
            ),
          ),
        ),
        GoRoute(
          path: '/site-sakini-kiraci',
          pageBuilder: (context, state) => NoTransitionPage(
            child: MainContainer(
              title: 'Ana Sayfa',
              child: const SiteSakiniKiraciDashboard(),
            ),
          ),
        ),
      ],
      errorPageBuilder: (context, state) => MaterialPage(
        child: MainContainer(
          title: 'Hata',
          child: Center(
            child: Text('Sayfa bulunamadı: ${state.error}'),
          ),
        ),
      ),
    );
  }

  // Uygulama başlangıcında kullanılacak statik router (provider kullanılmadan)
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Kimlik doğrulama sayfaları (başlangıçta erişilebilir)
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => NoTransitionPage(
          child: RegisterScreen(),
        ),
      ),

      // Diğer sayfalar (kimlik doğrulamadan önce erişilemez)
      GoRoute(
        path: '/',
        redirect: (_, __) => '/login',
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      child: Scaffold(
        body: Center(
          child: Text('Sayfa bulunamadı: ${state.error}'),
        ),
      ),
    ),
  );
}
