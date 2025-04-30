import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosmart/form/form_element_model.dart';
import 'package:prosmart/form/form_service.dart';

// Servis provider'ı
final formServiceProvider = Provider<FormService>((ref) {
  return FormService();
});

// Form getirme provider'ı
final formProvider =
    FutureProvider.family<DynamicForm?, String>((ref, formId) async {
  final formService = ref.watch(formServiceProvider);
  return formService.getForm(formId);
});

// Proje formları provider'ı
final projeFormlariProvider =
    StreamProvider.family<List<DynamicForm>, String>((ref, projectId) async* {
  final formService = ref.watch(formServiceProvider);
  final forms = await formService.getFormsByProject(projectId);
  yield forms;
});

// Form yanıtları provider'ı
final formResponsesProvider =
    FutureProvider.family<List<FormResponse>, String>((ref, formId) async {
  final formService = ref.watch(formServiceProvider);
  return formService.getFormResponses(formId);
});

// Form alanları state provider'ı
final formFieldsProvider =
    StateNotifierProvider<FormFieldsNotifier, List<FormFieldx>>((ref) {
  return FormFieldsNotifier();
});

// Form alanları notifier sınıfı
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
    final field = updatedFields[index];

    updatedFields[index] = FormFieldx(
      id: field.id,
      type: field.type,
      label: field.label,
      placeholder: field.placeholder,
      helperText: field.helperText,
      options: field.options,
      validation: validation,
      additionalProperties: field.additionalProperties,
    );

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

// Form ayarları provider'ı
final formSettingsProvider = StateProvider<FormSettings>((ref) {
  return FormSettings();
});

// Son geçerlilik tarihi provider'ı
final expiryDateProvider = StateProvider<DateTime?>((ref) {
  return null;
});

// Form oluşturma durumu provider'ı
final formCreationStateProvider = StateProvider<FormCreationState>((ref) {
  return FormCreationState();
});

// Form oluşturma durum sınıfı
class FormCreationState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  FormCreationState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  FormCreationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return FormCreationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// Form oluşturma işlemi provider'ı
final createFormProvider =
    FutureProvider.autoDispose.family<String, DynamicForm>((ref, form) async {
  final formService = ref.watch(formServiceProvider);

  // Yükleme durumunu güncelle
  ref.read(formCreationStateProvider.notifier).state = FormCreationState(
    isLoading: true,
    errorMessage: null,
    successMessage: null,
  );

  try {
    final formId = await formService.createForm(form);

    // Başarı durumunu güncelle
    ref.read(formCreationStateProvider.notifier).state = FormCreationState(
      isLoading: false,
      successMessage: 'Form başarıyla oluşturuldu',
    );

    return formId;
  } catch (e) {
    // Hata durumunu güncelle
    ref.read(formCreationStateProvider.notifier).state = FormCreationState(
      isLoading: false,
      errorMessage: 'Form oluşturulurken hata: $e',
    );
    rethrow;
  }
});

// Form güncelleme işlemi provider'ı
final updateFormProvider =
    FutureProvider.autoDispose.family<void, DynamicForm>((ref, form) async {
  final formService = ref.watch(formServiceProvider);

  // Yükleme durumunu güncelle
  ref.read(formCreationStateProvider.notifier).state = FormCreationState(
    isLoading: true,
    errorMessage: null,
    successMessage: null,
  );

  try {
    await formService.updateForm(form);

    // Başarı durumunu güncelle
    ref.read(formCreationStateProvider.notifier).state = FormCreationState(
      isLoading: false,
      successMessage: 'Form başarıyla güncellendi',
    );
  } catch (e) {
    // Hata durumunu güncelle
    ref.read(formCreationStateProvider.notifier).state = FormCreationState(
      isLoading: false,
      errorMessage: 'Form güncellenirken hata: $e',
    );
    rethrow;
  }
});

