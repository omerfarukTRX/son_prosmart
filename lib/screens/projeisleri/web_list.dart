import 'package:flutter/material.dart';
import 'package:prosmart/models/proje_model.dart';
import 'package:prosmart/screens/projeisleri/istatistik.dart';
import 'package:prosmart/screens/projeisleri/proje_detay.dart';
import 'package:prosmart/screens/projeisleri/proje_karti.dart';

class WebProjeListesi extends StatefulWidget {
  final List<ProjeModel> projeler;
  final void Function(ProjeModel) onProjeSelected;
  final ProjeModel? selectedProje;

  const WebProjeListesi({
    required this.projeler,
    required this.onProjeSelected,
    this.selectedProje,
    super.key,
  });

  @override
  State<WebProjeListesi> createState() => _WebProjeListesiState();
}

class _WebProjeListesiState extends State<WebProjeListesi> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sol Liste
        Expanded(
          flex: 1,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.projeler.length,
            itemBuilder: (context, index) {
              final proje = widget.projeler[index];
              final isSelected = widget.selectedProje?.id == proje.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProjeKarti(
                  proje: proje,
                  index: index,
                  isWeb: true,
                  isSelected: isSelected,
                  onTap: () {
                    // Parent widget'a seçilen projeyi bildir
                    widget.onProjeSelected(proje);
                  },
                ),
              );
            },
          ),
        ),
        // Sağ Detay - selectedProje null ise IstatistikSayfasi göster
        Expanded(
          flex: 2,
          child: widget.selectedProje == null
              ? const IstatistikSayfasi() // Boş istatistik sayfası
              : ProjeDetaySayfasi(
                  key: ValueKey(widget.selectedProje!.id),
                  proje: widget.selectedProje!),
        ),
      ],
    );
  }
}
