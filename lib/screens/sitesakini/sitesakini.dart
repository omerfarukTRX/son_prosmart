import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prosmart/screens/kullaniciyonetimi/proje_assocition.dart';
import 'package:prosmart/screens/main_container.dart';
import 'package:prosmart/screens/sitesakini/bakim_talep.dart';
import 'package:prosmart/screens/sitesakini/bilgi.dart';
import 'package:prosmart/screens/sitesakini/duyurular.dart';
import 'package:prosmart/screens/sitesakini/faaliyetler.dart';
import 'package:prosmart/screens/sitesakini/iletisim.dart';
import 'package:prosmart/screens/sitesakini/kapi_otomasyonu.dart';
import 'package:prosmart/screens/sitesakini/prosmart_bilgi.dart';
import 'package:prosmart/screens/sitesakini/taleplerim.dart';
import 'package:prosmart/service/kimlikislemleri/auth_provider.dart';
import 'package:intl/intl.dart';

final selectedProjectDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, projectId) async {
  if (projectId.isEmpty) {
    return null;
  }

  try {
    final projectDoc = await FirebaseFirestore.instance
        .collection('projeler')
        .doc(projectId)
        .get();

    if (projectDoc.exists) {
      return {
        'id': projectDoc.id,
        'data': projectDoc.data() as Map<String, dynamic>,
      };
    }
  } catch (e) {
    print('Proje detayları alınamadı: $e');
  }

  return null;
});

// Seçili proje provider
final selectedUserProjectProvider = StateProvider<String?>((ref) => null);

// Proje adı provider
final projectNamesProvider =
    FutureProvider.family<String, String>((ref, projectId) async {
  try {
    if (projectId.isEmpty) {
      return 'Proje Bulunamadı';
    }

    final doc = await FirebaseFirestore.instance
        .collection('projeler')
        .doc(projectId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['unvan'] ?? 'Proje Bulunamadı';
    }

    return 'Proje Bulunamadı';
  } catch (e) {
    print('Proje adı getirme hatası: $e');
    return 'Hata';
  }
});

class SiteSakiniKiraciDashboard extends ConsumerStatefulWidget {
  const SiteSakiniKiraciDashboard({super.key});

  @override
  ConsumerState<SiteSakiniKiraciDashboard> createState() =>
      _SiteSakiniKiraciDashboardState();
}

