import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjeTipi { site, isMerkezi, karma }

enum AbonelikTipi { elektrik, su, dogalgaz, internet }

class AbonelikModel {
  final String id;
  final AbonelikTipi tip;
  final String aboneNo;
  final String? yer;
  final bool isActive;

  AbonelikModel({
    required this.id,
    required this.tip,
    required this.aboneNo,
    this.yer,
    this.isActive = true,
  });

  factory AbonelikModel.fromMap(Map<String, dynamic> map) {
    return AbonelikModel(
      id: map['id'] ?? '',
      tip: AbonelikTipi.values.firstWhere(
        (e) => e.toString().split('.').last == map['tip'],
        orElse: () => AbonelikTipi.elektrik,
      ),
      aboneNo: map['aboneNo'] ?? '',
      yer: map['yer'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tip': tip.toString().split('.').last,
      'aboneNo': aboneNo,
      'yer': yer,
      'isActive': isActive,
    };
  }
}

class ProjeModel {
  final String id;
  final String unvan;
  final String adres;
  final ProjeTipi tip;
  final List<String> fotograflar;
  final GeoPoint konum;
  final List<String> yetkiliPersonelIds;
  final int blokSayisi;
  final int bagimsizBolumSayisi;
  final String ibanNo;
  final String vergiNo;
  final List<AbonelikModel> abonelikler;
  final String? qrKod;
  final bool isActive;
  final Timestamp olusturulmaTarihi;
  final Timestamp? guncellemeTarihi;

  ProjeModel({
    required this.id,
    required this.unvan,
    required this.adres,
    required this.tip,
    this.fotograflar = const [],
    required this.konum,
    this.yetkiliPersonelIds = const [],
    required this.blokSayisi,
    required this.bagimsizBolumSayisi,
    required this.ibanNo,
    required this.vergiNo,
    this.abonelikler = const [],
    this.qrKod,
    this.isActive = true,
    required this.olusturulmaTarihi,
    this.guncellemeTarihi,
  });

  factory ProjeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjeModel(
      id: doc.id,
      unvan: data['unvan'] ?? '',
      adres: data['adres'] ?? '',
      tip: ProjeTipi.values.firstWhere(
        (e) => e.toString().split('.').last == data['tip'],
        orElse: () => ProjeTipi.site,
      ),
      fotograflar: List<String>.from(data['fotograflar'] ?? []),
      konum: data['konum'] ?? const GeoPoint(0, 0),
      yetkiliPersonelIds: List<String>.from(data['yetkiliPersonelIds'] ?? []),
      blokSayisi: data['blokSayisi'] ?? 0,
      bagimsizBolumSayisi: data['bagimsizBolumSayisi'] ?? 0,
      ibanNo: data['ibanNo'] ?? '',
      vergiNo: data['vergiNo'] ?? '',
      abonelikler: (data['abonelikler'] as List<dynamic>?)
              ?.map((e) => AbonelikModel.fromMap(e))
              .toList() ??
          [],
      qrKod: data['qrKod'],
      isActive: data['isActive'] ?? true,
      olusturulmaTarihi: data['olusturulmaTarihi'] ?? Timestamp.now(),
      guncellemeTarihi: data['guncellemeTarihi'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'unvan': unvan,
      'adres': adres,
      'tip': tip.toString().split('.').last,
      'fotograflar': fotograflar,
      'konum': konum,
      'yetkiliPersonelIds': yetkiliPersonelIds,
      'blokSayisi': blokSayisi,
      'bagimsizBolumSayisi': bagimsizBolumSayisi,
      'ibanNo': ibanNo,
      'vergiNo': vergiNo,
      'abonelikler': abonelikler.map((e) => e.toMap()).toList(),
      'qrKod': qrKod,
      'isActive': isActive,
      'olusturulmaTarihi': olusturulmaTarihi,
      'guncellemeTarihi': guncellemeTarihi ?? FieldValue.serverTimestamp(),
    };
  }

  ProjeModel copyWith({
    String? id,
    String? unvan,
    String? adres,
    ProjeTipi? tip,
    List<String>? fotograflar,
    GeoPoint? konum,
    List<String>? yetkiliPersonelIds,
    int? blokSayisi,
    int? bagimsizBolumSayisi,
    String? ibanNo,
    String? vergiNo,
    List<AbonelikModel>? abonelikler,
    String? qrKod,
    bool? isActive,
    Timestamp? olusturulmaTarihi,
    Timestamp? guncellemeTarihi,
  }) {
    return ProjeModel(
      id: id ?? this.id,
      unvan: unvan ?? this.unvan,
      adres: adres ?? this.adres,
      tip: tip ?? this.tip,
      fotograflar: fotograflar ?? this.fotograflar,
      konum: konum ?? this.konum,
      yetkiliPersonelIds: yetkiliPersonelIds ?? this.yetkiliPersonelIds,
      blokSayisi: blokSayisi ?? this.blokSayisi,
      bagimsizBolumSayisi: bagimsizBolumSayisi ?? this.bagimsizBolumSayisi,
      ibanNo: ibanNo ?? this.ibanNo,
      vergiNo: vergiNo ?? this.vergiNo,
      abonelikler: abonelikler ?? this.abonelikler,
      qrKod: qrKod ?? this.qrKod,
      isActive: isActive ?? this.isActive,
      olusturulmaTarihi: olusturulmaTarihi ?? this.olusturulmaTarihi,
      guncellemeTarihi: guncellemeTarihi ?? this.guncellemeTarihi,
    );
  }
}
