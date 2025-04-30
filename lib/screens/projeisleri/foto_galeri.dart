import 'package:flutter/material.dart';

class FotoGaleri extends StatelessWidget {
  final List<String> fotograflar;

  const FotoGaleri({required this.fotograflar, super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: fotograflar.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return GestureDetector(
            onTap: () => _pickImage(),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_a_photo, size: 40),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            fotograflar[index - 1],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  void _pickImage() {
    // Fotoğraf seçme işlemi
  }
}