class _SiteSakiniKiraciDashboardState
    extends ConsumerState<SiteSakiniKiraciDashboard> {
  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B1E), // Koyu arka plan
      body: authStateAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'Kullanıcı bilgisi alınamadı',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                // Üst header bölümü
                _buildModernHeader(user.uid),

                // İçerik bölümü
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Bakım ilanları slider - ŞU AN DEVRE DIŞI
                          _buildModernMaintenanceSlider(),
                          const SizedBox(height: 24),

                          // Menü başlığı
                          const Text(
                            'Hızlı Erişim',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Modern menü grid
                          _buildModernMenuGrid(context),
                          const SizedBox(height: 16),

                          // ProSmart butonu
                          _buildModernProSmartButton(context),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Hata: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(String userId) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5E3AFF), // Mor
            Color(0xFF2196F3), // Mavi
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('kullanicilar')
              .doc(userId)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const SizedBox(height: 200);
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final userRole = userData['rol'] as String? ?? '';
            final isKatMaliki = userRole == 'siteSakini';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kullanıcı bilgileri satırı
                Row(
                  children: [
                    // Profil avatarı
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (userData['adSoyad'] ?? 'K')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5E3AFF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Ad ve rol bilgisi
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['adSoyad'] ?? 'Kullanıcı',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isKatMaliki ? 'Kat Maliki' : 'Kiracı',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sağ üst butonlar
                    Row(
                      children: [
                        _buildHeaderIconButton(
                          Icons.notifications_outlined,
                          onTap: () {
                            // Bildirimler sayfasına git
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildHeaderIconButton(
                          Icons.settings_outlined,
                          onTap: () {
                            // Ayarlar sayfasına git
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Proje seçimi
                _buildModernProjectSelector(userId),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, {required VoidCallback onTap}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildModernProjectSelector(String userId) {
    final selectedProjectId = ref.watch(selectedUserProjectProvider);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Firestore Error: ${snapshot.error}");
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Text('Bağlantı hatası',
                style: TextStyle(color: Colors.white)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox(height: 50);
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final projectAssociationsData =
            userData['projectAssociations'] as List<dynamic>?;

        if (projectAssociationsData == null ||
            projectAssociationsData.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Henüz bir projeye dahil değilsiniz',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }

        // ProjectAssociation listesine dönüştür
        List<ProjectAssociation> projectAssociations = [];
        for (var data in projectAssociationsData) {
          if (data is Map<String, dynamic>) {
            projectAssociations.add(ProjectAssociation.fromMap(data));
          }
        }

        // İlk açılışta ilk projeyi seç - Race condition önleme
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (selectedProjectId == null && projectAssociations.isNotEmpty) {
            final firstProjectId = projectAssociations.first.projectId;
            ref.read(selectedUserProjectProvider.notifier).state =
                firstProjectId;
          }
        });

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: const Color(0xFF5E3AFF),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedProjectId,
                dropdownColor: const Color(0xFF5E3AFF),
                icon:
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: projectAssociations.map((association) {
                  return DropdownMenuItem<String>(
                    value: association.projectId,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final projectNameAsync = ref
                            .watch(projectNamesProvider(association.projectId));

                        return projectNameAsync.when(
                          data: (projectName) {
                            final block = association.additionalInfo?['block']
                                    ?.toString() ??
                                '';
                            final apartment = association
                                    .additionalInfo?['apartment']
                                    ?.toString() ??
                                '';

                            return Row(
                              children: [
                                Icon(Icons.apartment,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        projectName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (block.isNotEmpty &&
                                          apartment.isNotEmpty)
                                        Text(
                                          'Blok $block - Daire $apartment',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const Row(
                            children: [
                              Icon(Icons.apartment,
                                  color: Colors.white70, size: 20),
                              SizedBox(width: 12),
                              Text('Yükleniyor...',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                          error: (e, s) => const Row(
                            children: [
                              Icon(Icons.error,
                                  color: Colors.white70, size: 20),
                              SizedBox(width: 12),
                              Text('Hata',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(selectedUserProjectProvider.notifier).state =
                        value;
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernMaintenanceSlider() {
    // ŞU AN DEVRE DIŞI - Placeholder olarak statik içerik gösterelim
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1F3A),
            Color(0xFF2A2B4A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E3AFF).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Bakım ilanları yakında aktif olacak',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMenuGrid(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.door_sliding,
        'title': 'Kapı\nOtomasyonu',
        'color': const Color(0xFF5E3AFF),
        'page': const KapiOtomasyonuPage(),
      },
      {
        'icon': Icons.task_alt,
        'title': 'Taleplerim',
        'color': const Color(0xFF2196F3),
        'page': const TaleplerimPage(),
      },
      {
        'icon': Icons.campaign,
        'title': 'Duyurular',
        'color': const Color(0xFF9C27B0),
        'page': const DuyurularPage(),
      },
      {
        'icon': Icons.event,
        'title': 'Faaliyetler',
        'color': const Color(0xFF4CAF50),
        'page': const FaaliyetlerPage(),
      },
      {
        'icon': Icons.contacts,
        'title': 'İletişim',
        'color': const Color(0xFFFF5722),
        'page': const IletisimPage(),
      },
      {
        'icon': Icons.info,
        'title': 'Bilgi',
        'color': const Color(0xFF00BCD4),
        'page': const BilgiPage(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildModernMenuButton(
          context: context,
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          color: item['color'] as Color,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item['page'] as Widget),
            );
          },
        );
      },
    );
  }

  Widget _buildModernMenuButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1F3A),
            Color(0xFF2A2B4A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernProSmartButton(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5E3AFF),
            Color(0xFF2196F3),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E3AFF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProsmartPage()),
            );
          },
          borderRadius: BorderRadius.circular(15),
          child: const Center(
            child: Text(
              'ProSmart Platform',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> getSelectedProjectInfo(WidgetRef ref) async {
    try {
      final userId = ref.watch(authStateProvider).value?.uid;
      final selectedProjectId = ref.watch(selectedUserProjectProvider);

      if (userId == null ||
          selectedProjectId == null ||
          selectedProjectId.isEmpty) {
        return null;
      }

      // Kullanıcı verilerini al
      final userDoc = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data();
      if (userData == null) {
        return null;
      }

      final projectAssociationsData =
          userData['projectAssociations'] as List<dynamic>?;

      if (projectAssociationsData == null) {
        return null;
      }

      // ProjectAssociation listesine dönüştür
      final projectAssociations = projectAssociationsData
          .map((data) =>
              ProjectAssociation.fromMap(data as Map<String, dynamic>))
          .toList();

      // Seçili projeye ait association'ı bul
      final selectedAssociation = projectAssociations.firstWhere(
        (association) => association.projectId == selectedProjectId,
        orElse: () => throw Exception('Seçili proje bulunamadı'),
      );

      // Proje detaylarını al
      final projectDoc = await FirebaseFirestore.instance
          .collection('projeler')
          .doc(selectedProjectId)
          .get();

      if (!projectDoc.exists) {
        return null;
      }

      final projectData = projectDoc.data();
      if (projectData == null) {
        return null;
      }

      return {
        'projectId': selectedProjectId,
        'projectName': projectData['unvan'],
        'block': selectedAssociation.additionalInfo?['block'] ?? '',
        'apartment': selectedAssociation.additionalInfo?['apartment'] ?? '',
        'role': selectedAssociation.role,
        'hasSpecialAccess': selectedAssociation.hasSpecialAccess,
        'projectData': projectData,
      };
    } catch (e) {
      print('getSelectedProjectInfo hatası: $e');
      return null;
    }
  }
}