// Form silme işlemi provider'ı
final deleteFormProvider =
    FutureProvider.autoDispose.family<void, String>((ref, formId) async {
  final formService = ref.watch(formServiceProvider);
  await formService.deleteForm(formId);
});

// Form yanıtı gönderme provider'ı
final submitFormResponseProvider = FutureProvider.autoDispose
    .family<String, FormResponse>((ref, response) async {
  final formService = ref.watch(formServiceProvider);
  return formService.submitFormResponse(response);
});

// Form yanıt analizi provider'ı
final formResponseAnalysisProvider =
    Provider.family<FormResponseAnalysis, FormResponseAnalysisParams>(
        (ref, params) {
  final form = params.form;
  final responses = params.responses;

  // Analiz verilerini hesapla
  return FormResponseAnalysis(
    totalResponses: responses.length,
    firstResponseDate: responses.isNotEmpty ? responses.last.submittedAt : null,
    lastResponseDate: responses.isNotEmpty ? responses.first.submittedAt : null,
    completionRate: form.settings.responseLimit != null &&
            form.settings.responseLimit! > 0
        ? (responses.length / form.settings.responseLimit! * 100).clamp(0, 100)
        : null,
    fieldAnalytics: _calculateFieldAnalytics(form, responses),
  );
});

// Form yanıt analizi için yardımcı fonksiyon
Map<String, FieldAnalytics> _calculateFieldAnalytics(
    DynamicForm form, List<FormResponse> responses) {
  final result = <String, FieldAnalytics>{};

  // Analize uygun alanları seç
  final analyzableFields = form.fields.where((field) =>
      field.type == FormFieldType.radioButton ||
      field.type == FormFieldType.checkbox ||
      field.type == FormFieldType.dropdown ||
      field.type == FormFieldType.rating);

  for (var field in analyzableFields) {
    final fieldResponses = responses
        .where((r) => r.data.containsKey(field.id))
        .map((r) => r.data[field.id])
        .where((r) => r != null)
        .toList();

    if (fieldResponses.isEmpty) continue;

    switch (field.type) {
      case FormFieldType.radioButton:
      case FormFieldType.dropdown:
        final optionCounts = <String, int>{};

        for (var response in fieldResponses) {
          final option = response.toString();
          optionCounts[option] = (optionCounts[option] ?? 0) + 1;
        }

        result[field.id] = FieldAnalytics(
          fieldId: field.id,
          fieldType: field.type,
          responseCount: fieldResponses.length,
          optionCounts: optionCounts,
        );
        break;

      case FormFieldType.checkbox:
        final optionCounts = <String, int>{};

        for (var response in fieldResponses) {
          if (response is List) {
            for (var option in response) {
              optionCounts[option.toString()] =
                  (optionCounts[option.toString()] ?? 0) + 1;
            }
          }
        }

        result[field.id] = FieldAnalytics(
          fieldId: field.id,
          fieldType: field.type,
          responseCount: fieldResponses.length,
          optionCounts: optionCounts,
        );
        break;

      case FormFieldType.rating:
        final ratings = <int, int>{};
        int total = 0;

        for (var response in fieldResponses) {
          if (response is int) {
            ratings[response] = (ratings[response] ?? 0) + 1;
            total += response;
          }
        }

        result[field.id] = FieldAnalytics(
          fieldId: field.id,
          fieldType: field.type,
          responseCount: fieldResponses.length,
          ratings: ratings,
          averageRating:
              fieldResponses.isNotEmpty ? total / fieldResponses.length : 0,
        );
        break;

      default:
        break;
    }
  }

  return result;
}

// Form yanıt analizi parametreleri
class FormResponseAnalysisParams {
  final DynamicForm form;
  final List<FormResponse> responses;

  FormResponseAnalysisParams({
    required this.form,
    required this.responses,
  });
}

// Form yanıt analizi sınıfı
class FormResponseAnalysis {
  final int totalResponses;
  final DateTime? firstResponseDate;
  final DateTime? lastResponseDate;
  final double? completionRate;
  final Map<String, FieldAnalytics> fieldAnalytics;

