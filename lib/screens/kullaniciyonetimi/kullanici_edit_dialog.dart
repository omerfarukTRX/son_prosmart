import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

import 'package:prosmart/screens/kullaniciyonetimi/kullanici_model.dart';

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

                      if (value.length < 10) {
                        return 'Telefon numarası en az 10 haneli olmalıdır';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

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

  // Kullanıcıyı kaydet
  void _saveUser() {
    if (_formKey.currentState!.validate()) {
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
