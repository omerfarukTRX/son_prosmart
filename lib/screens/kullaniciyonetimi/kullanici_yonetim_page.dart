import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_dashboard.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_edit_dialog.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_model.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_provider.dart';
import 'package:prosmart/widgets/stat_card.dart';
import 'package:prosmart/models/proje_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prosmart/service/kimlikislemleri/auth_provider.dart';
import 'package:prosmart/service/proje_repository.dart';

// Proje listesi provider
final projeListProvider = StreamProvider<List<ProjeModel>>((ref) {
  final projeRepository = ProjeRepository();
  return projeRepository.getProjeler();
});

// Kullanıcı-site ilişkilendirme provider
final kullaniciSiteIliskiProvider =
    StateProvider.family<List<String>, String>((ref, kullaniciId) {
  return [];
});
final projectDropdownOpenProvider =
    StateProvider.family<bool, String>((ref, userId) => false);
final userCardExpandedProvider =
    StateProvider.family<bool, String>((ref, userId) => false);
final userRoleSelectionProvider =
    StateProvider.family<KullaniciRolu?, String>((ref, userId) => null);

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

  @override
  void initState() {
    super.initState();
    // 6 sekme: İstatistikler, Onay Bekleyenler ve 4 kullanıcı kategorisi
    _tabController = TabController(length: 6, vsync: this);
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
            Tab(text: 'İstatistikler'),
            Tab(text: 'Onay Bekleyenler'),
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
              ref.invalidate(pendingUsersProvider);
            },
            tooltip: 'Listeyi Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama alanı
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kullanıcı ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
            ),
          ),

          // Tab içerikleri
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // İstatistikler Sekmesi
                const KullaniciDashboard(),

                // Onay Bekleyen Kullanıcılar
                const EnhancedApproveUsersScreen(),

                // Prosit Çalışanları
                _buildUserListTab(kullanicilarAsyncValue, [
                  KullaniciRolu.sirketYoneticisi,
                  KullaniciRolu.sahaCalisani,
                  KullaniciRolu.ofisCalisani,
                  KullaniciRolu.teknikPersonel,
                ]),

                // Site Çalışanları
                _buildUserListTab(kullanicilarAsyncValue, [
                  KullaniciRolu.peyzajPersoneli,
                  KullaniciRolu.temizlikPersoneli,
                  KullaniciRolu.guvenlikPersoneli,
                  KullaniciRolu.danismaPersoneli,
                ]),

                // Site Sakinleri
                _buildUserListTab(kullanicilarAsyncValue, [
                  KullaniciRolu.siteYoneticisi,
                  KullaniciRolu.siteSakini,
                  KullaniciRolu.kiraci,
                ]),

                // Tedarikçiler
                _buildUserListTab(kullanicilarAsyncValue, [
                  KullaniciRolu.usta,
                  KullaniciRolu.tedarikci,
                ]),
              ],
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

  // Kullanıcı listesi sekmesi oluşturma
  Widget _buildUserListTab(
      AsyncValue<List<KullaniciModel>> kullanicilarAsyncValue,
      List<KullaniciRolu> roller) {
    return kullanicilarAsyncValue.when(
      data: (kullanicilar) {
        final filteredKullanicilar = _filterKullanicilar(kullanicilar);
        return _buildUserList(filteredKullanicilar, roller);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
    );
  }

  // Kullanıcı filtreleme (sadece arama metni ile filtreleme yapılıyor)
  List<KullaniciModel> _filterKullanicilar(List<KullaniciModel> kullanicilar) {
    if (_searchText.isEmpty) {
      return kullanicilar;
    }

    return kullanicilar.where((user) {
      // Arama metni filtresi
      final searchLower = _searchText.toLowerCase();
      return user.adSoyad.toLowerCase().contains(searchLower) ||
          user.email.toLowerCase().contains(searchLower) ||
          user.telefon.contains(_searchText);
    }).toList();
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

// Gelişmiş Kullanıcı Onay Ekranı
class EnhancedApproveUsersScreen extends ConsumerWidget {
  const EnhancedApproveUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingUsersAsync = ref.watch(pendingUsersProvider);

    return pendingUsersAsync.when(
      data: (pendingUsers) {
        if (pendingUsers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green,
                ),
                SizedBox(height: 16),
                Text(
                  'Onay bekleyen kullanıcı bulunmamaktadır',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingUsers.length,
          itemBuilder: (context, index) {
            final user = pendingUsers[index];
            return _buildCompactUserApprovalCard(context, ref, user);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Hata: $error'),
      ),
    );
  }

  Widget _buildCompactUserApprovalCard(
      BuildContext context, WidgetRef ref, KullaniciModel user) {
    // Kullanıcının kayıt bilgilerinden site bilgilerini çıkar
    final ekBilgiler = user.ekBilgiler ?? {};
    final siteName = ekBilgiler['siteName'] as String? ?? 'Belirtilmemiş';
    final apartment = ekBilgiler['apartment'] as String? ?? 'Belirtilmemiş';
    final blok = ekBilgiler['blok'] as String? ?? 'Belirtilmemiş';

    final expandedState = ref.watch(userCardExpandedProvider(user.id));
    final seciliSiteler = ref.watch(kullaniciSiteIliskiProvider(user.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1, // Minimal tasarım için düşük elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık kısmı - her zaman görünür
            InkWell(
              onTap: () {
                ref.read(userCardExpandedProvider(user.id).notifier).state =
                    !expandedState;
              },
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: _getRoleColor(user.rol),
                    radius: 20,
                    child: Text(
                      user.adSoyad.isNotEmpty
                          ? user.adSoyad.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Kullanıcı adı ve site bilgisi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.adSoyad,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Site: $siteName',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Açma/kapama ikonu
                  Icon(
                    expandedState
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),

            // Detaylar - açılır kapanır
            if (expandedState) ...[
              const Divider(height: 16),

              // Detay bilgileri
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İletişim bilgileri
                    _buildDetailRow(Icons.email, 'E-posta', user.email),
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.phone, 'Telefon', user.telefon),
                    const SizedBox(height: 4),
                    _buildDetailRow(
                        Icons.calendar_today,
                        'Kayıt Tarihi',
                        user.kayitTarihi != null
                            ? '${user.kayitTarihi!.day}/${user.kayitTarihi!.month}/${user.kayitTarihi!.year}'
                            : 'Belirtilmemiş'),
                    const SizedBox(height: 4),

                    // Site bilgileri
                    _buildDetailRow(Icons.business, 'Site', siteName),
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.domain, 'Blok', blok),
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.home, 'Daire', apartment),

                    // ekBilgiler içindeki diğer tüm anahtarları göster
                    ...ekBilgiler.entries
                        .where((entry) => !['siteName', 'apartment', 'blok']
                            .contains(entry.key))
                        .map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildDetailRow(
                          Icons.info_outline,
                          entry.key,
                          entry.value.toString(),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Rol seçimi
                    _buildRoleSelection(context, ref, user),

                    const SizedBox(height: 16),

                    // Proje seçimi
                    _buildProjectSelection(context, ref, user),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // İşlem butonları
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Reddet butonu
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Reddet'),
                    onPressed: () =>
                        _showRejectConfirmationDialog(context, ref, user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Onayla butonu
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Onayla'),
                    onPressed: () {
                      final seciliSiteler =
                          ref.read(kullaniciSiteIliskiProvider(user.id));
                      if (seciliSiteler.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lütfen en az bir proje seçin'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final selectedRole =
                          ref.read(userRoleSelectionProvider(user.id));
                      if (selectedRole == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lütfen bir rol seçin'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      _showApproveConfirmationDialog(
                          context, ref, user, seciliSiteler, selectedRole);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Detay satırı (ikon + başlık + değer)
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            '$title:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Rol seçimi
  Widget _buildRoleSelection(
      BuildContext context, WidgetRef ref, KullaniciModel user) {
    final selectedRole = ref.watch(userRoleSelectionProvider(user.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kullanıcı Rolü:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),

        // Sadece Kat Maliki veya Kiracı rolleri
        Row(
          children: [
            Expanded(
              child: _buildRoleSelectionChip(
                  context,
                  ref,
                  user,
                  KullaniciRolu.siteSakini,
                  selectedRole == KullaniciRolu.siteSakini),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleSelectionChip(context, ref, user,
                  KullaniciRolu.kiraci, selectedRole == KullaniciRolu.kiraci),
            ),
          ],
        ),
      ],
    );
  }

  // Rol seçimi chip'i
  Widget _buildRoleSelectionChip(BuildContext context, WidgetRef ref,
      KullaniciModel user, KullaniciRolu rol, bool isSelected) {
    return GestureDetector(
      onTap: () {
        ref.read(userRoleSelectionProvider(user.id).notifier).state = rol;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _getRoleColor(rol).withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _getRoleColor(rol) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: _getRoleColor(rol),
                size: 16,
              ),
            if (isSelected) const SizedBox(width: 4),
            Text(
              _getRoleName(rol),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _getRoleColor(rol) : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Proje seçim alanı
  Widget _buildProjectSelection(
      BuildContext context, WidgetRef ref, KullaniciModel user) {
    final projeListAsync = ref.watch(projeListProvider);
    final seciliSiteler = ref.watch(kullaniciSiteIliskiProvider(user.id));
    final dropdownOpen = ref.watch(projectDropdownOpenProvider(user.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Projeler:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),

        // Dropdown trigger
        InkWell(
          onTap: () {
            ref.read(projectDropdownOpenProvider(user.id).notifier).state =
                !dropdownOpen;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  seciliSiteler.isEmpty
                      ? 'Projeleri seçin'
                      : '${seciliSiteler.length} proje seçildi',
                  style: TextStyle(
                    color: seciliSiteler.isEmpty
                        ? Colors.grey.shade600
                        : Colors.black,
                  ),
                ),
                const Spacer(),
                Icon(
                  dropdownOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),

        // Dropdown içeriği (açıksa göster)
        if (dropdownOpen)
          projeListAsync.when(
            data: (projeler) {
              return Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: projeler.length,
                  itemBuilder: (context, index) {
                    final proje = projeler[index];
                    if (!proje.isActive) return const SizedBox.shrink();

                    final isSelected = seciliSiteler.contains(proje.id);
                    return CheckboxListTile(
                      title: Text(
                        proje.unvan,
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: isSelected,
                      onChanged: (selected) {
                        final newList = List<String>.from(seciliSiteler);
                        if (selected == true) {
                          newList.add(proje.id);
                        } else {
                          newList.remove(proje.id);
                        }
                        ref
                            .read(kullaniciSiteIliskiProvider(user.id).notifier)
                            .state = newList;
                      },
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Proje listesi yüklenemedi',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ),

        // Seçili projeler
        if (seciliSiteler.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: projeListAsync.when(
                data: (projeler) {
                  return seciliSiteler.map((siteId) {
                    // Proje bilgisini bul
                    final proje = projeler.firstWhere(
                      (p) => p.id == siteId,
                      orElse: () => ProjeModel(
                        id: siteId,
                        unvan: 'Bilinmeyen Proje',
                        adres: '',
                        tip: ProjeTipi.site,
                        konum: const GeoPoint(0, 0),
                        blokSayisi: 0,
                        bagimsizBolumSayisi: 0,
                        ibanNo: '',
                        vergiNo: '',
                        olusturulmaTarihi: Timestamp.now(),
                      ),
                    );

                    return Chip(
                      label: Text(
                        proje.unvan,
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        final newList = List<String>.from(seciliSiteler);
                        newList.remove(siteId);
                        ref
                            .read(kullaniciSiteIliskiProvider(user.id).notifier)
                            .state = newList;
                      },
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      deleteIconColor: Colors.grey.shade700,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(4),
                    );
                  }).toList();
                },
                loading: () =>
                    [const CircularProgressIndicator(strokeWidth: 2)],
                error: (_, __) => [
                  Chip(
                    label: const Text('Proje bilgisi yüklenemedi'),
                    backgroundColor: Colors.red.shade100,
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Onaylama onay dialog'u
  void _showApproveConfirmationDialog(BuildContext context, WidgetRef ref,
      KullaniciModel user, List<String> siteIds, KullaniciRolu selectedRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Onayla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${user.adSoyad} kullanıcısına onay vermek istediğinize emin misiniz?'),
            const SizedBox(height: 16),

            // Seçilen rol
            Row(
              children: [
                Text(
                  'Seçilen Rol:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(selectedRole).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getRoleColor(selectedRole)),
                  ),
                  child: Text(
                    _getRoleName(selectedRole),
                    style: TextStyle(
                      fontSize: 13,
                      color: _getRoleColor(selectedRole),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'Seçilen Projeler:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...ref.read(projeListProvider).when(
                  data: (projeler) {
                    return siteIds.map((siteId) {
                      final proje = projeler.firstWhere(
                        (p) => p.id == siteId,
                        orElse: () => ProjeModel(
                          id: siteId,
                          unvan: 'Bilinmeyen Proje',
                          adres: '',
                          tip: ProjeTipi.site,
                          konum: const GeoPoint(0, 0),
                          blokSayisi: 0,
                          bagimsizBolumSayisi: 0,
                          ibanNo: '',
                          vergiNo: '',
                          olusturulmaTarihi: Timestamp.now(),
                        ),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(proje.unvan)),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  loading: () => [const CircularProgressIndicator()],
                  error: (_, __) => [const Text('Proje bilgileri yüklenemedi')],
                ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Kullanıcıyı güncelle - rol ve site ID'leri
              final updatedUser = user.copyWith(
                rol: selectedRole,
                siteIds: siteIds, // Artık ekBilgiler içinde değil
              );

              await ref.read(kullaniciGuncelleProvider(updatedUser).future);

              // Kullanıcı onaylama
              final result =
                  await ref.read(approveUserProvider(user.id).future);

              if (context.mounted) {
                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${user.adSoyad} onaylandı ve projeler ile ilişkilendirildi'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Listeyi yenile
                  ref.invalidate(pendingUsersProvider);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('${user.adSoyad} onaylanırken bir hata oluştu'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  // Reddetme onay dialog'u
  void _showRejectConfirmationDialog(
      BuildContext context, WidgetRef ref, KullaniciModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Reddet'),
        content: Text(
            '${user.adSoyad} kullanıcısını reddetmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Kullanıcı reddetme
              final result = await ref.read(rejectUserProvider(user.id).future);

              if (context.mounted) {
                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.adSoyad} reddedildi'),
                      backgroundColor: Colors.orange,
                    ),
                  );

                  // Listeyi yenile
                  ref.invalidate(pendingUsersProvider);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('${user.adSoyad} reddedilirken bir hata oluştu'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }

  // Rol rengi getir
  Color _getRoleColor(KullaniciRolu rol) {
    switch (rol) {
      case KullaniciRolu.siteSakini:
        return Colors.deepOrange;
      case KullaniciRolu.kiraci:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  // Rol adını getir
  String _getRoleName(KullaniciRolu rol) {
    switch (rol) {
      case KullaniciRolu.siteSakini:
        return 'Kat Maliki';
      case KullaniciRolu.kiraci:
        return 'Kiracı';
      default:
        return 'Bilinmeyen Rol';
    }
  }
}