  FormResponseAnalysis({
    required this.totalResponses,
    this.firstResponseDate,
    this.lastResponseDate,
    this.completionRate,
    required this.fieldAnalytics,
  });
}

// Alan analitiği sınıfı
class FieldAnalytics {
  final String fieldId;
  final FormFieldType fieldType;
  final int responseCount;
  final Map<String, int>? optionCounts;
  final Map<int, int>? ratings;
  final double? averageRating;

  FieldAnalytics({
    required this.fieldId,
    required this.fieldType,
    required this.responseCount,
    this.optionCounts,
    this.ratings,
    this.averageRating,
  });

  // Bir seçeneğin yüzdesini hesapla
  double? getOptionPercentage(String option) {
    if (optionCounts == null || responseCount == 0) return null;
    return (optionCounts![option] ?? 0) / responseCount * 100;
  }

  // Bir derecelendirmenin yüzdesini hesapla
  double? getRatingPercentage(int rating) {
    if (ratings == null || responseCount == 0) return null;
    return (ratings![rating] ?? 0) / responseCount * 100;
  }
}

// Form özelleştirme provider'ı (tema, renkler vb.)
final formCustomizationProvider = StateProvider<FormCustomization>((ref) {
  return FormCustomization();
});

// Form özelleştirme sınıfı
class FormCustomization {
  final Color primaryColor;
  final Color backgroundColor;
  final String? logoUrl;
  final String? headerImageUrl;
  final bool showProjectHeader;
  final String? customCss;

  FormCustomization({
    this.primaryColor = const Color(0xFF2196F3), // Varsayılan mavi
    this.backgroundColor = const Color(0xFFFAFAFA), // Varsayılan açık gri
    this.logoUrl,
    this.headerImageUrl,
    this.showProjectHeader = true,
    this.customCss,
  });

  FormCustomization copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    String? logoUrl,
    String? headerImageUrl,
    bool? showProjectHeader,
    String? customCss,
  }) {
    return FormCustomization(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      logoUrl: logoUrl ?? this.logoUrl,
      headerImageUrl: headerImageUrl ?? this.headerImageUrl,
      showProjectHeader: showProjectHeader ?? this.showProjectHeader,
      customCss: customCss ?? this.customCss,
    );
  }
}

// Aktif formlar provider'ı (süresi dolmamış ve limit aşılmamış formlar)
final activeFormsProvider =
    Provider.family<List<DynamicForm>, List<DynamicForm>>((ref, allForms) {
  final now = DateTime.now();

  return allForms.where((form) {
    // Süresi dolmamış formları filtrele
    if (form.expiresAt != null && form.expiresAt!.isBefore(now)) {
      return false;
    }

    // Yanıt limiti aşılmamış formları filtrele
    if (form.settings.responseLimit != null) {
      final responses = ref.watch(formResponsesProvider(form.id)).value ?? [];
      if (responses.length >= form.settings.responseLimit!) {
        return false;
      }
    }

    return true;
  }).toList();
});

// Form erişim kontrolü provider'ı
final formAccessControlProvider =
    Provider.family<bool, FormAccessParams>((ref, params) {
  final form = params.form;
  final userId = params.userId;

  // Anonim erişime açık mı?
  if (form.settings.allowAnonymous) {
    return true;
  }

  // Kullanıcı kimliği zorunlu mu?
  if (form.settings.requireAuth && userId == null) {
    return false;
  }

  // Belirli kullanıcılara kısıtlı mı?
  if (form.settings.allowedUsers != null &&
      form.settings.allowedUsers!.isNotEmpty &&
      userId != null) {
    return form.settings.allowedUsers!.contains(userId);
  }

  return true;
});

// Form erişim parametreleri
class FormAccessParams {
  final DynamicForm form;
  final String? userId;
  final String? blockId;
  final String? unitId;

  FormAccessParams({
    required this.form,
    this.userId,
    this.blockId,
    this.unitId,
  });
}
