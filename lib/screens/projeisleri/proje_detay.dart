import 'package:flutter/material.dart';
import 'package:prosmart/models/proje_model.dart';
import 'package:prosmart/screens/projeisleri/ayarlar_paneli.dart';
import 'package:prosmart/screens/projeisleri/bilgi_karti.dart';
import 'package:prosmart/screens/projeisleri/detay_header.dart';
import 'package:prosmart/screens/projeisleri/foto_galeri.dart';
import 'package:prosmart/screens/projeisleri/proje_form.dart';

class ProjeDetaySayfasi extends StatefulWidget {
  final ProjeModel proje;

  const ProjeDetaySayfasi({required this.proje, super.key});

  @override
  State<ProjeDetaySayfasi> createState() => _ProjeDetaySayfasiState();
}

class _ProjeDetaySayfasiState extends State<ProjeDetaySayfasi>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Aktif proje modelini saklayalım
  late ProjeModel _aktifProje;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Widget'ın projesini başlangıç değeri olarak al
    _aktifProje = widget.proje;
    debugPrint(
        'ProjeDetaySayfasi oluşturuldu: ${widget.proje.unvan} (ID: ${widget.proje.id})');
  }

  @override
  void didUpdateWidget(ProjeDetaySayfasi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proje.id != widget.proje.id) {
      setState(() {
        _aktifProje = widget.proje;
      });
      debugPrint(
          'ProjeDetaySayfasi güncellendi: ${widget.proje.unvan} (ID: ${widget.proje.id})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
      appBar: AppBar(
        title: Text(_aktifProje.unvan),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          Chip(
            backgroundColor: theme.colorScheme.primaryContainer,
            label: Text(
              _aktifProje.tip.toString().split('.').last,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                width: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            tabs: const [
              Tab(icon: Icon(Icons.info_outline), text: "Genel"),
              Tab(icon: Icon(Icons.photo_library), text: "Galeri"),
              Tab(icon: Icon(Icons.settings), text: "Ayarlar"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGenelBilgiler(),
                FotoGaleri(fotograflar: _aktifProje.fotograflar),
                AyarlarPaneli(proje: _aktifProje),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        onPressed: _showEditDialog,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildGenelBilgiler() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          BilgiKarti(
            icon: Icons.location_on,
            title: "Adres",
            value: _aktifProje.adres,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BilgiKarti(
                  icon: Icons.apartment,
                  title: "Blok Sayısı",
                  value: _aktifProje.blokSayisi.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BilgiKarti(
                  icon: Icons.door_front_door,
                  title: "Bağımsız Bölüm",
                  value: _aktifProje.bagimsizBolumSayisi.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BilgiKarti(
            icon: Icons.account_balance,
            title: "IBAN No",
            value: _aktifProje.ibanNo,
          ),
          const SizedBox(height: 12),
          BilgiKarti(
            icon: Icons.receipt,
            title: "Vergi No",
            value: _aktifProje.vergiNo,
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    // Form için key oluştur
    final formKey = GlobalKey<FormState>();
    final projeFormKey = GlobalKey<ProjeFormState>();

    // Geçici proje referansı
    ProjeModel guncellenecekProje = _aktifProje;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Projeyi Düzenle"),
        content: SingleChildScrollView(
          child: ProjeForm(
            proje: _aktifProje,
            formKey: formKey,
            projeFormKey: projeFormKey,
            onSaved: (model) {
              guncellenecekProje = model;
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text("İptal"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Kaydet"),
            onPressed: () {
              // Form geçerli mi kontrol et
              if (formKey.currentState!.validate()) {
                // Global key ile ProjeFormState'e erişebiliriz
                if (projeFormKey.currentState?.saveForm() ?? false) {
                  // State'i güncelle
                  setState(() {
                    _aktifProje = guncellenecekProje;
                  });

                  // Dialogu kapat
                  Navigator.pop(context);

                  // Başarı mesajı göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Proje güncellendi")),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
