import 'package:flutter/material.dart';

class ProsmartPage extends StatelessWidget {
  const ProsmartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProSmart'),
      ),
      body: const Center(
        child: Text('ProSmart sayfası içeriği burada olacak'),
      ),
    );
  }
}
