import 'package:flutter/material.dart';
import 'package:prosmart/models/proje_model.dart';
import 'package:prosmart/screens/projeisleri/proje_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjeEkleSayfasi extends StatefulWidget {
  const ProjeEkleSayfasi({super.key});

  @override
  State<ProjeEkleSayfasi> createState() => _ProjeEkleSayfasiState();
}

class _ProjeEkleSayfasiState extends State<ProjeEkleSayfasi> {
  final _formKey = GlobalKey<FormState>();

  // Form referansı ve key
  final _projeFormKey = GlobalKey<ProjeFormState>();

  // Boş bir proje modeli oluştur
  late ProjeModel _yeniProje = ProjeModel(
    id: '',
    unvan: '',
    adres: '',
    ibanNo: '',
    vergiNo: '',
    blokSayisi: 0,
    bagimsizBolumSayisi: 0,
    isActive: true,
    tip: ProjeTipi.site,
    konum: const GeoPoint(0, 0),
    olusturulmaTarihi: Timestamp.now(),
  );

  // Proje modelini güncelle
  void _updateProjeModel(ProjeModel model) {
    setState(() {
      _yeniProje = model;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Proje Oluştur'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.1),
              theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ],
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            margin: isMobile
                ? const EdgeInsets.all(16)
                : const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık ve Adımlar
                  _buildHeader(theme),
                  const SizedBox(height: 32),

                  // Form Alanı - ProjeForm instance'ını saklayacak şekilde oluşturalım
                  ProjeForm(
                    key: ValueKey('projeForm'),
                    proje: _yeniProje,
                    formKey: _formKey,
                    projeFormKey: _projeFormKey,
                    onSaved: _updateProjeModel,
                  ),

                  // Kaydet Butonu
                  const SizedBox(height: 24),
                  _buildSaveButton(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Proje Bilgileri',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tüm alanları doldurarak yeni projenizi oluşturabilirsiniz',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          // Artık _projeFormKey kullanarak doğrudan ProjeFormState'e erişebiliriz
          if (_projeFormKey.currentState?.saveForm() ?? false) {
            // Firestore kayıt işlemleri burada yapılabilir

            // Başarılı sonuç döndür ve sayfayı kapat
            Navigator.pop(context, true);
          }
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      child: const Text('PROJEYİ KAYDET', style: TextStyle(fontSize: 16)),
    );
  }
}
