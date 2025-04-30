import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import '../../models/menu_model.dart';
import '../../utils/icon_helper.dart';
import 'icon_picker_dialog.dart';

class MenuEditDialog extends ConsumerStatefulWidget {
  final MenuModel? menu;

  const MenuEditDialog({
    super.key,
    this.menu,
  });

  @override
  ConsumerState<MenuEditDialog> createState() => _MenuEditDialogState();
}

class _MenuEditDialogState extends ConsumerState<MenuEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _routeController;
  late String _selectedIcon;
  late bool _isActive;
  final Set<String> _selectedRoles = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.menu?.title);
    _routeController = TextEditingController(text: widget.menu?.route);
    _selectedIcon = widget.menu?.icon ?? 'dashboard_outlined';
    _isActive = widget.menu?.isActive ?? true;
    if (widget.menu != null) {
      _selectedRoles.addAll(widget.menu!.roles);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Başlığı
                  Row(
                    children: [
                      Text(
                        widget.menu == null ? 'Yeni Menü' : 'Menü Düzenle',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Menü Adı
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Menü Adı',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Menü adı boş olamaz';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () async {
                          final selectedIcon = await showDialog<String>(
                            context: context,
                            builder: (context) => IconPickerDialog(
                              selectedIcon: _selectedIcon,
                            ),
                          );
                          if (selectedIcon != null) {
                            setState(() {
                              _selectedIcon = selectedIcon;
                            });
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(IconHelper.getIcon(_selectedIcon)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Route
                  TextFormField(
                    controller: _routeController,
                    decoration: const InputDecoration(
                      labelText: 'Route',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Route boş olamaz';
                      }
                      if (!value.startsWith('/')) {
                        return 'Route "/" ile başlamalıdır';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Roller
                  const Text(
                    'Roller',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: KullaniciRolu.values.map((rol) {
                      final rolStr = rol.toString().split('.').last;
                      return FilterChip(
                        label: Text(rolStr),
                        selected: _selectedRoles.contains(rolStr),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRoles.add(rolStr);
                            } else {
                              _selectedRoles.remove(rolStr);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Aktif/Pasif
                  SwitchListTile(
                    title: const Text('Aktif'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Butonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveMenu,
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveMenu() {
    if (_formKey.currentState!.validate()) {
      if (_selectedRoles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('En az bir rol seçmelisiniz'),
          ),
        );
        return;
      }

      final menu = MenuModel(
        id: widget.menu?.id ?? DateTime.now().toString(),
        title: _titleController.text,
        route: _routeController.text,
        icon: _selectedIcon,
        roles: _selectedRoles.toList(),
        isActive: _isActive,
        order: widget.menu?.order ?? 0,
      );

      Navigator.pop(context, menu);
    }
  }
}
