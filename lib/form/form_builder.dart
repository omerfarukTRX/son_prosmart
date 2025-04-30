import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prosmart/form/form_element_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/form/form_provider.dart';
import 'package:prosmart/form/form_service.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

/// Form oluşturucu ekranı
class FormBuilderScreen extends ConsumerStatefulWidget {
  final String projectId;

  const FormBuilderScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends ConsumerState<FormBuilderScreen> {
  final _formTitleController = TextEditingController();
  final _formDescController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showAdvancedSettings = false;

  @override
  void dispose() {
    _formTitleController.dispose();
    _formDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formFieldsNotifier = ref.watch(formFieldsProvider.notifier);
    final formFields = ref.watch(formFieldsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Form Oluştur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _showAdvancedSettings = !_showAdvancedSettings;
              });
            },
            tooltip: 'Form Ayarları',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveForm,
            tooltip: 'Formu Kaydet',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  // Form başlık ve açıklama bölümü
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _formTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Form Başlığı',
                            hintText: 'Örn: Memnuniyet Anketi',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen form başlığı girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _formDescController,
                          decoration: const InputDecoration(
                            labelText: 'Form Açıklaması (İsteğe Bağlı)',
                            hintText: 'Formu dolduranlar için bilgi...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),

                  // Form ayarları bölümü (katlanabilir)
                  if (_showAdvancedSettings) _buildAdvancedSettings(),

                  // Ara başlık - Form Elemanları
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'Form Elemanları',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Text(
                          'Elemanları sürükleyip düzenleyebilirsiniz',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Alanları
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sol panel - Kullanılabilir form elemanları
                        SizedBox(
                          width: 200,
                          child: _buildAvailableFormFieldsPanel(),
                        ),

                        // Ayırıcı çizgi
                        const VerticalDivider(width: 1),

                        // Sağ panel - Form önizleme ve düzenleme alanı
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: DragTarget<FormFieldType>(
                              onWillAcceptWithDetails: (data) => true,
                              onAcceptWithDetails:
                                  (DragTargetDetails<FormFieldType> details) {
                                FormFieldType fieldType = details.data;
                                String label;
                                switch (fieldType) {
                                  case FormFieldType.textField:
                                    label = 'Metin Sorusu';
                                    break;
                                  case FormFieldType.textArea:
                                    label = 'Uzun Metin Sorusu';
                                    break;
                                  case FormFieldType.radioButton:
                                    label = 'Çoktan Seçmeli Soru';
                                    break;
                                  case FormFieldType.checkbox:
                                    label = 'Onay Kutuları';
                                    break;
                                  case FormFieldType.dropdown:
                                    label = 'Açılır Liste';
                                    break;
                                  case FormFieldType.dateField:
                                    label = 'Tarih Seçimi';
                                    break;
                                  case FormFieldType.fileUpload:
                                    label = 'Dosya Yükleme';
                                    break;
                                  case FormFieldType.rating:
                                    label = 'Derecelendirme';
                                    break;
                                  case FormFieldType.section:
                                    label = 'Bölüm Başlığı';
                                    break;
                                  case FormFieldType.paragraph:
                                    label = 'Bilgi Metni';
                                    break;
                                }

                                formFieldsNotifier.addFormField(
                                  FormFieldx(
                                    type: fieldType,
                                    label: label,
                                    options:
                                        _fieldTypeRequiresOptions(fieldType)
                                            ? [
                                                FieldOption(label: 'Seçenek 1'),
                                                FieldOption(label: 'Seçenek 2'),
                                                FieldOption(label: 'Seçenek 3'),
                                              ]
                                            : null,
                                    validation: ValidationRule(),
                                  ),
                                );
                              },
                              builder: (context, candidateData, rejectedData) {
                                return Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: candidateData.isNotEmpty
                                        ? Colors.blue.shade50
                                        : Colors.white,
                                    border: Border.all(
                                      color: candidateData.isNotEmpty
                                          ? Colors.blue
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: formFields.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_box_outlined,
                                                size: 48,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Form elemanlarını buraya sürükleyin',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ReorderableListView.builder(
                                          padding: const EdgeInsets.all(16.0),
                                          itemCount: formFields.length,
                                          onReorder: (oldIndex, newIndex) {
                                            formFieldsNotifier.reorderFields(
                                                oldIndex, newIndex);
                                          },
                                          itemBuilder: (context, index) {
                                            final field = formFields[index];
                                            return _buildFormFieldItem(field,
                                                index, formFieldsNotifier);
                                          },
                                        ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      persistentFooterButtons: [
        // Alt buton grubu
        TextButton.icon(
          icon: const Icon(Icons.restart_alt),
          label: const Text('Sıfırla'),
          onPressed: () {
            _showResetConfirmationDialog();
          },
        ),
        const Spacer(),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('FORMU KAYDET'),
          onPressed: _isLoading ? null : _saveForm,
        ),
      ],
    );
  }

  // Gelişmiş ayarlar bölümü
  Widget _buildAdvancedSettings() {
    final formSettings = ref.watch(formSettingsProvider);
    final formSettingsNotifier = ref.watch(formSettingsProvider.notifier);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Form Ayarları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Ayarlar
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Anonim Yanıt'),
                  subtitle: const Text(
                      'Kullanıcı kimliği olmadan form doldurulabilir'),
                  value: formSettings.allowAnonymous,
                  onChanged: (value) {
                    formSettingsNotifier.update((state) => state.copyWith(
                          allowAnonymous: value,
                          // Anonim izin verilirse kimlik doğrulama gerektirme
                          requireAuth: value ? false : state.requireAuth,
                        ));
                  },
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  title: const Text('Yanıt Bildirimi'),
                  subtitle: const Text('Yeni yanıt geldiğinde bildirim gönder'),
                  value: formSettings.notifyOnSubmit,
                  onChanged: (value) {
                    formSettingsNotifier.update((state) => state.copyWith(
                          notifyOnSubmit: value,
                        ));
                  },
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Kimlik Doğrulama'),
                  subtitle: const Text('Form doldurmak için giriş zorunlu'),
                  value: formSettings.requireAuth,
                  onChanged: formSettings.allowAnonymous
                      ? null // Anonim izin verilmişse değiştirilemez
                      : (value) {
                          formSettingsNotifier.update((state) => state.copyWith(
                                requireAuth: value,
                              ));
                        },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Yanıt Limiti',
                      hintText: 'Maksimum yanıt sayısı',
                      border: OutlineInputBorder(),
                      helperText: 'Boş bırakılırsa limit yoktur',
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: formSettings.responseLimit?.toString(),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        formSettingsNotifier.update((state) => state.copyWith(
                              responseLimit: null,
                            ));
                      } else {
                        final limit = int.tryParse(value);
                        if (limit != null) {
                          formSettingsNotifier.update((state) => state.copyWith(
                                responseLimit: limit,
                              ));
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          // Geçerlilik süresi
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildExpirationDatePicker(formSettingsNotifier),
          ),
        ],
      ),
    );
  }

  // Geçerlilik süresi seçici
  Widget _buildExpirationDatePicker(StateController<FormSettings> notifier) {
    // Mevcut geçerlilik tarihine bağlı UI durumu
    final DateTime? currentExpiryDate = ref.watch(expiryDateProvider);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Geçerlilik Süresi: ${currentExpiryDate == null ? 'Süresiz' : '${currentExpiryDate.day}/${currentExpiryDate.month}/${currentExpiryDate.year}'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton(
          child:
              Text(currentExpiryDate == null ? 'Tarih Seç' : 'Tarihi Değiştir'),
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: currentExpiryDate ??
                  DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );

            if (picked != null) {
              ref.read(expiryDateProvider.notifier).state = picked;
            }
          },
        ),
        if (currentExpiryDate != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              ref.read(expiryDateProvider.notifier).state = null;
            },
            tooltip: 'Tarihi Kaldır',
          ),
      ],
    );
  }

  // Kullanılabilir form elemanları paneli
  Widget _buildAvailableFormFieldsPanel() {
    // Form elemanı grupları
    const fieldGroups = {
      'Metin Alanları': [FormFieldType.textField, FormFieldType.textArea],
      'Seçim Alanları': [
        FormFieldType.radioButton,
        FormFieldType.checkbox,
        FormFieldType.dropdown
      ],
      'Özel Alanlar': [
        FormFieldType.dateField,
        FormFieldType.fileUpload,
        FormFieldType.rating
      ],
      'Yerleşim Elemanları': [FormFieldType.section, FormFieldType.paragraph],
    };

    return Container(
      color: Colors.grey.shade50,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Form Elemanları',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(),
          ...fieldGroups.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ...entry.value.map((fieldType) {
                  return _buildDraggableFieldItem(fieldType);
                }),
                const Divider(),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Sürüklenebilir form elemanı
  Widget _buildDraggableFieldItem(FormFieldType fieldType) {
    final fieldInfo = getFieldTypeInfo(fieldType);

    return Draggable<FormFieldType>(
      // Önemli: data parametresi
      data: fieldType,

      // Sürükleme sırasında görünen widget
      feedback: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          width: 200,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(fieldInfo.icon, color: Colors.blue.shade800),
              const SizedBox(width: 16),
              Text(fieldInfo.label),
            ],
          ),
        ),
      ),

      // Sürükleme başladığında orijinal konumda görünen widget
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(fieldInfo.icon, color: Colors.grey),
              const SizedBox(width: 16),
              Text(fieldInfo.label, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),

      // Normal durumdaki widget
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(fieldInfo.icon, color: Colors.blue.shade800),
            const SizedBox(width: 16),
            Expanded(child: Text(fieldInfo.label)),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Form önizleme alanı

  // Düzenlenebilir form elemanı
  Widget _buildFormFieldItem(
      FormFieldx field, int index, FormFieldsNotifier formFieldsNotifier) {
    final fieldInfo = getFieldTypeInfo(field.type);

    return Card(
      key: ValueKey(field.id),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eleman başlığı ve eylemler
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(fieldInfo.icon, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  fieldInfo.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                if (field.type != FormFieldType.section &&
                    field.type != FormFieldType.paragraph)
                  Switch(
                    value: field.validation?.required ?? false,
                    onChanged: (value) {
                      formFieldsNotifier.updateFieldValidation(
                        index,
                        field.validation?.copyWith(required: value) ??
                            ValidationRule(required: value),
                      );
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                const SizedBox(width: 8),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Düzenle'),
                      ),
                      onTap: () {
                        // Gecikme ile gösterme (menü kapandıktan sonra)
                        Future.delayed(
                          const Duration(milliseconds: 50),
                          () => _showEditFieldDialog(
                              field, index, formFieldsNotifier),
                        );
                      },
                    ),
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Kopyala'),
                      ),
                      onTap: () {
                        formFieldsNotifier.duplicateField(index);
                      },
                    ),
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Sil', style: TextStyle(color: Colors.red)),
                      ),
                      onTap: () {
                        formFieldsNotifier.removeFormField(index);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Eleman içeriği önizleme
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etiket
                Text(
                  field.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                if (field.helperText != null &&
                    field.helperText!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    field.helperText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Alan tipine göre önizleme
                _buildFieldPreview(field),

                if (field.validation != null && field.validation!.required) ...[
                  const SizedBox(height: 4),
                  Text(
                    '* Bu alan zorunludur',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Form alanının önizlemesi
  Widget _buildFieldPreview(FormFieldx field) {
    switch (field.type) {
      case FormFieldType.textField:
        return TextFormField(
          enabled: false,
          decoration: InputDecoration(
            hintText: field.placeholder ?? 'Metin girin',
            border: const OutlineInputBorder(),
          ),
        );

      case FormFieldType.textArea:
        return TextFormField(
          enabled: false,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: field.placeholder ?? 'Uzun metin girin',
            border: const OutlineInputBorder(),
          ),
        );

      case FormFieldType.radioButton:
        return Column(
          children: field.options?.map((option) {
                return RadioListTile<String>(
                  title: Text(option.label),
                  value: option.value ?? option.label,
                  groupValue: null,
                  onChanged: null,
                  dense: true,
                );
              }).toList() ??
              [],
        );

      case FormFieldType.checkbox:
        return Column(
          children: field.options?.map((option) {
                return CheckboxListTile(
                  title: Text(option.label),
                  value: false,
                  onChanged: null,
                  dense: true,
                );
              }).toList() ??
              [],
        );

      case FormFieldType.dropdown:
        return DropdownButtonFormField<String>(
          items: field.options?.map((option) {
                return DropdownMenuItem<String>(
                  value: option.value ?? option.label,
                  child: Text(option.label),
                );
              }).toList() ??
              [],
          onChanged: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          hint: Text(field.placeholder ?? 'Seçim yapın'),
        );

      case FormFieldType.dateField:
        return TextFormField(
          enabled: false,
          decoration: const InputDecoration(
            hintText: 'GG/AA/YYYY',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
          ),
        );

      case FormFieldType.fileUpload:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.file_upload),
          label: Text(field.placeholder ?? 'Dosya Yükle'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 45),
          ),
        );

      case FormFieldType.rating:
        final maxRating = field.additionalProperties?['maxRating'] as int? ?? 5;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxRating, (index) {
            return const Icon(Icons.star_border, color: Colors.amber);
          }),
        );

      case FormFieldType.section:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Text(
            field.label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case FormFieldType.paragraph:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(field.label),
        );
    }
  }

  // Form alanı düzenleme dialog'u
  void _showEditFieldDialog(
      FormFieldx field, int index, FormFieldsNotifier formFieldsNotifier) {
    final TextEditingController labelController =
        TextEditingController(text: field.label);
    final TextEditingController placeholderController =
        TextEditingController(text: field.placeholder);
    final TextEditingController helperTextController =
        TextEditingController(text: field.helperText);

    // Seçenek düzenleme kontrolcüleri
    final List<TextEditingController> optionControllers = [];
    if (field.options != null) {
      for (var option in field.options!) {
        optionControllers.add(TextEditingController(text: option.label));
      }
    }

    // Doğrulama kuralları
    ValidationRule validation = field.validation ?? ValidationRule();

    // Özel alanlar
    Map<String, dynamic> additionalProps =
        field.additionalProperties?.cast<String, dynamic>() ?? {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('${getFieldTypeInfo(field.type).label} Düzenle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etiket alanı
                  TextFormField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Soru/Etiket',
                      hintText: 'Kullanıcıya gösterilecek metin',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Yer tutucu metin (bazı alan tipleri için)
                  if (field.type == FormFieldType.textField ||
                      field.type == FormFieldType.textArea ||
                      field.type == FormFieldType.dropdown ||
                      field.type == FormFieldType.fileUpload)
                    Column(
                      children: [
                        TextFormField(
                          controller: placeholderController,
                          decoration: const InputDecoration(
                            labelText: 'Yer Tutucu Metin',
                            hintText: 'Örnek: Adınızı girin',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Yardımcı metin
                  TextFormField(
                    controller: helperTextController,
                    decoration: const InputDecoration(
                      labelText: 'Yardımcı Metin',
                      hintText: 'Kullanıcıya yönelik açıklama',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Seçenekli alan tipleri için seçenek düzenleme
                  if (_fieldTypeRequiresOptions(field.type)) ...[
                    const Text(
                      'Seçenekler',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(optionControllers.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: optionControllers[i],
                                decoration: InputDecoration(
                                  labelText: 'Seçenek ${i + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  optionControllers.removeAt(i);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Seçenek Ekle'),
                      onPressed: () {
                        setState(() {
                          optionControllers.add(TextEditingController());
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Özel alanlar için ek ayarlar
                  if (field.type == FormFieldType.rating) ...[
                    const Text(
                      'Derecelendirme Ayarları',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Maksimum Yıldız Sayısı',
                        border: OutlineInputBorder(),
                      ),
                      value: additionalProps['maxRating'] as int? ?? 5,
                      items: [3, 4, 5, 10].map((value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value yıldız'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          additionalProps['maxRating'] = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Doğrulama kuralları
                  if (field.type != FormFieldType.section &&
                      field.type != FormFieldType.paragraph) ...[
                    const Text(
                      'Doğrulama Kuralları',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Zorunlu Alan'),
                      subtitle:
                          const Text('Kullanıcı bu alanı doldurmak zorundadır'),
                      value: validation.required,
                      onChanged: (value) {
                        setState(() {
                          validation = validation.copyWith(
                            required: value ?? false,
                          );
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (field.type == FormFieldType.textField ||
                        field.type == FormFieldType.textArea) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Minimum Uzunluk',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: validation.minLength?.toString(),
                              onChanged: (value) {
                                setState(() {
                                  validation = validation.copyWith(
                                    minLength: value.isEmpty
                                        ? null
                                        : int.tryParse(value),
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Maksimum Uzunluk',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: validation.maxLength?.toString(),
                              onChanged: (value) {
                                setState(() {
                                  validation = validation.copyWith(
                                    maxLength: value.isEmpty
                                        ? null
                                        : int.tryParse(value),
                                  );
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Güncellenmiş alanı oluştur
                  final updatedField = FormFieldx(
                    id: field.id, // Mevcut ID korunur
                    type: field.type,
                    label: labelController.text,
                    placeholder: placeholderController.text.isEmpty
                        ? null
                        : placeholderController.text,
                    helperText: helperTextController.text.isEmpty
                        ? null
                        : helperTextController.text,
                    validation: validation,
                    additionalProperties:
                        additionalProps.isEmpty ? null : additionalProps,
                    options: optionControllers.isNotEmpty
                        ? optionControllers
                            .where((controller) => controller.text.isNotEmpty)
                            .map((controller) =>
                                FieldOption(label: controller.text))
                            .toList()
                        : null,
                  );

                  // Alanı güncelle
                  formFieldsNotifier.updateFormField(index, updatedField);
                  Navigator.pop(context);
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Formu sıfırlama onay dialog'u
  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Formu Sıfırla'),
        content: const Text(
            'Tüm form elemanları silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Formu sıfırla
              ref.read(formFieldsProvider.notifier).clearFields();
              ref.read(formSettingsProvider.notifier).state = FormSettings();
              ref.read(expiryDateProvider.notifier).state = null;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  // Formu kaydet
  void _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen form başlığını girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final formFields = ref.read(formFieldsProvider);
    if (formFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir form elemanı ekleyin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Form verilerini hazırla
      final formSettings = ref.read(formSettingsProvider);
      final expiryDate = ref.read(expiryDateProvider);

      final form = DynamicForm(
        title: _formTitleController.text,
        description:
            _formDescController.text.isEmpty ? null : _formDescController.text,
        projectId: widget.projectId,
        fields: formFields,
        expiresAt: expiryDate,
        settings: formSettings,
      );

      // Form servisi ile kaydet
      final formService = ref.read(formServiceProvider);
      final formId = await formService.createForm(form);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form başarıyla kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );

        // Form önizleme sayfasına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FormPreviewScreen(formId: formId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Form kaydedilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Yardımcı metodlar
  bool _fieldTypeRequiresOptions(FormFieldType type) {
    return type == FormFieldType.radioButton ||
        type == FormFieldType.checkbox ||
        type == FormFieldType.dropdown;
  }
}

// Form alanı tipi bilgileri
class FormFieldTypeInfo {
  final String label;
  final IconData icon;

  const FormFieldTypeInfo({required this.label, required this.icon});
}

FormFieldTypeInfo getFieldTypeInfo(FormFieldType type) {
  switch (type) {
    case FormFieldType.textField:
      return const FormFieldTypeInfo(
        label: 'Metin Kutusu',
        icon: Icons.text_fields,
      );
    case FormFieldType.textArea:
      return const FormFieldTypeInfo(
        label: 'Çok Satırlı Metin',
        icon: Icons.text_snippet,
      );
    case FormFieldType.radioButton:
      return const FormFieldTypeInfo(
        label: 'Tekli Seçim',
        icon: Icons.radio_button_checked,
      );
    case FormFieldType.checkbox:
      return const FormFieldTypeInfo(
        label: 'Çoklu Seçim',
        icon: Icons.check_box,
      );
    case FormFieldType.dropdown:
      return const FormFieldTypeInfo(
        label: 'Açılır Liste',
        icon: Icons.arrow_drop_down_circle,
      );
    case FormFieldType.dateField:
      return const FormFieldTypeInfo(
        label: 'Tarih Seçici',
        icon: Icons.calendar_today,
      );
    case FormFieldType.fileUpload:
      return const FormFieldTypeInfo(
        label: 'Dosya Yükleme',
        icon: Icons.attach_file,
      );
    case FormFieldType.rating:
      return const FormFieldTypeInfo(
        label: 'Derecelendirme',
        icon: Icons.star,
      );
    case FormFieldType.section:
      return const FormFieldTypeInfo(
        label: 'Bölüm Başlığı',
        icon: Icons.title,
      );
    case FormFieldType.paragraph:
      return const FormFieldTypeInfo(
        label: 'Bilgi Metni',
        icon: Icons.article,
      );
  }
}

/// Form önizleme ekranı
class FormPreviewScreen extends ConsumerWidget {
  final String formId;

  const FormPreviewScreen({
    super.key,
    required this.formId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formAsyncValue = ref.watch(formProvider(formId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Önizleme'),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.share),
            tooltip: 'Formu Paylaş',
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.qr_code),
                  title: Text('QR Kodu Göster'),
                ),
                onTap: () {
                  // Gecikmeli çağrı (menü kapandıktan sonra)
                  Future.delayed(
                    const Duration(milliseconds: 50),
                    () => _showQrCodeDialog(context, ref, formId),
                  );
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.link),
                  title: Text('Bağlantıyı Kopyala'),
                ),
                onTap: () => _copyFormLink(context, ref, formId),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.email),
                  title: Text('E-posta ile Gönder'),
                ),
                onTap: () => _shareViaEmail(context, ref, formId),
              ),
            ],
          ),
        ],
      ),
      body: formAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Hata: $error'),
        ),
        data: (form) {
          if (form == null) {
            return const Center(
              child: Text('Form bulunamadı'),
            );
          }

          return FormRenderer(form: form);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Yanıtları görüntüleme ekranına git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormResponsesScreen(formId: formId),
            ),
          );
        },
        icon: const Icon(Icons.analytics),
        label: const Text('Yanıtları Görüntüle'),
      ),
    );
  }

  // QR kod dialog'u
  static void _showQrCodeDialog(
      BuildContext context, WidgetRef ref, String formId) {
    final formAsyncValue = ref.read(formProvider(formId));

    if (formAsyncValue.value == null) return;

    final form = formAsyncValue.value!;
    final qrUrl = form.qrCodeUrl;

    if (qrUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR kod bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(form.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aşağıdaki QR kodu taratarak formu doldurun',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Image.network(
              qrUrl,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            if (form.formUrl != null)
              Text(
                form.formUrl!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_alt),
            label: const Text('QR Kodu İndir'),
            onPressed: () => _downloadQrCode(context, qrUrl, form.title),
          ),
        ],
      ),
    );
  }

  // Form bağlantısını kopyala
  static void _copyFormLink(
      BuildContext context, WidgetRef ref, String formId) {
    final formAsyncValue = ref.read(formProvider(formId));

    if (formAsyncValue.value == null) return;

    final formUrl = formAsyncValue.value!.formUrl;

    if (formUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form bağlantısı bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: formUrl)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bağlantı panoya kopyalandı'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  // E-posta ile paylaş
  static void _shareViaEmail(
      BuildContext context, WidgetRef ref, String formId) {
    final formAsyncValue = ref.read(formProvider(formId));

    if (formAsyncValue.value == null) return;

    final form = formAsyncValue.value!;
    final formUrl = form.formUrl;

    if (formUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form bağlantısı bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // E-posta gönderme dialog'u
    TextEditingController emailController = TextEditingController();
    TextEditingController subjectController = TextEditingController(
      text: 'Form Doldurma Daveti: ${form.title}',
    );
    TextEditingController messageController = TextEditingController(
      text: '''Merhaba,

Lütfen aşağıdaki bağlantıyı kullanarak formu doldurun:

${form.title}
$formUrl

Saygılarımızla,
ProSmart Yönetim Sistemi
''',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('E-posta ile Gönder'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Alıcı E-posta Adresleri',
                  hintText: 'ornek@email.com, ornek2@email.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Konu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Mesaj',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                minLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Gönder'),
            onPressed: () {
              if (emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen en az bir e-posta adresi girin'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // E-posta gönderme işlemi
              final emails =
                  emailController.text.split(',').map((e) => e.trim()).toList();
              _sendFormEmailInvitation(
                context,
                emails,
                subjectController.text,
                messageController.text,
              );

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // QR kodu indir
  static void _downloadQrCode(
      BuildContext context, String qrUrl, String formTitle) {
    // QR kod indirme işlemi
    // Not: Web ve mobil platformlar için farklı işlemler gerekebilir
    // Web için window.open, mobil için path_provider ve download_manager kullanılabilir

    // Basit bildirim göster
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR kod indiriliyor...'),
      ),
    );
  }

  // E-posta ile form davetiyesi gönder
  static void _sendFormEmailInvitation(BuildContext context,
      List<String> emails, String subject, String message) {
    // Firebase Functions veya başka bir servis ile e-posta gönderimi yapılabilir

    // Başarılı bildirim göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${emails.length} alıcıya davet gönderildi'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Form görüntüleyici widget
class FormRenderer extends ConsumerStatefulWidget {
  final DynamicForm form;
  final bool isReadOnly;

  const FormRenderer({
    super.key,
    required this.form,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<FormRenderer> createState() => _FormRendererState();
}

class _FormRendererState extends ConsumerState<FormRenderer> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form başlığı
            Text(
              widget.form.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (widget.form.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.form.description!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Form alanları
            ...widget.form.fields.map((field) => _buildFormField(field)),

            if (!widget.isReadOnly) ...[
              const SizedBox(height: 32),

              // Gönder butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('GÖNDER'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Form alanı oluşturucu
  Widget _buildFormField(FormFieldx field) {
    final padding = const EdgeInsets.only(bottom: 24.0);

    switch (field.type) {
      case FormFieldType.textField:
        return Padding(
          padding: padding,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.placeholder,
              helperText: field.helperText,
              border: const OutlineInputBorder(),
            ),
            enabled: !widget.isReadOnly,
            validator: (value) {
              if (field.validation?.required == true &&
                  (value == null || value.isEmpty)) {
                return 'Bu alan zorunludur';
              }
              if (field.validation?.minLength != null &&
                  value != null &&
                  value.length < field.validation!.minLength!) {
                return 'En az ${field.validation!.minLength} karakter giriniz';
              }
              if (field.validation?.maxLength != null &&
                  value != null &&
                  value.length > field.validation!.maxLength!) {
                return 'En fazla ${field.validation!.maxLength} karakter giriniz';
              }
              if (field.validation?.pattern != null &&
                  value != null &&
                  !RegExp(field.validation!.pattern!).hasMatch(value)) {
                return field.validation?.errorMessage ?? 'Geçersiz format';
              }
              return null;
            },
            onSaved: (value) {
              _formData[field.id] = value;
            },
          ),
        );

      case FormFieldType.textArea:
        return Padding(
          padding: padding,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.placeholder,
              helperText: field.helperText,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            enabled: !widget.isReadOnly,
            maxLines: 5,
            minLines: 3,
            validator: (value) {
              if (field.validation?.required == true &&
                  (value == null || value.isEmpty)) {
                return 'Bu alan zorunludur';
              }
              if (field.validation?.minLength != null &&
                  value != null &&
                  value.length < field.validation!.minLength!) {
                return 'En az ${field.validation!.minLength} karakter giriniz';
              }
              if (field.validation?.maxLength != null &&
                  value != null &&
                  value.length > field.validation!.maxLength!) {
                return 'En fazla ${field.validation!.maxLength} karakter giriniz';
              }
              return null;
            },
            onSaved: (value) {
              _formData[field.id] = value;
            },
          ),
        );

      case FormFieldType.radioButton:
        return Padding(
          padding: padding,
          child: FormField<String>(
            initialValue: null,
            validator: (value) {
              if (field.validation?.required == true && value == null) {
                return 'Lütfen bir seçim yapın';
              }
              return null;
            },
            builder: (FormFieldState<String> state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (field.helperText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      field.helperText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ...field.options?.map((option) {
                        return RadioListTile<String>(
                          title: Text(option.label),
                          value: option.value ?? option.label,
                          groupValue: state.value,
                          onChanged: widget.isReadOnly
                              ? null
                              : (value) {
                                  state.didChange(value);
                                  _formData[field.id] = value;
                                },
                          dense: true,
                        );
                      }).toList() ??
                      [],
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Text(
                        state.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
            onSaved: (value) {
              _formData[field.id] = value;
            },
          ),
        );

      case FormFieldType.checkbox:
        return Padding(
          padding: padding,
          child: FormField<List<String>>(
            initialValue: [],
            validator: (value) {
              if (field.validation?.required == true &&
                  (value == null || value.isEmpty)) {
                return 'Lütfen en az bir seçim yapın';
              }
              return null;
            },
            builder: (FormFieldState<List<String>> state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (field.helperText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      field.helperText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ...field.options?.map((option) {
                        final isChecked =
                            state.value!.contains(option.value ?? option.label);
                        return CheckboxListTile(
                          title: Text(option.label),
                          value: isChecked,
                          onChanged: widget.isReadOnly
                              ? null
                              : (checked) {
                                  final newValue =
                                      List<String>.from(state.value!);
                                  final optionValue =
                                      option.value ?? option.label;

                                  if (checked == true) {
                                    newValue.add(optionValue);
                                  } else {
                                    newValue.remove(optionValue);
                                  }

                                  state.didChange(newValue);
                                  _formData[field.id] = newValue;
                                },
                          dense: true,
                        );
                      }).toList() ??
                      [],
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Text(
                        state.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
            onSaved: (value) {
              _formData[field.id] = value;
            },
          ),
        );

      case FormFieldType.dropdown:
        return Padding(
          padding: padding,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: field.label,
              helperText: field.helperText,
              border: const OutlineInputBorder(),
            ),
            hint: Text(field.placeholder ?? 'Seçiniz'),
            items: field.options?.map((option) {
                  return DropdownMenuItem<String>(
                    value: option.value ?? option.label,
                    child: Text(option.label),
                  );
                }).toList() ??
                [],
            onChanged: widget.isReadOnly
                ? null
                : (value) {
                    _formData[field.id] = value;
                  },
            validator: (value) {
              if (field.validation?.required == true && value == null) {
                return 'Lütfen bir seçim yapın';
              }
              return null;
            },
            onSaved: (value) {
              _formData[field.id] = value;
            },
          ),
        );

      case FormFieldType.dateField:
        return Padding(
          padding: padding,
          child: FormField<DateTime>(
            initialValue: null,
            validator: (value) {
              if (field.validation?.required == true && value == null) {
                return 'Lütfen bir tarih seçin';
              }
              return null;
            },
            builder: (FormFieldState<DateTime> state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (field.helperText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      field.helperText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: widget.isReadOnly
                        ? null
                        : () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );

                            if (picked != null) {
                              state.didChange(picked);
                              _formData[field.id] = picked.toIso8601String();
                            }
                          },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                        hintText: field.placeholder ?? 'Tarih seçin',
                        errorText: state.hasError ? state.errorText : null,
                      ),
                      child: Text(
                        state.value == null
                            ? field.placeholder ?? 'Tarih seçin'
                            : '${state.value!.day}/${state.value!.month}/${state.value!.year}',
                        style: TextStyle(
                          color: state.value == null
                              ? Colors.grey.shade600
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            onSaved: (value) {
              if (value != null) {
                _formData[field.id] = value.toIso8601String();
              }
            },
          ),
        );

      case FormFieldType.fileUpload:
        return Padding(
          padding: padding,
          child: FormField<List<PlatformFile>>(
            initialValue: [],
            validator: (files) {
              if (field.validation?.required == true &&
                  (files == null || files.isEmpty)) {
                return 'Lütfen dosya yükleyin';
              }
              return null;
            },
            builder: (FormFieldState<List<PlatformFile>> state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (field.helperText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      field.helperText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (state.value!.isEmpty)
                    OutlinedButton.icon(
                      onPressed: widget.isReadOnly
                          ? null
                          : () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.any,
                                allowMultiple: true,
                              );

                              if (result != null) {
                                state.didChange(result.files);
                                // Dosya referanslarını sakla
                                _formData[field.id] = result.files;
                              }
                            },
                      icon: const Icon(Icons.attach_file),
                      label: Text(field.placeholder ?? 'Dosya Seç'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...state.value!.map((file) {
                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(file.name),
                            subtitle: Text(
                              '${(file.size / 1024).toStringAsFixed(1)} KB',
                            ),
                            trailing: widget.isReadOnly
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      final newFiles =
                                          List<PlatformFile>.from(state.value!);
                                      newFiles.remove(file);
                                      state.didChange(newFiles);
                                      _formData[field.id] = newFiles;
                                    },
                                  ),
                            dense: true,
                          );
                        }),
                        if (!widget.isReadOnly) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Dosya Ekle'),
                            onPressed: () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.any,
                                allowMultiple: true,
                              );

                              if (result != null) {
                                final newFiles =
                                    List<PlatformFile>.from(state.value!);
                                newFiles.addAll(result.files);
                                state.didChange(newFiles);
                                _formData[field.id] = newFiles;
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Text(
                        state.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
            onSaved: (value) {
              _formData[field.id] = value;
            },
          ),
        );

      case FormFieldType.rating:
        final maxRating = field.additionalProperties?['maxRating'] as int? ?? 5;

        return Padding(
          padding: padding,
          child: FormField<int>(
            initialValue: 0,
            validator: (value) {
              if (field.validation?.required == true &&
                  (value == null || value == 0)) {
                return 'Lütfen bir derecelendirme seçin';
              }
              return null;
            },
            builder: (FormFieldState<int> state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (field.helperText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      field.helperText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(maxRating, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          state.value! >= starValue
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: widget.isReadOnly
                            ? null
                            : () {
                                state.didChange(starValue);
                                _formData[field.id] = starValue;
                              },
                        splashRadius: 20,
                      );
                    }),
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Text(
                        state.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
            onSaved: (value) {
              _formData[field.id] = value;
            },
          ),
        );

      case FormFieldType.section:
        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (field.helperText != null && field.helperText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  field.helperText!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        );

      case FormFieldType.paragraph:
        return Padding(
          padding: padding,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                if (field.helperText != null &&
                    field.helperText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    field.helperText!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }

  // Form gönderimi
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Doğrulama hatası varsa, sayfayı kaydır
      return;
    }

    // Form verilerini topla
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Dosya yüklemeleri varsa önce onları işle
      final Map<String, dynamic> processedData = await _processFormData();

      // Form yanıtını oluştur
      final formResponse = FormResponse(
        formId: widget.form.id,
        data: processedData,
        submittedBy: null, // Kullanıcı kimliği burada eklenebilir
      );

      // Form servisini kullanarak yanıtı gönder
      final formService = ref.read(formServiceProvider);
      await formService.submitFormResponse(formResponse);

      if (mounted) {
        // Başarı mesajı göster
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Teşekkürler!'),
            content: const Text('Form yanıtınız başarıyla gönderildi.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Dialog'u kapat
                  Navigator.pop(context); // Form sayfasını kapat
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Form gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Form verilerini işleme (dosya yüklemeleri dahil)
  Future<Map<String, dynamic>> _processFormData() async {
    final Map<String, dynamic> processedData = {};

    for (var entry in _formData.entries) {
      final fieldId = entry.key;
      final value = entry.value;

      // Dosya yüklemeleri için
      if (value is List<PlatformFile>) {
        if (value.isNotEmpty) {
          final List<Uint8List> fileBytes = [];

          for (var file in value) {
            if (kIsWeb) {
              // Web için
              fileBytes.add(file.bytes!);
            } else {
              // Mobil için
              final bytes = await File(file.path!).readAsBytes();
              fileBytes.add(bytes);
            }
          }

          if (fileBytes.isNotEmpty) {
            // Dosyaları Firebase Storage'a yükle
            final formService = ref.read(formServiceProvider);
            final urls = await formService.uploadFormAttachments(
              widget.form.id,
              const Uuid().v4(), // Geçici responseId
              fileBytes,
            );

            // URL'leri data'ya ekle
            processedData[fieldId] = urls;
          }
        }
      } else {
        // Diğer tipleri doğrudan ekle
        processedData[fieldId] = value;
      }
    }

    return processedData;
  }
}

/// Form yanıtları ekranı
class FormResponsesScreen extends ConsumerStatefulWidget {
  final String formId;

  const FormResponsesScreen({
    super.key,
    required this.formId,
  });

  @override
  ConsumerState<FormResponsesScreen> createState() =>
      _FormResponsesScreenState();
}

class _FormResponsesScreenState extends ConsumerState<FormResponsesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formAsyncValue = ref.watch(formProvider(widget.formId));
    final responsesAsyncValue = ref.watch(formResponsesProvider(widget.formId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Yanıtları'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Özet'),
            Tab(text: 'Tüm Yanıtlar'),
            Tab(text: 'Grafikler'),
          ],
        ),
      ),
      body: formAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Form yüklenirken hata: $error'),
        ),
        data: (form) {
          if (form == null) {
            return const Center(
              child: Text('Form bulunamadı'),
            );
          }

          return responsesAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Yanıtlar yüklenirken hata: $error'),
            ),
            data: (responses) {
              if (responses.isEmpty) {
                return const Center(
                  child: Text('Henüz yanıt bulunmamaktadır'),
                );
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  // Özet Tab
                  _buildSummaryTab(form, responses),

                  // Tüm Yanıtlar Tab
                  _buildAllResponsesTab(form, responses),

                  // Grafikler Tab
                  _buildChartsTab(form, responses),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _exportResponses(widget.formId),
        icon: const Icon(Icons.download),
        label: const Text('Dışa Aktar'),
      ),
    );
  }

  // Özet sekmesi
  Widget _buildSummaryTab(DynamicForm form, List<FormResponse> responses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet kart
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    form.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Temel istatistikler
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Toplam Yanıt',
                          '${responses.length}',
                          Icons.question_answer,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Son Yanıt',
                          _formatDateTime(responses.first.submittedAt),
                          Icons.access_time,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Tamamlanma Oranı',
                          form.settings.responseLimit != null
                              ? '${(responses.length / form.settings.responseLimit! * 100).toStringAsFixed(1)}%'
                              : 'Limitsiz',
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Durum',
                          _getFormStatus(form),
                          _getFormStatusIcon(form),
                          _getFormStatusColor(form),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Hızlı yanıt analizi
          const Text(
            'Hızlı Yanıt Analizi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...form.fields.where(_isAnalyzableField).map((field) {
            return _buildFieldSummary(field, responses);
          }),
        ],
      ),
    );
  }

  // Basit istatistik kartı
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Alan özeti widget'ı
  Widget _buildFieldSummary(FormFieldx field, List<FormResponse> responses) {
    // Alan için yanıtları topla
    final fieldResponses = responses
        .where((r) => r.data.containsKey(field.id))
        .map((r) => r.data[field.id])
        .where((r) => r != null)
        .toList();

    if (fieldResponses.isEmpty) {
      return const SizedBox.shrink();
    }

    switch (field.type) {
      case FormFieldType.radioButton:
      case FormFieldType.dropdown:
        return _buildChoiceFieldSummary(field, fieldResponses);

      case FormFieldType.checkbox:
        return _buildMultiChoiceFieldSummary(field, fieldResponses);

      case FormFieldType.rating:
        return _buildRatingFieldSummary(field, fieldResponses);

      default:
        return const SizedBox.shrink();
    }
  }

  // Tekli seçim alanı özeti
  Widget _buildChoiceFieldSummary(FormFieldx field, List<dynamic> responses) {
    final optionCounts = <String, int>{};

    // Her seçenek için yanıt sayısını hesapla
    for (var response in responses) {
      if (response != null) {
        final option = response.toString();
        optionCounts[option] = (optionCounts[option] ?? 0) + 1;
      }
    }

    final totalResponses = responses.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ...optionCounts.entries.map((entry) {
              final option = entry.key;
              final count = entry.value;
              final percentage =
                  (count / totalResponses * 100).toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(option),
                        ),
                        Text(
                          '$count ($percentage%)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: count / totalResponses,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Çoklu seçim alanı özeti
  Widget _buildMultiChoiceFieldSummary(
      FormFieldx field, List<dynamic> responses) {
    final optionCounts = <String, int>{};

    // Her seçenek için yanıt sayısını hesapla
    for (var response in responses) {
      if (response is List) {
        for (var option in response) {
          optionCounts[option.toString()] =
              (optionCounts[option.toString()] ?? 0) + 1;
        }
      }
    }

    final totalResponses = responses.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ...optionCounts.entries.map((entry) {
              final option = entry.key;
              final count = entry.value;
              final percentage =
                  (count / totalResponses * 100).toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(option),
                        ),
                        Text(
                          '$count ($percentage%)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: count / totalResponses,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Derecelendirme alanı özeti
  Widget _buildRatingFieldSummary(FormFieldx field, List<dynamic> responses) {
    int total = 0;
    int count = 0;
    final Map<int, int> ratingCounts = {};
    final maxRating = field.additionalProperties?['maxRating'] as int? ?? 5;

    // Derecelendirme verilerini topla
    for (var response in responses) {
      if (response is int) {
        total += response;
        count++;
        ratingCounts[response] = (ratingCounts[response] ?? 0) + 1;
      }
    }

    final average = count > 0 ? total / count : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // Ortalama derecelendirme
            Row(
              children: [
                const Text(
                  'Ortalama:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                ...List.generate(maxRating, (index) {
                  final starValue = index + 1;
                  return Icon(
                    starValue <= average.round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 24,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  average.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Derecelendirme dağılımı
            ...List.generate(maxRating, (index) {
              final rating = maxRating - index;
              final ratingCount = ratingCounts[rating] ?? 0;
              final percentage = count > 0
                  ? (ratingCount / count * 100).toStringAsFixed(1)
                  : '0.0';

              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$rating',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: count > 0 ? ratingCount / count : 0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                        minHeight: 8,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        ' $ratingCount ($percentage%)',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Tüm yanıtlar sekmesi
  Widget _buildAllResponsesTab(DynamicForm form, List<FormResponse> responses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: responses.length,
      itemBuilder: (context, index) {
        final response = responses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              'Yanıt #${responses.length - index}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Gönderilme: ${_formatDateTime(response.submittedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: form.fields.map((field) {
                    // Form elemanı tipine göre yanıt görüntüleme
                    return _buildResponseItem(field, response.data[field.id]);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Yanıt öğesi widget'ı
  Widget _buildResponseItem(FormFieldx field, dynamic value) {
    if (field.type == FormFieldType.section ||
        field.type == FormFieldType.paragraph) {
      return const SizedBox.shrink();
    }

    // Yanıt yok ise
    if (value == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Yanıt verilmedi',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Yanıt tipine göre görüntüleme
    Widget responseWidget;

    switch (field.type) {
      case FormFieldType.textField:
      case FormFieldType.textArea:
        responseWidget = Text(value.toString());
        break;

      case FormFieldType.radioButton:
      case FormFieldType.dropdown:
        responseWidget = Text(value.toString());
        break;

      case FormFieldType.checkbox:
        if (value is List) {
          responseWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: value
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 16),
                          const SizedBox(width: 8),
                          Text(item.toString()),
                        ],
                      ),
                    ))
                .toList(),
          );
        } else {
          responseWidget = Text(value.toString());
        }
        break;

      case FormFieldType.dateField:
        try {
          final date = DateTime.parse(value.toString());
          responseWidget = Text('${date.day}/${date.month}/${date.year}');
        } catch (e) {
          responseWidget = Text(value.toString());
        }
        break;

      case FormFieldType.fileUpload:
        if (value is List) {
          responseWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...value.map((url) => InkWell(
                    onTap: () => _openUrl(url.toString()),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(url.toString()),
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _extractFileName(url.toString()),
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        } else {
          responseWidget = Text(value.toString());
        }
        break;

      case FormFieldType.rating:
        final rating = int.tryParse(value.toString()) ?? 0;
        responseWidget = Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 16,
            );
          }),
        );
        break;

      default:
        responseWidget = Text(value.toString());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          responseWidget,
        ],
      ),
    );
  }

  // Grafikler sekmesi
  Widget _buildChartsTab(DynamicForm form, List<FormResponse> responses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yanıt zaman çizelgesi grafiği
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yanıt Zaman Çizelgesi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: _buildResponseTimelineChart(responses),
                  ),
                ],
              ),
            ),
          ),

          // Anket soruları için grafikler
          ...form.fields
              .where(_isChartableField)
              .map((field) => _buildFieldChart(field, responses)),
        ],
      ),
    );
  }

  // Yanıt zaman çizelgesi grafiği
  Widget _buildResponseTimelineChart(List<FormResponse> responses) {
    // Yanıtları gün bazında gruplama
    final Map<DateTime, int> dailyResponseCounts = {};

    for (var response in responses) {
      final date = DateTime(
        response.submittedAt.year,
        response.submittedAt.month,
        response.submittedAt.day,
      );

      dailyResponseCounts[date] = (dailyResponseCounts[date] ?? 0) + 1;
    }

    // Tarihleri sırala
    final sortedDates = dailyResponseCounts.keys.toList()..sort();

    // Boş günleri doldur
    if (sortedDates.length > 1) {
      final firstDate = sortedDates.first;
      final lastDate = sortedDates.last;

      for (int i = 0; i <= lastDate.difference(firstDate).inDays; i++) {
        final date = firstDate.add(Duration(days: i));
        dailyResponseCounts[date] ??= 0;
      }
    }

    // Tüm tarihleri tekrar sırala
    final allSortedDates = dailyResponseCounts.keys.toList()..sort();

    // Grafik verileri oluştur
    final List<FlSpot> spots = [];
    for (int i = 0; i < allSortedDates.length; i++) {
      final date = allSortedDates[i];
      final count = dailyResponseCounts[date]!;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < allSortedDates.length) {
                  final date = allSortedDates[value.toInt()];
                  if (value.toInt() % 3 == 0) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade400),
        ),
        minX: 0,
        maxX: (allSortedDates.length - 1).toDouble(),
        minY: 0,
        maxY: dailyResponseCounts.values
                .fold<int>(0, (max, value) => value > max ? value : max) +
            1.0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  // Alan grafiği oluştur
  Widget _buildFieldChart(FormFieldx field, List<FormResponse> responses) {
    // Alan için yanıtları topla
    final fieldResponses = responses
        .where((r) => r.data.containsKey(field.id))
        .map((r) => r.data[field.id])
        .where((r) => r != null)
        .toList();

    if (fieldResponses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _buildChartForFieldType(field, fieldResponses),
            ),
          ],
        ),
      ),
    );
  }

  // Alan tipine göre grafik oluştur
  Widget _buildChartForFieldType(FormFieldx field, List<dynamic> responses) {
    switch (field.type) {
      case FormFieldType.radioButton:
      case FormFieldType.dropdown:
        return _buildPieChartForChoiceField(field, responses);

      case FormFieldType.checkbox:
        return _buildBarChartForMultiChoiceField(field, responses);

      case FormFieldType.rating:
        return _buildBarChartForRatingField(field, responses);

      default:
        return const Center(
          child: Text('Bu alan tipi için grafik oluşturulamıyor'),
        );
    }
  }

  // Seçim alanı için pasta grafiği
  Widget _buildPieChartForChoiceField(
      FormFieldx field, List<dynamic> responses) {
    final optionCounts = <String, int>{};

    // Her seçenek için yanıt sayısını hesapla
    for (var response in responses) {
      if (response != null) {
        final option = response.toString();
        optionCounts[option] = (optionCounts[option] ?? 0) + 1;
      }
    }

    // Pasta grafiği dilimleri oluştur
    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];

    int colorIndex = 0;
    optionCounts.forEach((option, count) {
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: count.toDouble(),
          title: '$count',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Row(
      children: [
        // Pasta grafiği
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),

        // Açıklama
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...optionCounts.entries.map((entry) {
                final option = entry.key;
                final count = entry.value;
                final percentage =
                    (count / responses.length * 100).toStringAsFixed(1);
                final color = colors[
                    optionCounts.keys.toList().indexOf(option) % colors.length];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        '$count ($percentage%)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // Çoklu seçim alanı için çubuk grafiği
  Widget _buildBarChartForMultiChoiceField(
      FormFieldx field, List<dynamic> responses) {
    final optionCounts = <String, int>{};

    // Her seçenek için yanıt sayısını hesapla
    for (var response in responses) {
      if (response is List) {
        for (var option in response) {
          optionCounts[option.toString()] =
              (optionCounts[option.toString()] ?? 0) + 1;
        }
      }
    }

    // Çubuk grafiği verileri
    final barGroups = <BarChartGroupData>[];
    final maxY = optionCounts.values
            .fold<int>(0, (max, value) => value > max ? value : max) +
        1.0;
    final labels = optionCounts.keys.toList();

    for (int i = 0; i < labels.length; i++) {
      final option = labels[i];
      final count = optionCounts[option]!;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Colors.blue,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _shortenLabel(labels[value.toInt()]),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  // Derecelendirme alanı için çubuk grafiği
  Widget _buildBarChartForRatingField(
      FormFieldx field, List<dynamic> responses) {
    final ratingCounts = <int, int>{};
    final maxRating = field.additionalProperties?['maxRating'] as int? ?? 5;

    // Her derecelendirme için sayım yap
    for (int i = 1; i <= maxRating; i++) {
      ratingCounts[i] = 0;
    }

    for (var response in responses) {
      if (response is int && response >= 1 && response <= maxRating) {
        ratingCounts[response] = (ratingCounts[response] ?? 0) + 1;
      }
    }

    // Çubuk grafiği verileri
    final barGroups = <BarChartGroupData>[];
    final maxY = ratingCounts.values
            .fold<int>(0, (max, value) => value > max ? value : max) +
        1.0;

    for (int i = 1; i <= maxRating; i++) {
      final count = ratingCounts[i]!;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Colors.amber,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final rating = value.toInt();
                if (rating >= 1 && rating <= maxRating) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$rating',
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.star, size: 12, color: Colors.amber),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  // Yanıtları dışa aktar
  void _exportResponses(String formId) async {
    try {
      final form = ref.read(formProvider(formId)).value;
      final responses = ref.read(formResponsesProvider(formId)).value;

      if (form == null || responses == null) {
        return;
      }

      // Dışa aktarma seçenekleri dialog'u
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Yanıtları Dışa Aktar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Excel Olarak Aktar'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsExcel(form, responses);
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('CSV Olarak Aktar'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsCsv(form, responses);
                },
              ),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('PDF Raporu Oluştur'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsPdf(form, responses);
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dışa aktarma hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Excel olarak dışa aktar
  void _exportAsExcel(DynamicForm form, List<FormResponse> responses) {
    // Excel dışa aktarma işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Excel dosyası oluşturuluyor...'),
      ),
    );

    // Gerçek uygulamada excel kütüphanesi kullanılabilir
  }

  // CSV olarak dışa aktar
  void _exportAsCsv(DynamicForm form, List<FormResponse> responses) {
    // CSV dışa aktarma işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV dosyası oluşturuluyor...'),
      ),
    );

    // Gerçek uygulamada csv kütüphanesi kullanılabilir
  }

  // PDF olarak dışa aktar
  void _exportAsPdf(DynamicForm form, List<FormResponse> responses) {
    // PDF dışa aktarma işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF raporu oluşturuluyor...'),
      ),
    );

    // Gerçek uygulamada pdf kütüphanesi kullanılabilir
  }

  // Yardımcı metodlar
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getFormStatus(DynamicForm form) {
    if (form.expiresAt != null && form.expiresAt!.isBefore(DateTime.now())) {
      return 'Süresi Dolmuş';
    }

    if (form.settings.responseLimit != null) {
      return 'Aktif (${form.settings.responseLimit} limit)';
    }

    return 'Aktif';
  }

  IconData _getFormStatusIcon(DynamicForm form) {
    if (form.expiresAt != null && form.expiresAt!.isBefore(DateTime.now())) {
      return Icons.event_busy;
    }

    return Icons.event_available;
  }

  Color _getFormStatusColor(DynamicForm form) {
    if (form.expiresAt != null && form.expiresAt!.isBefore(DateTime.now())) {
      return Colors.red;
    }

    return Colors.green;
  }

  bool _isAnalyzableField(FormFieldx field) {
    return field.type == FormFieldType.radioButton ||
        field.type == FormFieldType.checkbox ||
        field.type == FormFieldType.dropdown ||
        field.type == FormFieldType.rating;
  }

  bool _isChartableField(FormFieldx field) {
    return _isAnalyzableField(field);
  }

  void _openUrl(String url) {
    // URL açma işlemi
    // Web için window.open, mobil için url_launcher kullanılabilir
  }

  IconData _getFileIcon(String url) {
    final extension = url.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _extractFileName(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    return path.split('/').last;
  }

  String _shortenLabel(String label) {
    if (label.length <= 10) return label;
    return '${label.substring(0, 8)}...';
  }
}

// Provider tanımlamaları
final formServiceProvider = Provider<FormService>((ref) {
  return FormService();
});

final formProvider =
    FutureProvider.family<DynamicForm?, String>((ref, formId) async {
  final formService = ref.watch(formServiceProvider);
  return formService.getForm(formId);
});

final formResponsesProvider =
    FutureProvider.family<List<FormResponse>, String>((ref, formId) async {
  final formService = ref.watch(formServiceProvider);
  return formService.getFormResponses(formId);
});

final formFieldsProvider =
    StateNotifierProvider<FormFieldsNotifier, List<FormFieldx>>((ref) {
  return FormFieldsNotifier();
});

class FormFieldsNotifier extends StateNotifier<List<FormFieldx>> {
  FormFieldsNotifier() : super([]);

  void addFormField(FormFieldx field) {
    state = [...state, field];
  }

  void updateFormField(int index, FormFieldx updatedField) {
    final updatedFields = [...state];
    updatedFields[index] = updatedField;
    state = updatedFields;
  }

  void removeFormField(int index) {
    final updatedFields = [...state];
    updatedFields.removeAt(index);
    state = updatedFields;
  }

  void reorderFields(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    if (newIndex < 0 || newIndex >= state.length) return;

    final updatedFields = [...state];

    // ReorderableListView için indexleri düzelt
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final field = updatedFields.removeAt(oldIndex);
    updatedFields.insert(newIndex, field);

    state = updatedFields;
  }

  void updateFieldValidation(int index, ValidationRule validation) {
    final updatedFields = [...state];
    updatedFields[index] =
        updatedFields[index].copyWith(validation: validation);
    state = updatedFields;
  }

  void duplicateField(int index) {
    final fieldToDuplicate = state[index];
    final duplicatedField = FormFieldx(
      type: fieldToDuplicate.type,
      label: '${fieldToDuplicate.label} (Kopya)',
      placeholder: fieldToDuplicate.placeholder,
      helperText: fieldToDuplicate.helperText,
      options: fieldToDuplicate.options
          ?.map((e) => FieldOption(label: e.label, value: e.value))
          .toList(),
      validation: fieldToDuplicate.validation,
      additionalProperties: fieldToDuplicate.additionalProperties,
    );

    state = [
      ...state.sublist(0, index + 1),
      duplicatedField,
      ...state.sublist(index + 1)
    ];
  }

  void clearFields() {
    state = [];
  }
}

final formSettingsProvider = StateProvider<FormSettings>((ref) {
  return FormSettings();
});

final expiryDateProvider = StateProvider<DateTime?>((ref) {
  return null;
});

// Form field copyWith metodu (model bölümüne eklenebilir)
