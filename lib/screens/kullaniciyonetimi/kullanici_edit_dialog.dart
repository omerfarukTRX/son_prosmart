import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/models/proje_model.dart';
import 'package:prosmart/screens/kullaniciyonetimi/proje_assocition.dart';
import 'package:prosmart/service/proje_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

import 'package:prosmart/screens/kullaniciyonetimi/kullanici_model.dart';

// Düzenleme ekranı için seçili projeler provider'ı
final editScreenProjectsProvider =
    StateProvider.family<List<ProjectAssociation>, String>(
  (ref, userId) => [],
);

class KullaniciEditDialog extends ConsumerStatefulWidget {
  final KullaniciModel? kullanici;

  const KullaniciEditDialog({super.key, this.kullanici});

  @override
  ConsumerState<KullaniciEditDialog> createState() =>
      _KullaniciEditDialogState();
}

class _KullaniciEditDialogState extends ConsumerState<KullaniciEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _adSoyadController;
  late TextEditingController _emailController;
  late TextEditingController _telefonController;

  late KullaniciRolu _seciliRol;
  late bool _aktif;

  Uint8List? _profilFotoBytes;
  String? _profilFotoOnizlemeUrl;
  bool _fotografYukleniyor = false;

  List<ProjeModel> _projeler = [];
  bool _projelerLoading = true;

  @override
  void initState() {
    super.initState();

    // Controller'ları başlat
    _adSoyadController = TextEditingController(text: widget.kullanici?.adSoyad);
    _emailController = TextEditingController(text: widget.kullanici?.email);
    _telefonController = TextEditingController(text: widget.kullanici?.telefon);

    // Mevcut değerleri ayarla
    _seciliRol = widget.kullanici?.rol ?? KullaniciRolu.atanmamis;
    _aktif = widget.kullanici?.aktif ?? true;

    // Profil fotoğrafı varsa
    if (widget.kullanici?.profilFotoUrl != null) {
      _profilFotoOnizlemeUrl = widget.kullanici!.profilFotoUrl;
    }

    // Projeleri yükle
    _loadProjeler();

    // Mevcut proje ilişkilerini ayarla
    if (widget.kullanici != null &&
        widget.kullanici!.projectAssociations != null) {
      // Provider'ı güncelle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(editScreenProjectsProvider(widget.kullanici!.id).notifier)
            .state = widget.kullanici!.projectAssociations!;
      });
    }
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
  void dispose() {
    _adSoyadController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Seçili projeleri izle (yeni kullanıcı oluşturulurken null olabilir)
    final selectedProjects = widget.kullanici != null
        ? ref.watch(editScreenProjectsProvider(widget.kullanici!.id))
        : <ProjectAssociation>[];

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Başlığı
                  Row(
                    children: [
                      Text(
                        widget.kullanici == null
                            ? 'Yeni Kullanıcı'
                            : 'Kullanıcı Düzenle',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Profil Fotoğrafı
                  Center(
                    child: Column(
                      children: [
                        _buildProfilePhotoWidget(),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _fotografYukleniyor ? null : _fotografSec,
                          icon: const Icon(Icons.photo),
                          label: Text(_profilFotoOnizlemeUrl == null
                              ? 'Fotoğraf Ekle'
                              : 'Fotoğrafı Değiştir'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ad Soyad
                  TextFormField(
                    controller: _adSoyadController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ad Soyad boş olamaz';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // E-posta
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'E-posta boş olamaz';
                      }

                      // Basit bir e-posta doğrulama
                      bool emailValid = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      ).hasMatch(value);

                      if (!emailValid) {
                        return 'Geçerli bir e-posta giriniz';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Telefon
                  TextFormField(
                    controller: _telefonController,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Telefon boş olamaz';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Rol Seçimi
                  const Text(
                    'Kullanıcı Rolü',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rol kategorileri
                  _buildRollerCategoryDropdown(),
                  const SizedBox(height: 16),

                  // Aktif/Pasif
                  SwitchListTile(
                    title: const Text('Kullanıcı Aktif'),
                    subtitle: const Text('Pasif kullanıcılar giriş yapamaz'),
                    value: _aktif,
                    onChanged: (value) {
                      setState(() {
                        _aktif = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Proje İlişkilendirme Bölümü
                  if (widget.kullanici != null) ...[
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
                        onPressed: () => _showAddProjectDialog(context),
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
                        'İlişkili Projeler',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        projectModel?.unvan ??
                                            'Proje Bulunamadı',
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
                                              color:
                                                  project.role == 'siteSakini'
                                                      ? Colors.deepOrange
                                                          .withOpacity(0.1)
                                                      : Colors.pink
                                                          .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              project.role == 'siteSakini'
                                                  ? 'Kat Maliki'
                                                  : 'Kiracı',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    project.role == 'siteSakini'
                                                        ? Colors.deepOrange
                                                        : Colors.pink,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 8),

                                          // Özel erişim rozeti (varsa)
                                          if (project.hasSpecialAccess)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
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
                                      _showEditProjectDialog(context, project),
                                  tooltip: 'Düzenle',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 18),
                                  onPressed: () =>
                                      _removeProjectFromUser(project),
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
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Kullanıcı herhangi bir projeye dahil değil.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),

                  // İşlem Butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _saveUser,
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Proje ekleme dialog'u
  Future<void> _showAddProjectDialog(BuildContext context) async {
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
    String block = '';
    String apartment = '';

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
                  final currentAssociations = ref
                      .read(editScreenProjectsProvider(widget.kullanici!.id));

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
                  ref
                      .read(editScreenProjectsProvider(widget.kullanici!.id)
                          .notifier)
                      .state = [
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
  Future<void> _showEditProjectDialog(
      BuildContext context, ProjectAssociation project) async {
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
                  final currentAssociations = ref
                      .read(editScreenProjectsProvider(widget.kullanici!.id));
                  final updatedAssociations = currentAssociations.map((p) {
                    if (p.projectId == project.projectId) {
                      return updatedProject;
                    }
                    return p;
                  }).toList();

                  // Listeyi güncelle
                  ref
                      .read(editScreenProjectsProvider(widget.kullanici!.id)
                          .notifier)
                      .state = updatedAssociations;

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
  void _removeProjectFromUser(ProjectAssociation project) {
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
                  ref.read(editScreenProjectsProvider(widget.kullanici!.id));
              final updatedAssociations = currentAssociations
                  .where((p) => p.projectId != project.projectId)
                  .toList();

              // Listeyi güncelle
              ref
                  .read(
                      editScreenProjectsProvider(widget.kullanici!.id).notifier)
                  .state = updatedAssociations;

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

  // Profil fotoğrafı widget'ı
  Widget _buildProfilePhotoWidget() {
    return Stack(
      children: [
        // Ana fotoğraf
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
            image: _profilFotoOnizlemeUrl != null
                ? DecorationImage(
                    image: NetworkImage(_profilFotoOnizlemeUrl!),
                    fit: BoxFit.cover,
                  )
                : _profilFotoBytes != null
                    ? DecorationImage(
                        image: MemoryImage(_profilFotoBytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
          ),
          child: _fotografYukleniyor
              ? const Center(child: CircularProgressIndicator())
              : _profilFotoOnizlemeUrl == null && _profilFotoBytes == null
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
        ),

        // Fotoğraf ekleme butonu
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // Rol kategorileri dropdown
  Widget _buildRollerCategoryDropdown() {
    // Rol kategorileri
    const Map<String, List<KullaniciRolu>> rolKategorileri = {
      'Prosit Çalışanları': [
        KullaniciRolu.sirketYoneticisi,
        KullaniciRolu.sahaCalisani,
        KullaniciRolu.ofisCalisani,
        KullaniciRolu.teknikPersonel,
      ],
      'Site Çalışanları': [
        KullaniciRolu.peyzajPersoneli,
        KullaniciRolu.temizlikPersoneli,
        KullaniciRolu.guvenlikPersoneli,
        KullaniciRolu.danismaPersoneli,
      ],
      'Site Sakinleri': [
        KullaniciRolu.siteYoneticisi,
        KullaniciRolu.siteSakini,
        KullaniciRolu.kiraci,
      ],
      'Tedarikçiler': [
        KullaniciRolu.usta,
        KullaniciRolu.tedarikci,
      ],
    };

    return Column(
      children: [
        // Kategoriye göre sekmeli rol seçimi
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: rolKategorileri.entries.expand((entry) {
              // Her kategori için roller
              return entry.value.map((rol) {
                final isSelected = _seciliRol == rol;

                return ChoiceChip(
                  label: Text(_getRolGorunenAd(rol)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _seciliRol = rol;
                      });
                    }
                  },
                );
              }).toList();
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Fotoğraf seçme işlemi
  Future<void> _fotografSec() async {
    try {
      setState(() {
        _fotografYukleniyor = true;
      });

      final ImagePicker picker = ImagePicker();

      if (kIsWeb) {
        // Web için fotoğraf seçimi
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
        );

        if (pickedFile != null) {
          // Web için dosya okuma
          _profilFotoBytes = await pickedFile.readAsBytes();
          setState(() {});
        }
      } else {
        // Mobil için fotoğraf seçimi
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
        );

        if (pickedFile != null) {
          // Mobil için dosya okuma
          final bytes = await File(pickedFile.path).readAsBytes();
          setState(() {
            _profilFotoBytes = bytes;
          });
        }
      }
    } catch (e) {
      // Hata durumunda
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilirken hata: $e')),
      );
    } finally {
      setState(() {
        _fotografYukleniyor = false;
      });
    }
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

  // Kullanıcıyı kaydet
  void _saveUser() {
    if (_formKey.currentState!.validate()) {
      // Mevcut proje ilişkilerini al
      final projectAssociations = widget.kullanici != null
          ? ref.read(editScreenProjectsProvider(widget.kullanici!.id))
          : <ProjectAssociation>[];

      // Yeni kullanıcı oluştur veya mevcut kullanıcıyı güncelle
      final kullanici = KullaniciModel(
        id: widget.kullanici?.id ?? '',
        adSoyad: _adSoyadController.text.trim(),
        email: _emailController.text.trim(),
        telefon: _telefonController.text.trim(),
        rol: _seciliRol,
        aktif: _aktif,
        kayitTarihi: widget.kullanici?.kayitTarihi,
        profilFotoUrl: widget.kullanici?.profilFotoUrl,
        ekBilgiler: widget.kullanici?.ekBilgiler,
        projectAssociations: projectAssociations,
      );

      Navigator.pop(context, kullanici);
    }
  }

  // Yardımcı metot - Rol görünen adını al
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
}
