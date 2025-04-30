import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

// Form elemanı tipi
enum FormFieldType {
  textField,
  textArea,
  radioButton,
  checkbox,
  dropdown,
  dateField,
  fileUpload,
  rating,
  section, // Bölüm başlığı
  paragraph // Açıklama metni
}

// Form doğrulama kuralları
class ValidationRule {
  final bool required;
  final int? minLength;
  final int? maxLength;
  final String? pattern; // Regex pattern
  final String? errorMessage;

  ValidationRule({
    this.required = false,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'required': required,
      'minLength': minLength,
      'maxLength': maxLength,
      'pattern': pattern,
      'errorMessage': errorMessage,
    };
  }

  factory ValidationRule.fromMap(Map<String, dynamic> map) {
    return ValidationRule(
      required: map['required'] ?? false,
      minLength: map['minLength'],
      maxLength: map['maxLength'],
      pattern: map['pattern'],
      errorMessage: map['errorMessage'],
    );
  }
  ValidationRule copyWith({
    bool? required,
    int? minLength,
    int? maxLength,
    String? pattern,
    String? errorMessage,
  }) {
    return ValidationRule(
      required: required ?? this.required,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      pattern: pattern ?? this.pattern,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Form elemanı seçenekleri (Radio, Checkbox, Dropdown için)
class FieldOption {
  final String id;
  final String label;
  final String? value;

  FieldOption({
    String? id,
    required this.label,
    this.value,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'value': value ?? label,
    };
  }

  factory FieldOption.fromMap(Map<String, dynamic> map) {
    return FieldOption(
      id: map['id'],
      label: map['label'],
      value: map['value'],
    );
  }
}

// Form elemanı
class FormFieldx {
  final String id;
  final FormFieldType type;
  final String label;
  final String? placeholder;
  final String? helperText;
  final List<FieldOption>? options;
  final ValidationRule? validation;
  final Map<String, dynamic>? additionalProperties;

  FormFieldx({
    String? id,
    required this.type,
    required this.label,
    this.placeholder,
    this.helperText,
    this.options,
    this.validation,
    this.additionalProperties,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'label': label,
      'placeholder': placeholder,
      'helperText': helperText,
      'options': options?.map((e) => e.toMap()).toList(),
      'validation': validation?.toMap(),
      'additionalProperties': additionalProperties,
    };
  }

  factory FormFieldx.fromMap(Map<String, dynamic> map) {
    return FormFieldx(
      id: map['id'],
      type: _parseFieldType(map['type']),
      label: map['label'],
      placeholder: map['placeholder'],
      helperText: map['helperText'],
      options: map['options'] != null
          ? List<FieldOption>.from(
              map['options']?.map((x) => FieldOption.fromMap(x)))
          : null,
      validation: map['validation'] != null
          ? ValidationRule.fromMap(map['validation'])
          : null,
      additionalProperties: map['additionalProperties'],
    );
  }

  static FormFieldType _parseFieldType(String typeStr) {
    return FormFieldType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => FormFieldType.textField,
    );
  }

  FormFieldx copyWith({
    String? id,
    FormFieldType? type,
    String? label,
    String? placeholder,
    String? helperText,
    List<FieldOption>? options,
    ValidationRule? validation,
    Map<String, dynamic>? additionalProperties,
  }) {
    return FormFieldx(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      placeholder: placeholder ?? this.placeholder,
      helperText: helperText ?? this.helperText,
      options: options ?? this.options,
      validation: validation ?? this.validation,
      additionalProperties: additionalProperties ?? this.additionalProperties,
    );
  }
}

// Form modeli
class DynamicForm {
  final String id;
  final String title;
  final String? description;
  final String projectId;
  final List<FormFieldx> fields;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final FormSettings settings;
  final String? qrCodeUrl;
  final String? formUrl;

  DynamicForm({
    String? id,
    required this.title,
    this.description,
    required this.projectId,
    required this.fields,
    DateTime? createdAt,
    this.expiresAt,
    FormSettings? settings,
    this.qrCodeUrl,
    this.formUrl,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        settings = settings ?? FormSettings();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'projectId': projectId,
      'fields': fields.map((e) => e.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'settings': settings.toMap(),
      'qrCodeUrl': qrCodeUrl,
      'formUrl': formUrl,
    };
  }

  factory DynamicForm.fromMap(Map<String, dynamic> map, String docId) {
    return DynamicForm(
      id: docId,
      title: map['title'],
      description: map['description'],
      projectId: map['projectId'],
      fields: List<FormFieldx>.from(
          map['fields']?.map((x) => FormFieldx.fromMap(x)) ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      settings: map['settings'] != null
          ? FormSettings.fromMap(map['settings'])
          : FormSettings(),
      qrCodeUrl: map['qrCodeUrl'],
      formUrl: map['formUrl'],
    );
  }

  // Form yanıtları için alt koleksiyon yolu
  String get responsesPath => 'forms/$id/responses';
}

// Form ayarları
class FormSettings {
  final bool allowAnonymous;
  final bool notifyOnSubmit;
  final int? responseLimit;
  final bool requireAuth;
  final List<String>? allowedUsers;
  final List<String>? allowedBlocks;
  final List<String>? allowedUnits;

  FormSettings({
    this.allowAnonymous = true,
    this.notifyOnSubmit = true,
    this.responseLimit,
    this.requireAuth = false,
    this.allowedUsers,
    this.allowedBlocks,
    this.allowedUnits,
  });

  Map<String, dynamic> toMap() {
    return {
      'allowAnonymous': allowAnonymous,
      'notifyOnSubmit': notifyOnSubmit,
      'responseLimit': responseLimit,
      'requireAuth': requireAuth,
      'allowedUsers': allowedUsers,
      'allowedBlocks': allowedBlocks,
      'allowedUnits': allowedUnits,
    };
  }

  factory FormSettings.fromMap(Map<String, dynamic> map) {
    return FormSettings(
      allowAnonymous: map['allowAnonymous'] ?? true,
      notifyOnSubmit: map['notifyOnSubmit'] ?? true,
      responseLimit: map['responseLimit'],
      requireAuth: map['requireAuth'] ?? false,
      allowedUsers: map['allowedUsers'] != null
          ? List<String>.from(map['allowedUsers'])
          : null,
      allowedBlocks: map['allowedBlocks'] != null
          ? List<String>.from(map['allowedBlocks'])
          : null,
      allowedUnits: map['allowedUnits'] != null
          ? List<String>.from(map['allowedUnits'])
          : null,
    );
  }
  FormSettings copyWith({
    bool? allowAnonymous,
    bool? notifyOnSubmit,
    int? responseLimit,
    bool? requireAuth,
    List<String>? allowedUsers,
    List<String>? allowedBlocks,
    List<String>? allowedUnits,
  }) {
    return FormSettings(
      allowAnonymous: allowAnonymous ?? this.allowAnonymous,
      notifyOnSubmit: notifyOnSubmit ?? this.notifyOnSubmit,
      responseLimit: responseLimit ?? this.responseLimit,
      requireAuth: requireAuth ?? this.requireAuth,
      allowedUsers: allowedUsers ?? this.allowedUsers,
      allowedBlocks: allowedBlocks ?? this.allowedBlocks,
      allowedUnits: allowedUnits ?? this.allowedUnits,
    );
  }
}

// Form yanıtı modeli
class FormResponse {
  final String id;
  final String formId;
  final Map<String, dynamic> data;
  final DateTime submittedAt;
  final String? submittedBy;
  final List<String>? attachmentUrls;

  FormResponse({
    String? id,
    required this.formId,
    required this.data,
    DateTime? submittedAt,
    this.submittedBy,
    this.attachmentUrls,
  })  : id = id ?? const Uuid().v4(),
        submittedAt = submittedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'formId': formId,
      'data': data,
      'submittedAt': FieldValue.serverTimestamp(),
      'submittedBy': submittedBy,
      'attachmentUrls': attachmentUrls,
    };
  }

  factory FormResponse.fromMap(Map<String, dynamic> map, String docId) {
    return FormResponse(
      id: docId,
      formId: map['formId'],
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      submittedAt:
          (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      submittedBy: map['submittedBy'],
      attachmentUrls: map['attachmentUrls'] != null
          ? List<String>.from(map['attachmentUrls'])
          : null,
    );
  }
}
