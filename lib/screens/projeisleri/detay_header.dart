import 'package:flutter/material.dart';
import 'package:prosmart/models/proje_model.dart';

class DetayHeader extends StatelessWidget {
  final ProjeModel proje;

  const DetayHeader({required this.proje, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      title: Text(
        proje.unvan,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      expandedHeight: 0, // Header yüksekliğini kaldır
      flexibleSpace: const SizedBox.shrink(), // Flex alanını kaldır
      actions: [
        // Proje tipi etiketi
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Chip(
            backgroundColor: theme.colorScheme.primaryContainer,
            label: Text(
              proje.tip.toString().split('.').last,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
