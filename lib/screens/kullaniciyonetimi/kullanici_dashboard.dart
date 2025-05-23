import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prosmart/screens/kullaniciyonetimi/kullanici_provider.dart';
import 'package:prosmart/screens/kullaniciyonetimi/stat_card.dart';
import 'package:prosmart/widgets/stat_card.dart';

class KullaniciDashboard extends ConsumerWidget {
  const KullaniciDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kullanicilarAsyncValue = ref.watch(kullanicilarProvider);
    final rolDagilimi = ref.watch(kullaniciRolDagilimProvider);

    return kullanicilarAsyncValue.when(
      data: (kullanicilar) {
        // Toplam kullanıcı sayısı
        final toplamKullanici = kullanicilar.length;

        // Aktif kullanıcı sayısı
        final aktifKullanici = kullanicilar.where((k) => k.aktif).length;

        // Kategori bazında kullanıcı sayıları
        final prositCalisanlar = kullanicilar
            .where((k) =>
                k.rol == KullaniciRolu.sirketYoneticisi ||
                k.rol == KullaniciRolu.sahaCalisani ||
                k.rol == KullaniciRolu.ofisCalisani ||
                k.rol == KullaniciRolu.teknikPersonel)
            .length;

        final siteCalisanlar = kullanicilar
            .where((k) =>
                k.rol == KullaniciRolu.peyzajPersoneli ||
                k.rol == KullaniciRolu.temizlikPersoneli ||
                k.rol == KullaniciRolu.guvenlikPersoneli ||
                k.rol == KullaniciRolu.danismaPersoneli)
            .length;

        final siteSakinleri = kullanicilar
            .where((k) =>
                k.rol == KullaniciRolu.siteYoneticisi ||
                k.rol == KullaniciRolu.siteSakini ||
                k.rol == KullaniciRolu.kiraci)
            .length;

        final tedarikciler = kullanicilar
            .where((k) =>
                k.rol == KullaniciRolu.usta || k.rol == KullaniciRolu.tedarikci)
            .length;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık kaldırıldı (istendiği gibi)

                // Özet İstatistikler
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatCard(
                      title: 'Toplam Kullanıcı',
                      value: toplamKullanici.toString(),
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    StatCard(
                      title: 'Aktif Kullanıcı',
                      value: '$aktifKullanici',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    StatCard(
                      title: 'Pasif Kullanıcı',
                      value: '${toplamKullanici - aktifKullanici}',
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Kategori Dağılımı
                const Text(
                  'Kategori Dağılımı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Kategori çubuk grafiği
                SizedBox(
                  height: 200,
                  child: _buildCategoryBarChart(prositCalisanlar,
                      siteCalisanlar, siteSakinleri, tedarikciler),
                ),
                const SizedBox(height: 24),

                // Rol Dağılımı
                const Text(
                  'Rol Dağılımı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Rol pasta grafiği
                Expanded(
                  child: _buildRolPieChart(rolDagilimi),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Hata: $error'),
      ),
    );
  }

  // Kategori çubuk grafiği
  Widget _buildCategoryBarChart(
      int prosit, int site, int sakin, int tedarikci) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          _makeBarGroup(0, prosit.toDouble(), Colors.blue),
          _makeBarGroup(1, site.toDouble(), Colors.green),
          _makeBarGroup(2, sakin.toDouble(), Colors.orange),
          _makeBarGroup(3, tedarikci.toDouble(), Colors.purple),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = [
                  'Prosit\nÇalışanları',
                  'Site\nÇalışanları',
                  'Site\nSakinleri',
                  'Tedarikçiler',
                ];

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    titles[value.toInt()],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        gridData: const FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
        ),
      ),
    );
  }

  // Rol pasta grafiği
  Widget _buildRolPieChart(Map<String, int> rolDagilimi) {
    // Renk listesi
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.pink,
      Colors.cyan,
      Colors.lime,
      Colors.brown,
      Colors.blueGrey,
    ];

    if (rolDagilimi.isEmpty) {
      return const Center(child: Text('Veri yok'));
    }

    // Pasta dilimlerini oluştur
    final sections = <PieChartSectionData>[];
    int colorIndex = 0;

    for (var entry in rolDagilimi.entries) {
      if (entry.value > 0) {
        sections.add(
          PieChartSectionData(
            value: entry.value.toDouble(),
            title: '${entry.key}\n${entry.value}',
            color: colors[colorIndex % colors.length],
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        colorIndex++;
      }
    }

    return sections.isEmpty
        ? const Center(child: Text('Veri yok'))
        : PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 0,
              sectionsSpace: 2,
            ),
          );
  }

  // Çubuk grubu oluşturma fonksiyonu
  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 25,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}
