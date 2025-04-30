import 'package:flutter/material.dart';

class IstatistikSayfasi extends StatelessWidget {
  const IstatistikSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
      ),
      body: const Center(
        child: Text(
          'İstatistik verileri burada gösterilecek',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
