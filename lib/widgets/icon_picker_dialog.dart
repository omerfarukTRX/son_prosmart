import 'package:flutter/material.dart';
import '../../utils/icon_helper.dart';

class IconPickerDialog extends StatefulWidget {
  final String? selectedIcon;

  const IconPickerDialog({
    super.key,
    this.selectedIcon,
  });

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  String? _searchQuery;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, IconData>> get filteredIcons {
    final allIcons = IconHelper.getAllIcons();
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return allIcons;
    }
    return allIcons
        .where((icon) =>
            icon.key.toLowerCase().contains(_searchQuery!.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Başlığı
              Row(
                children: [
                  const Text(
                    'İkon Seç',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Kapatma butonu
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Arama Çubuğu
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'İkon ara...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // İkon Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: filteredIcons.length,
                  itemBuilder: (context, index) {
                    final iconEntry = filteredIcons[index];
                    final isSelected = iconEntry.key == widget.selectedIcon;

                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop(iconEntry.key);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : null,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Tooltip(
                          message: iconEntry.key,
                          child: Icon(
                            iconEntry.value,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : null,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
