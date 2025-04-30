enum KullaniciRolu {
  sirketYoneticisi,
  siteYoneticisi,
  sahaCalisani,
  ofisCalisani,
  teknikPersonel,
  peyzajPersoneli,
  temizlikPersoneli,
  guvenlikPersoneli,
  danismaPersoneli,
  siteSakini,
  kiraci,
  usta,
  tedarikci,
  atanmamis
}

extension KullaniciRoluExtension on KullaniciRolu {
  String get ad {
    return toString().split('.').last;
  }

  String get gorunenAd {
    switch (this) {
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
    }
  }
}
