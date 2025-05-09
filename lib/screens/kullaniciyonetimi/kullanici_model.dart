import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/screens/kullaniciyonetimi/proje_assocition.dart';

class KullaniciModel {
  final String id;
  final String adSoyad;
  final String email;
  final String telefon;
  final KullaniciRolu rol;
  final bool aktif;
  final DateTime? kayitTarihi;
  final String? profilFotoUrl;
  final Map<String, dynamic>? ekBilgiler;
  final List<ProjectAssociation>? projectAssociations; // Yeni alan

  KullaniciModel({
    required this.id,
    required this.adSoyad,
    required this.email,
    required this.telefon,
    required this.rol,
    this.aktif = true,
    this.kayitTarihi,
    this.profilFotoUrl,
    this.ekBilgiler,
    this.projectAssociations, // Constructor'a ekledik
  });

  // Firestore'dan dönüştürme
  factory KullaniciModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KullaniciModel(
      id: doc.id,
      adSoyad: data['adSoyad'] ?? '',
      email: data['email'] ?? '',
      telefon: data['telefon'] ?? '',
      rol: _parseRol(data['rol']),
      aktif: data['aktif'] ?? true,
      kayitTarihi: (data['kayitTarihi'] as Timestamp?)?.toDate(),
      profilFotoUrl: data['profilFotoUrl'],
      ekBilgiler: data['ekBilgiler'],
      projectAssociations: (data['projectAssociations'] as List<dynamic>?)
          ?.map((e) => ProjectAssociation.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static KullaniciRolu _parseRol(String? rolString) {
    if (rolString == null) return KullaniciRolu.atanmamis;

    try {
      return KullaniciRolu.values.firstWhere(
        (rol) => rol.toString().split('.').last == rolString,
        orElse: () => KullaniciRolu.atanmamis,
      );
    } catch (e) {
      return KullaniciRolu.atanmamis;
    }
  }

  // Firestore'a dönüştürme
  Map<String, dynamic> toFirestore() {
    return {
      'adSoyad': adSoyad,
      'email': email,
      'telefon': telefon,
      'rol': rol.toString().split('.').last,
      'aktif': aktif,
      'kayitTarihi': kayitTarihi != null
          ? Timestamp.fromDate(kayitTarihi!)
          : Timestamp.now(),
      'profilFotoUrl': profilFotoUrl,
      'ekBilgiler': ekBilgiler,
      'projectAssociations':
          projectAssociations?.map((e) => e.toMap()).toList(),
    };
  }

  // Kopyalama ile değişiklik yapma
  KullaniciModel copyWith({
    String? adSoyad,
    String? email,
    String? telefon,
    KullaniciRolu? rol,
    bool? aktif,
    DateTime? kayitTarihi,
    String? profilFotoUrl,
    Map<String, dynamic>? ekBilgiler,
    List<ProjectAssociation>? projectAssociations, // copyWith'e ekledik
  }) {
    return KullaniciModel(
      id: id,
      adSoyad: adSoyad ?? this.adSoyad,
      email: email ?? this.email,
      telefon: telefon ?? this.telefon,
      rol: rol ?? this.rol,
      aktif: aktif ?? this.aktif,
      kayitTarihi: kayitTarihi ?? this.kayitTarihi,
      profilFotoUrl: profilFotoUrl ?? this.profilFotoUrl,
      ekBilgiler: ekBilgiler ?? this.ekBilgiler,
      projectAssociations:
          projectAssociations ?? this.projectAssociations, // Kopyalama
    );
  }
}
