import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prosmart/models/proje_model.dart';
import 'package:prosmart/screens/projeisleri/custom_app_bar.dart';
import 'package:prosmart/screens/projeisleri/proje_ekle_sayfasi.dart';
import 'package:prosmart/screens/projeisleri/mobile_list.dart';
import 'package:prosmart/screens/projeisleri/web_list.dart';
import 'istatistik.dart';
import 'proje_detay.dart';

class ProjeListeSayfasi extends StatefulWidget {
  const ProjeListeSayfasi({super.key});

  @override
  State<ProjeListeSayfasi> createState() => _ProjeListeSayfasiState();
}

class _ProjeListeSayfasiState extends State<ProjeListeSayfasi> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<ProjeModel> _projeler = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showInactive = false;
  ProjeModel? _selectedProje;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    // İlk yüklemede otomatik seçim yapılmayacak
    // _selectedProje null olarak kalacak ve istatistik sayfası gösterilecek
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore.collection('projeler').get();
      final projects = snapshot.docs.map(ProjeModel.fromFirestore).toList()
        ..sort((a, b) => a.unvan.compareTo(b.unvan));

      setState(() {
        _projeler = projects;
        _isLoading = false;
        // İlk projeyi otomatik olarak seçmiyoruz
        // Kullanıcı tıklayana kadar istatistik sayfası gösterilecek
      });
    } catch (e) {
      debugPrint("Proje yükleme hatası: $e");
      setState(() => _isLoading = false);
    }
  }

  // Proje seçimi için callback fonksiyonu
  void _selectProje(ProjeModel proje) {
    setState(() {
      _selectedProje = proje;
    });
  }

  List<ProjeModel> get _filteredProjects {
    return _projeler.where((proje) {
      final matchesSearch =
          proje.unvan.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _showInactive || proje.isActive;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: ProjeAppBar(
        searchController: _searchController,
        onSearchChanged: (query) => setState(() => _searchQuery = query),
        onFilterToggled: (value) => setState(() => _showInactive = value),
        onRefresh: _loadProjects,
        showInactive: _showInactive,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProjects.isEmpty
              ? _buildEmptyState()
              : isDesktop
                  ? WebProjeListesi(
                      projeler: _filteredProjects,
                      selectedProje: _selectedProje,
                      onProjeSelected: _selectProje,
                    )
                  : MobileProjeListesi(
                      projeler: _filteredProjects,
                      onProjeSelected: _navigateToDetail,
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ProjeEkleSayfasi()),
          );
          if (result == true) {
            _loadProjects(); // Listeyi yenile
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            _showInactive ? 'Hiç proje bulunamadı' : 'Aktif proje bulunamadı',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!_showInactive) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() => _showInactive = true),
              child: const Text('Pasif projeleri göster'),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToDetail(ProjeModel proje) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ProjeDetaySayfasi(proje: proje),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
