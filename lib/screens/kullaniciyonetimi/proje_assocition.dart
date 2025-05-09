class ProjectAssociation {
  final String projectId;
  final String role; // Sadece "siteSakini" veya "kiraci" değerlerini alacak
  final bool hasSpecialAccess; // Özel erişim izni
  final Map<String, dynamic>? additionalInfo; // Blok, daire vb. bilgiler

  ProjectAssociation({
    required this.projectId,
    required this.role,
    this.hasSpecialAccess = false,
    this.additionalInfo,
  });

  // Veri dönüşüm metodları
  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'role': role,
      'hasSpecialAccess': hasSpecialAccess,
      'additionalInfo': additionalInfo,
    };
  }

  factory ProjectAssociation.fromMap(Map<String, dynamic> map) {
    return ProjectAssociation(
      projectId: map['projectId'] ?? '',
      role: map['role'] ?? 'siteSakini',
      hasSpecialAccess: map['hasSpecialAccess'] ?? false,
      additionalInfo: map['additionalInfo'],
    );
  }

  // Kopyalama ile güncel bir nesne oluştur
  ProjectAssociation copyWith({
    String? projectId,
    String? role,
    bool? hasSpecialAccess,
    Map<String, dynamic>? additionalInfo,
  }) {
    return ProjectAssociation(
      projectId: projectId ?? this.projectId,
      role: role ?? this.role,
      hasSpecialAccess: hasSpecialAccess ?? this.hasSpecialAccess,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
