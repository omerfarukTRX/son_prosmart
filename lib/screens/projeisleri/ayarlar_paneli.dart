import 'package:flutter/material.dart';
import 'package:prosmart/models/proje_model.dart';

class AyarlarPaneli extends StatelessWidget {
  final ProjeModel proje;

  const AyarlarPaneli({required this.proje, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text("Proje Durumu"),
                subtitle: Text(proje.isActive ? "Aktif" : "Pasif"),
                value: proje.isActive,
                onChanged: (value) {
                  // Firestore güncelleme
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text("QR Kodu Yönet"),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Projeyi Sil"),
                textColor: theme.colorScheme.error,
                iconColor: theme.colorScheme.error,
                onTap: () => _showDeleteDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Projeyi Sil"),
        content: const Text("Bu projeyi silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            child: const Text("İptal"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
            onPressed: () {
              // Silme işlemi
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
