import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/models/proje_model.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_model.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_provider.dart';
import 'package:prosmart/service/kimlikislemleri/auth_provider.dart';
import 'package:prosmart/service/proje_repository.dart';

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

    // Projeyi seçmek için kullanılacak değişken
    String? selectedProjectId;

    // İlgili projeyi bul
    ProjeModel? matchingProject;
    if (!_projelerLoading && _projeler.isNotEmpty) {
      // Site adına göre projelerde ara
      for (var proje in _projeler) {
        if (proje.unvan.toLowerCase() == siteName.toLowerCase()) {
          matchingProject = proje;
          break;
        }
      }

      // Eşleşen proje yoksa (isteğe bağlı) ilk projeyi seç
      matchingProject ??= _projeler.first;

      // Eşleşen proje bulunduysa ID'sini al
      selectedProjectId = matchingProject.id;
    }

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

            // Site bilgileri
            ListTile(
              leading: const Icon(Icons.apartment),
              title: const Text('Site Adı'),
              subtitle: Text(siteName),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.business),
                    title: const Text('Blok'),
                    subtitle: Text(block),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.door_front_door),
                    title: const Text('Daire No'),
                    subtitle: Text(apartment),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),

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

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // Proje seçimi
            if (_projelerLoading)
              const Center(child: CircularProgressIndicator())
            else
              StatefulBuilder(
                builder: (context, setDropdownState) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Proje Seçin',
                      border: OutlineInputBorder(),
                      helperText:
                          'Kullanıcıyı ilişkilendirmek için proje seçin',
                    ),
                    value: selectedProjectId,
                    items: _projeler.map((project) {
                      return DropdownMenuItem<String>(
                        value: project.id,
                        child: Text(project.unvan),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDropdownState(() {
                        selectedProjectId = value;
                      });
                    },
                  );
                },
              ),

            const SizedBox(height: 16),

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
                  onPressed: selectedProjectId == null
                      ? null
                      : () => _showApproveConfirmationDialog(
                            context,
                            user,
                            selectedProjectId!,
                            block,
                            apartment,
                            isOwner ? 'siteSakini' : 'kiraci',
                          ),
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

  // Onaylama onay dialog'u
  void _showApproveConfirmationDialog(
    BuildContext context,
    KullaniciModel user,
    String projectId,
    String block,
    String apartment,
    String roleType,
  ) {
    // Seçilen projeyi bul
    ProjeModel? selectedProject;
    for (var proje in _projeler) {
      if (proje.id == projectId) {
        selectedProject = proje;
        break;
      }
    }

    if (selectedProject == null && _projeler.isNotEmpty) {
      selectedProject = _projeler.first;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Onayla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${user.adSoyad} kullanıcısını aşağıdaki proje ile ilişkilendirerek onaylamak istediğinize emin misiniz?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Proje: ${selectedProject?.unvan ?? "Seçilmedi"}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Blok: $block'),
                  Text('Daire: $apartment'),
                  Text(
                      'Rol: ${roleType == 'siteSakini' ? 'Kat Maliki' : 'Kiracı'}'),
                ],
              ),
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

              // 1. Kullanıcıyı aktifleştir ve onayla
              final userApproveResult =
                  await ref.read(approveUserProvider(user.id).future);

              // 2. Kullanıcıyı proje ile ilişkilendir
              if (userApproveResult && selectedProject != null) {
                final associationParams = {
                  'userId': user.id,
                  'projectId': selectedProject.id,
                  'type': roleType,
                  'block': block,
                  'apartment': apartment,
                };

                final projectAssociationResult = await ref.read(
                    userProjectAssociationProvider(associationParams).future);

                if (context.mounted) {
                  if (projectAssociationResult) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${user.adSoyad} onaylandı ve ${selectedProject.unvan ?? "seçilen proje"} projesiyle ilişkilendirildi'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Listeyi yenile
                    ref.invalidate(pendingUsersProvider);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${user.adSoyad} onaylandı fakat proje ilişkilendirme başarısız oldu'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
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
