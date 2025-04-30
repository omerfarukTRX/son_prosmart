import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_edit_dialog.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_model.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_provider.dart';

class KullaniciYonetimSayfasi extends ConsumerStatefulWidget {
  const KullaniciYonetimSayfasi({super.key});

  @override
  ConsumerState<KullaniciYonetimSayfasi> createState() =>
      _KullaniciYonetimSayfasiState();
}

class _KullaniciYonetimSayfasiState
    extends ConsumerState<KullaniciYonetimSayfasi>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  KullaniciRolu? _selectedRoleFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kullanicilarAsyncValue = ref.watch(kullanicilarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Prosit Çalışanları'),
            Tab(text: 'Site Çalışanları'),
            Tab(text: 'Site Sakinleri'),
            Tab(text: 'Tedarikçiler'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(kullanicilarProvider);
            },
            tooltip: 'Listeyi Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve filtre alanı
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Kullanıcı ara...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Rol filtresi
                DropdownButton<KullaniciRolu?>(
                  value: _selectedRoleFilter,
                  hint: const Text('Tüm Roller'),
                  onChanged: (value) {
                    setState(() {
                      _selectedRoleFilter = value;
                    });
                  },
                  items: [
                    const DropdownMenuItem<KullaniciRolu?>(
                      value: null,
                      child: Text('Tüm Roller'),
                    ),
                    ...KullaniciRolu.values.map((role) {
                      return DropdownMenuItem<KullaniciRolu?>(
                        value: role,
                        child: Text(_getRolGorunenAd(role)),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          // Tab içerikleri
          Expanded(
            child: kullanicilarAsyncValue.when(
              data: (kullanicilar) {
                final filteredKullanicilar = _filterKullanicilar(kullanicilar);

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Prosit Çalışanları
                    _buildUserList(filteredKullanicilar, [
                      KullaniciRolu.sirketYoneticisi,
                      KullaniciRolu.sahaCalisani,
                      KullaniciRolu.ofisCalisani,
                      KullaniciRolu.teknikPersonel,
                    ]),

                    // Site Çalışanları
                    _buildUserList(filteredKullanicilar, [
                      KullaniciRolu.peyzajPersoneli,
                      KullaniciRolu.temizlikPersoneli,
                      KullaniciRolu.guvenlikPersoneli,
                      KullaniciRolu.danismaPersoneli,
                    ]),

                    // Site Sakinleri
                    _buildUserList(filteredKullanicilar, [
                      KullaniciRolu.siteYoneticisi,
                      KullaniciRolu.siteSakini,
                      KullaniciRolu.kiraci,
                    ]),

                    // Tedarikçiler
                    _buildUserList(filteredKullanicilar, [
                      KullaniciRolu.usta,
                      KullaniciRolu.tedarikci,
                    ]),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Kullanıcılar yüklenirken hata oluştu: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(kullanicilarProvider),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(context, ref),
        tooltip: 'Yeni Kullanıcı Ekle',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUserList(
      List<KullaniciModel> kullanicilar, List<KullaniciRolu> roller) {
    // Sadece belirtilen rollerdeki kullanıcıları filtrele
    final filteredUsers =
        kullanicilar.where((user) => roller.contains(user.rol)).toList();

    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text('Bu kategoride kullanıcı bulunamadı'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(user.rol),
              child: Text(
                user.adSoyad.isNotEmpty
                    ? user.adSoyad.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user.adSoyad),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                Text(
                  _getRolGorunenAd(user.rol),
                  style: TextStyle(
                    color: _getRoleColor(user.rol),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: user.aktif,
                  onChanged: (value) {
                    _toggleUserStatus(user, value);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showUserDialog(context, ref, user),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(user),
                ),
              ],
            ),
            onTap: () => _showUserDetails(user),
          ),
        );
      },
    );
  }

  // Kullanıcı filtreleme
  List<KullaniciModel> _filterKullanicilar(List<KullaniciModel> kullanicilar) {
    if (_searchText.isEmpty && _selectedRoleFilter == null) {
      return kullanicilar;
    }

    return kullanicilar.where((user) {
      // Arama metni filtresi
      final matchesSearch = _searchText.isEmpty ||
          user.adSoyad.toLowerCase().contains(_searchText.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchText.toLowerCase()) ||
          user.telefon.contains(_searchText);

      // Rol filtresi
      final matchesRole =
          _selectedRoleFilter == null || user.rol == _selectedRoleFilter;

      return matchesSearch && matchesRole;
    }).toList();
  }

  // Rol adını al
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

  // Role göre renk döndür
  Color _getRoleColor(KullaniciRolu rol) {
    switch (rol) {
      case KullaniciRolu.sirketYoneticisi:
        return Colors.purple;
      case KullaniciRolu.siteYoneticisi:
        return Colors.blue;
      case KullaniciRolu.sahaCalisani:
        return Colors.teal;
      case KullaniciRolu.ofisCalisani:
        return Colors.indigo;
      case KullaniciRolu.teknikPersonel:
        return Colors.brown;
      case KullaniciRolu.peyzajPersoneli:
        return Colors.green;
      case KullaniciRolu.temizlikPersoneli:
        return Colors.cyan;
      case KullaniciRolu.guvenlikPersoneli:
        return Colors.red;
      case KullaniciRolu.danismaPersoneli:
        return Colors.amber;
      case KullaniciRolu.siteSakini:
        return Colors.deepOrange;
      case KullaniciRolu.kiraci:
        return Colors.pink;
      case KullaniciRolu.usta:
        return Colors.grey;
      case KullaniciRolu.tedarikci:
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  // Kullanıcı aktif/pasif durumunu değiştir
  void _toggleUserStatus(KullaniciModel user, bool active) {
    final updatedUser = user.copyWith(aktif: active);
    ref.read(kullaniciGuncelleProvider(updatedUser));
  }

  // Kullanıcı silme onayı göster
  void _showDeleteConfirmation(KullaniciModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: Text(
            '${user.adSoyad} kullanıcısını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(kullaniciSilProvider(user.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // Kullanıcı ekle/düzenle dialog'unu göster
  Future<void> _showUserDialog(BuildContext context, WidgetRef ref,
      [KullaniciModel? user]) async {
    final result = await showDialog<KullaniciModel>(
      context: context,
      builder: (context) => KullaniciEditDialog(kullanici: user),
    );

    if (result != null) {
      if (user == null) {
        // Yeni kullanıcı
        ref.read(kullaniciEkleProvider(result));
      } else {
        // Kullanıcı güncelleme
        ref.read(kullaniciGuncelleProvider(result));
      }
    }
  }

  // Kullanıcı detaylarını göster
  void _showUserDetails(KullaniciModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.adSoyad),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('E-posta'),
              subtitle: Text(user.email),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Telefon'),
              subtitle: Text(user.telefon),
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Rol'),
              subtitle: Text(_getRolGorunenAd(user.rol)),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Kayıt Tarihi'),
              subtitle: Text(
                user.kayitTarihi != null
                    ? '${user.kayitTarihi!.day}/${user.kayitTarihi!.month}/${user.kayitTarihi!.year}'
                    : 'Belirtilmemiş',
              ),
            ),
            ListTile(
              leading: Icon(
                user.aktif ? Icons.check_circle : Icons.cancel,
                color: user.aktif ? Colors.green : Colors.red,
              ),
              title: const Text('Durum'),
              subtitle: Text(user.aktif ? 'Aktif' : 'Pasif'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUserDialog(context, ref, user);
            },
            child: const Text('Düzenle'),
          ),
        ],
      ),
    );
  }
}
