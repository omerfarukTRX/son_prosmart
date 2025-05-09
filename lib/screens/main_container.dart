import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosmart/config/theme/scale_theme.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/providers/menu_provider.dart';
import 'package:prosmart/utils/icon_helper.dart';

class MainContainer extends ConsumerWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;

  const MainContainer({
    super.key,
    required this.child,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRoleAsync = ref.watch(currentUserRoleProvider);

    return userRoleAsync.when(
      data: (userRoles) {
        // Site sakini veya kiracı ise menü gösterme
        final isSiteSakiniKiraci =
            userRoles.contains(KullaniciRolu.siteSakini) ||
                userRoles.contains(KullaniciRolu.kiraci);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 1100;

            // Site sakini/kiracı için sadece app bar ve içerik göster
            if (isSiteSakiniKiraci) {
              return Scaffold(
                appBar: MainAppBar(
                  title: title,
                  actions: actions,
                  showMenuButton: false,
                ),
                body: child,
              );
            }

            // Diğer roller için normal layout
            return Scaffold(
              body: isWideScreen
                  ? Row(
                      children: [
                        const MainDrawer(),
                        Expanded(
                          child: Column(
                            children: [
                              MainAppBar(title: title, actions: actions),
                              Expanded(child: child),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        MainAppBar(
                          title: title,
                          actions: actions,
                          showMenuButton: true,
                        ),
                        Expanded(child: child),
                      ],
                    ),
              drawer: isWideScreen ? null : const MainDrawer(),
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Hata: $error')),
      ),
    );
  }
}

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showMenuButton;

  const MainAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showMenuButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          const SizedBox(width: 24),
          Text(
            title,
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          const Spacer(),
          if (actions != null) ...actions!,
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firestore menü öğelerini al
    final menuItemsAsync = ref.watch(menuItemsProvider);

    return Container(
      width: ScaleTheme.sidebarWidth,
      color: ScaleColors.sidebar,
      child: Column(
        children: [
          // Logo ve Başlık
          Container(
            height: ScaleTheme.drawerHeaderHeight,
            padding: const EdgeInsets.all(1),
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
            ),
          ),
          const Divider(),

          // Kullanıcı Profili (şimdilik statik)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: ScaleColors.accent,
                  child: Text('JS'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'John Smith',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Art Director',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Menü Öğeleri
          Expanded(
            child: menuItemsAsync.when(
              data: (menuItems) {
                // Aktif menüleri listele
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: menuItems.map((menu) {
                    return _buildMenuItem(
                      context: context,
                      icon: IconHelper.getIcon(menu.icon),
                      title: menu.title,
                      route: menu.route,
                      // İlk menü seçili olarak gösterilsin
                      isSelected: menuItems.first.id == menu.id,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Menü yüklenirken hata oluştu: $error'),
              ),
            ),
          ),

          // Alt Menü
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.admin_panel_settings,
                  title: 'Admin',
                  route: '/menu-manager',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.logout,
                  title: 'Çıkış',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? route,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected
            ? ScaleColors.accent.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          height: 36,
          child: ListTile(
            leading: Icon(
              icon,
              size: 18,
              color: isSelected ? ScaleColors.accent : ScaleColors.sidebarText,
            ),
            title: Text(
              title,
              style: TextStyle(
                color:
                    isSelected ? ScaleColors.accent : ScaleColors.sidebarText,
                fontSize: 13,
              ),
            ),
            dense: true,
            horizontalTitleGap: 12,
            minLeadingWidth: 0,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            onTap: () {
              if (route != null) {
                // Drawer'ı kapat
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }

                // Sayfaya git
                context.go(route);
              }
            },
          ),
        ),
      ),
    );
  }
}
