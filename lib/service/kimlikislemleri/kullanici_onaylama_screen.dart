import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_model.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_provider.dart';
import 'package:prosmart/service/kimlikislemleri/auth_provider.dart';

class ApproveUsersScreen extends ConsumerWidget {
  const ApproveUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingUsersAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Onaylama'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(pendingUsersProvider);
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
              return _buildUserApprovalCard(context, ref, user);
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

  Widget _buildUserApprovalCard(
      BuildContext context, WidgetRef ref, KullaniciModel user) {
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
                              _getRoleName(user.rol),
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

            // Onay işlemleri
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Rol Güncelle
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Rol Güncelle'),
                  onPressed: () => _showUpdateRoleDialog(context, ref, user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                // Reddet butonu
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Reddet'),
                  onPressed: () =>
                      _showRejectConfirmationDialog(context, ref, user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),

                // Onayla butonu
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Onayla'),
                  onPressed: () =>
                      _showApproveConfirmationDialog(context, ref, user),
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

  // Rol güncelleme dialog'u
  void _showUpdateRoleDialog(
      BuildContext context, WidgetRef ref, KullaniciModel user) {
    KullaniciRolu selectedRole = user.rol;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Rol Güncelle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${user.adSoyad} için yeni rol seçin:'),
                const SizedBox(height: 16),
                DropdownButtonFormField<KullaniciRolu>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Rolü',
                    border: OutlineInputBorder(),
                  ),
                  items: KullaniciRolu.values.map((role) {
                    return DropdownMenuItem<KullaniciRolu>(
                      value: role,
                      child: Text(_getRoleName(role)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedRole = value;
                      });
                    }
                  },
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
                  Navigator.pop(context);

                  // Rol güncelleme işlemi
                  final updatedUser = user.copyWith(rol: selectedRole);
                  ref.read(kullaniciGuncelleProvider(updatedUser));

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.adSoyad} için rol güncellendi'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                child: const Text('Güncelle'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Onaylama onay dialog'u
  void _showApproveConfirmationDialog(
      BuildContext context, WidgetRef ref, KullaniciModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Onayla'),
        content: Text(
            '${user.adSoyad} kullanıcısına onay vermek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Kullanıcı onaylama
              final result =
                  await ref.read(approveUserProvider(user.id).future);

              if (context.mounted) {
                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.adSoyad} onaylandı'),
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

  // Rol adını getir
  String _getRoleName(KullaniciRolu rol) {
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
}
