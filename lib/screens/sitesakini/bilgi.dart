import 'package:flutter/material.dart';

class BilgiPage extends StatelessWidget {
  const BilgiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilgi'),
      ),
      body: const Center(
        child: Text('Bilgi sayfası içeriği burada olacak'),
      ),
    );
  }
}
