import 'package:flutter/material.dart';

class DuyurularPage extends StatelessWidget {
  const DuyurularPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyurular'),
      ),
      body: const Center(
        child: Text('Duyurular sayfası içeriği burada olacak'),
      ),
    );
  }
}
