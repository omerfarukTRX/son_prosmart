import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/widgets/menu_edit_dialog.dart';
import '../providers/menu_provider.dart';
import '../models/menu_model.dart';
import '../utils/icon_helper.dart';

class MenuManagerScreen extends ConsumerStatefulWidget {
  const MenuManagerScreen({super.key});

  @override
  _MenuManagerScreenState createState() => _MenuManagerScreenState();
}

class _MenuManagerScreenState extends ConsumerState<MenuManagerScreen> {
  // Seçili roller için state
  final List<KullaniciRolu> _selectedRoles = [];

  @override
  Widget build(BuildContext context) {
    final menuStream = ref.watch(menuStreamProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve Yeni Ekle Butonu
            Row(
              children: [
                const Text(
                  'Menü Yönetimi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Menü'),
                  onPressed: () => _showMenuDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rol Filtreleme
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: KullaniciRolu.values
                    .where((role) => role != KullaniciRolu.atanmamis)
                    .map((role) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: FilterChip(
                            label: Text(role.gorunenAd),
                            selected: _selectedRoles.contains(role),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedRoles.add(role);
                                } else {
                                  _selectedRoles.remove(role);
                                }
                              });
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Menü Listesi
            Expanded(
              child: menuStream.when(
                data: (menus) {
                  // Rol filtrelemesi
                  final filteredMenus = _selectedRoles.isEmpty
                      ? menus
                      : menus.where((menu) {
                          return menu.roles.any((roleStr) => _selectedRoles.any(
                              (selectedRole) => selectedRole.ad == roleStr));
                        }).toList();

                  if (filteredMenus.isEmpty) {
                    return const Center(
                      child: Text('Seçilen rollere ait menü bulunmuyor'),
                    );
                  }

                  return ReorderableListView.builder(
                    itemCount: filteredMenus.length,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final List<MenuModel> newMenus = List.from(filteredMenus);
                      final item = newMenus.removeAt(oldIndex);
                      newMenus.insert(newIndex, item);

                      ref
                          .read(menuNotifierProvider.notifier)
                          .reorderMenus(newMenus);
                    },
                    itemBuilder: (context, index) {
                      final menu = filteredMenus[index];
                      return Card(
                        key: ValueKey(menu.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(IconHelper.getIcon(menu.icon)),
                          title: Text(menu.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(menu.route),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: menu.roles.map((role) {
                                  return Chip(
                                    label: Text(
                                      // Görünen adı kullan
                                      KullaniciRolu.values
                                          .firstWhere((r) => r.ad == role,
                                              orElse: () =>
                                                  KullaniciRolu.atanmamis)
                                          .gorunenAd,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Aktif/Pasif switch
                              Switch(
                                value: menu.isActive,
                                onChanged: (value) {
                                  final updatedMenu = menu.copyWith(
                                    isActive: value,
                                  );
                                  ref
                                      .read(menuNotifierProvider.notifier)
                                      .updateMenu(updatedMenu);
                                },
                              ),
                              // Düzenle butonu
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showMenuDialog(
                                  context,
                                  ref,
                                  menu,
                                ),
                              ),
                              // Sil butonu
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _showDeleteDialog(
                                  context,
                                  ref,
                                  menu,
                                ),
                              ),
                              // Sürükle ikonu
                              const Icon(
                                Icons.drag_handle,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Hata: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMenuDialog(
    BuildContext context,
    WidgetRef ref, [
    MenuModel? menu,
  ]) async {
    final result = await showDialog<MenuModel>(
      context: context,
      builder: (context) => MenuEditDialog(menu: menu),
    );

    if (result != null) {
      if (menu == null) {
        // Yeni menü
        await ref.read(menuNotifierProvider.notifier).addMenu(result);
      } else {
        // Menü güncelleme
        await ref.read(menuNotifierProvider.notifier).updateMenu(result);
      }
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    MenuModel menu,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menüyü Sil'),
        content:
            Text('${menu.title} menüsünü silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(menuNotifierProvider.notifier).deleteMenu(menu.id);
    }
  }
}
