import 'package:flutter/material.dart';

class BakimTalepPage extends StatelessWidget {
  final String bakimId;
  final Map<String, dynamic> bakimData;

  const BakimTalepPage({
    super.key,
    required this.bakimId,
    required this.bakimData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bakimData['baslik'] ?? 'Bakım Talebi'),
      ),
      body: const Center(
        child: Text('Bakım talep formu burada olacak'),
      ),
    );
  }
}
