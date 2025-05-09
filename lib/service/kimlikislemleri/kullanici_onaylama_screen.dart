import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/models/proje_model.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_model.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_provider.dart';
import 'package:prosmart/screens/kullaniciyonetimi/proje_assocition.dart';
import 'package:prosmart/service/kimlikislemleri/auth_provider.dart';
import 'package:prosmart/service/proje_repository.dart';

// Seçilen projeler için state provider
final selectedProjectsProvider =
    StateProvider.family<List<ProjectAssociation>, String>(
  (ref, userId) => [],
);

class ApproveUsersScreen extends ConsumerStatefulWidget {
  const ApproveUsersScreen({super.key});

  @override
  ConsumerState<ApproveUsersScreen> createState() => _ApproveUsersScreenState();
}

class _ApproveUsersScreenState extends ConsumerState<ApproveUsersScreen> {
  List<ProjeModel> _projeler = [];
  bool _projelerLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjeler();
  }

  Future<void> _loadProjeler() async {
    try {
      final projeRepository = ProjeRepository();
      final projeler = await projeRepository.getProjeler().first;

      setState(() {
        _projeler = projeler;
        _projelerLoading = false;
      });
    } catch (e) {
      setState(() {
        _projelerLoading = false;
      });
      print('Projeler yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingUsersAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Onaylama'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(pendingUsersProvider);
              _loadProjeler();
            },
            tooltip: 'Listeyi Yenile',
          ),
        ],
      ),
      body: pendingUsersAsync.when(
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
                    style: TextStyle(
                      fontSize: 16,
                    ),
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
              return _buildUserApprovalCard(context, user);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Hata: $error'),
        ),
      ),
    );
  }

  Widget _buildUserApprovalCard(BuildContext context, KullaniciModel user) {
    // Kullanıcının kayıt sırasında girdiği ek bilgileri al
    final ekBilgiler = user.ekBilgiler;
    final siteName = ekBilgiler?['siteName'] as String? ?? 'Belirtilmemiş';
    final block = ekBilgiler?['block'] as String? ?? 'Belirtilmemiş';
    final apartment = ekBilgiler?['apartment'] as String? ?? 'Belirtilmemiş';
    final roleStr = ekBilgiler?['role'] as String? ?? 'siteSakini';

    // Kullanıcının seçtiği rol
    final isOwner = roleStr == 'siteSakini';

    // Mevcut seçili projeleri al
    final selectedProjects = ref.watch(selectedProjectsProvider(user.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(user.rol),
                  radius: 24,
                  child: Text(
                    user.adSoyad.isNotEmpty
                        ? user.adSoyad.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.adSoyad,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.rol).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getRoleColor(user.rol),
                              ),
                            ),
                            child: Text(
                              isOwner ? 'Kat Maliki' : 'Kiracı',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getRoleColor(user.rol),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.orange,
                              ),
                            ),
                            child: const Text(
                              'Onay Bekliyor',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Temel site bilgileri (kayıt formundan gelenler)
            Card(
              color: Colors.grey.shade50,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kayıt Bilgileri',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Site bilgileri
                    ListTile(
                      leading: const Icon(Icons.apartment, size: 20),
                      title: const Text('Site Adı',
                          style: TextStyle(fontSize: 14)),
                      subtitle: Text(siteName),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.business, size: 20),
                            title: const Text('Blok',
                                style: TextStyle(fontSize: 14)),
                            subtitle: Text(block),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            leading:
                                const Icon(Icons.door_front_door, size: 20),
                            title: const Text('Daire No',
                                style: TextStyle(fontSize: 14)),
                            subtitle: Text(apartment),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // İletişim bilgileri
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('E-posta'),
              subtitle: Text(user.email),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Telefon'),
              subtitle: Text(user.telefon),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Kayıt Tarihi'),
              subtitle: Text(
                user.kayitTarihi != null
                    ? '${user.kayitTarihi!.day}/${user.kayitTarihi!.month}/${user.kayitTarihi!.year}'
                    : 'Belirtilmemiş',
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Proje İlişkilendirme Bölümü
            const Text(
              'Proje İlişkilendirme',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Proje ekleme butonu
            if (!_projelerLoading)
              ElevatedButton.icon(
                onPressed: () => _showAddProjectDialog(context, user),
                icon: const Icon(Icons.add),
                label: const Text('Proje Ekle'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 16),

            // Seçili projeler listesi
            if (selectedProjects.isNotEmpty) ...[
              const Text(
                'Seçilen Projeler',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              // Seçili projeleri göster
              ...selectedProjects.map((project) {
                final projectModel = _findProjeById(project.projectId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                projectModel?.unvan ?? 'Proje Bulunamadı',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Proje rol bilgisi
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: project.role == 'siteSakini'
                                          ? Colors.deepOrange.withOpacity(0.1)
                                          : Colors.pink.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      project.role == 'siteSakini'
                                          ? 'Kat Maliki'
                                          : 'Kiracı',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: project.role == 'siteSakini'
                                            ? Colors.deepOrange
                                            : Colors.pink,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Özel erişim rozeti (varsa)
                                  if (project.hasSpecialAccess)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Özel Erişim',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              // Blok ve daire bilgisi
                              if (project.additionalInfo != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Blok: ${project.additionalInfo!['block'] ?? '-'}, Daire: ${project.additionalInfo!['apartment'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Düzenleme ve silme butonları
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () =>
                              _showEditProjectDialog(context, user, project),
                          tooltip: 'Düzenle',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 18),
                          onPressed: () =>
                              _removeProjectFromUser(user.id, project),
                          tooltip: 'Kaldır',
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else ...[
              // Proje seçilmemiş
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kullanıcıyı onaylamak için en az bir proje eklemelisiniz.',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Onay işlemleri
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reddet butonu
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Reddet'),
                  onPressed: () => _showRejectConfirmationDialog(context, user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),

                // Onayla butonu
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Onayla'),
                  onPressed: selectedProjects.isEmpty
                      ? null
                      : () => _showApproveConfirmationDialog(context, user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Proje ekleme dialog'u
  Future<void> _showAddProjectDialog(
      BuildContext context, KullaniciModel user) async {
    if (_projeler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eklenecek proje bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ProjeModel? selectedProject = _projeler.first;
    String role = 'siteSakini'; // Varsayılan rol
    bool hasSpecialAccess = false;
    String block = user.ekBilgiler?['block'] ?? '';
    String apartment = user.ekBilgiler?['apartment'] ?? '';

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Proje Ekle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Proje seçimi
                DropdownButtonFormField<ProjeModel>(
                  decoration: const InputDecoration(
                    labelText: 'Proje',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedProject,
                  items: _projeler.map((project) {
                    return DropdownMenuItem<ProjeModel>(
                      value: project,
                      child: Text(project.unvan),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProject = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Rol seçimi
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Kat Maliki'),
                        value: 'siteSakini',
                        groupValue: role,
                        onChanged: (value) {
                          setState(() {
                            role = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Kiracı'),
                        value: 'kiraci',
                        groupValue: role,
                        onChanged: (value) {
                          setState(() {
                            role = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),

                // Özel erişim
                SwitchListTile(
                  title: const Text('Özel Erişim'),
                  subtitle: const Text('Site yönetimi yetkisi'),
                  value: hasSpecialAccess,
                  onChanged: (value) {
                    setState(() {
                      hasSpecialAccess = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Blok ve daire bilgileri
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: block,
                        decoration: const InputDecoration(
                          labelText: 'Blok',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            block = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: apartment,
                        decoration: const InputDecoration(
                          labelText: 'Daire',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            apartment = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedProject == null) return;

                  // Yeni proje ilişkisi oluştur
                  final projectAssociation = ProjectAssociation(
                    projectId: selectedProject!.id,
                    role: role,
                    hasSpecialAccess: hasSpecialAccess,
                    additionalInfo: {
                      'block': block,
                      'apartment': apartment,
                    },
                  );

                  // Mevcut ilişkiler listesine ekle
                  final currentAssociations =
                      ref.read(selectedProjectsProvider(user.id));

                  // Aynı proje zaten eklenmiş mi kontrol et
                  final isDuplicate = currentAssociations
                      .any((p) => p.projectId == selectedProject!.id);

                  if (isDuplicate) {
                    // Hata mesajı göster
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bu proje zaten eklenmiş'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Listeyi güncelle
                  ref.read(selectedProjectsProvider(user.id).notifier).state = [
                    ...currentAssociations,
                    projectAssociation,
                  ];

                  Navigator.pop(context);
                },
                child: const Text('Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Proje düzenleme dialog'u
  Future<void> _showEditProjectDialog(BuildContext context, KullaniciModel user,
      ProjectAssociation project) async {
    final projectModel = _findProjeById(project.projectId);
    if (projectModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proje bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String role = project.role;
    bool hasSpecialAccess = project.hasSpecialAccess;
    String block = project.additionalInfo?['block'] ?? '';
    String apartment = project.additionalInfo?['apartment'] ?? '';

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Proje Düzenle: ${projectModel.unvan}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Kat Maliki'),
                        value: 'siteSakini',
                        groupValue: role,
                        onChanged: (value) {
                          setState(() {
                            role = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Kiracı'),
                        value: 'kiraci',
                        groupValue: role,
                        onChanged: (value) {
                          setState(() {
                            role = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),

                // Özel erişim switch'i
                SwitchListTile(
                  title: const Text('Özel Erişim'),
                  subtitle: const Text('Site yönetimi yetkisi'),
                  value: hasSpecialAccess,
                  onChanged: (value) {
                    setState(() {
                      hasSpecialAccess = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Blok ve daire bilgileri
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: block,
                        decoration: const InputDecoration(
                          labelText: 'Blok',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            block = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: apartment,
                        decoration: const InputDecoration(
                          labelText: 'Daire',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            apartment = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Güncellenmiş proje ilişkisi oluştur
                  final updatedProject = ProjectAssociation(
                    projectId: project.projectId,
                    role: role,
                    hasSpecialAccess: hasSpecialAccess,
                    additionalInfo: {
                      'block': block,
                      'apartment': apartment,
                    },
                  );

                  // Mevcut ilişkiler listesinden eskisini kaldır, yenisini ekle
                  final currentAssociations =
                      ref.read(selectedProjectsProvider(user.id));
                  final updatedAssociations = currentAssociations.map((p) {
                    if (p.projectId == project.projectId) {
                      return updatedProject;
                    }
                    return p;
                  }).toList();

                  // Listeyi güncelle
                  ref.read(selectedProjectsProvider(user.id).notifier).state =
                      updatedAssociations;

                  Navigator.pop(context);
                },
                child: const Text('Güncelle'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Kullanıcıdan proje kaldır
  void _removeProjectFromUser(String userId, ProjectAssociation project) {
    // Onay sor
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Projeyi Kaldır'),
        content: const Text(
            'Bu projeyi kullanıcıdan kaldırmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Mevcut ilişkiler listesinden kaldır
              final currentAssociations =
                  ref.read(selectedProjectsProvider(userId));
              final updatedAssociations = currentAssociations
                  .where((p) => p.projectId != project.projectId)
                  .toList();

              // Listeyi güncelle
              ref.read(selectedProjectsProvider(userId).notifier).state =
                  updatedAssociations;

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
  }

  // ID'ye göre proje bul
  ProjeModel? _findProjeById(String projectId) {
    for (var proje in _projeler) {
      if (proje.id == projectId) {
        return proje;
      }
    }
    return null;
  }

  // Onaylama onay dialog'u
  void _showApproveConfirmationDialog(
      BuildContext context, KullaniciModel user) {
    final selectedProjects = ref.read(selectedProjectsProvider(user.id));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Onayla'),
        content: Column(
            // ... (diğer kısımlar aynı kalacak)
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // 1. Kullanıcıyı aktifleştir ve onayla
              final userApproveResult =
                  await ref.read(approveUserProvider(user.id).future);

              if (userApproveResult) {
                // 2. Kullanıcıyı projelerle ilişkilendir
                // Burada kullanıcı modelini güncelle (projectAssociations alanı)
                final updatedUser = user.copyWith(
                  projectAssociations:
                      selectedProjects, // siteIds yerine projectAssociations
                );

                final userUpdateResult = await ref
                    .read(kullaniciGuncelleProvider(updatedUser).future);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${user.adSoyad} onaylandı ve ${selectedProjects.length} projeyle ilişkilendirildi'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Listeyi yenile
                  ref.invalidate(pendingUsersProvider);
                }
              } else {
                if (context.mounted) {
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
      BuildContext context, KullaniciModel user) {
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
}
