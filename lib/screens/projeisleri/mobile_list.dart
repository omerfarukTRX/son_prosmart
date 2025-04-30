import 'package:flutter/material.dart';
import 'package:prosmart/models/proje_model.dart';
import 'package:prosmart/screens/projeisleri/proje_karti.dart';

class MobileProjeListesi extends StatelessWidget {
  final List<ProjeModel> projeler;
  final Function(ProjeModel) onProjeSelected;

  const MobileProjeListesi({
    required this.projeler,
    required this.onProjeSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projeler.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProjeKarti(
            proje: projeler[index],
            index: index,
            onTap: () => onProjeSelected(projeler[index]),
          ),
        );
      },
    );
  }
}
