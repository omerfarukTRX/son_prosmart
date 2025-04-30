import 'package:flutter/material.dart';

class IconHelper {
  static final Map<String, IconData> icons = {
    'dashboard_outlined': Icons.dashboard_outlined,
    'analytics_outlined': Icons.analytics_outlined,
    'people_outlined': Icons.people_outlined,
    'settings_outlined': Icons.settings_outlined,
    'logout': Icons.logout,
    'task_outlined': Icons.task_outlined,
    'apartment': Icons.apartment,
    'engineering': Icons.engineering,
    'campaign_outlined': Icons.campaign_outlined,
    'assessment_outlined': Icons.assessment_outlined,
    'groups_outlined': Icons.groups_outlined,
    'local_shipping_outlined': Icons.local_shipping_outlined,
    'person_outlined': Icons.person_outlined,
    'notifications_outlined': Icons.notifications_outlined,
    'article_outlined': Icons.article_outlined,
    'home_outlined': Icons.home_outlined,
    'calendar_today_outlined': Icons.calendar_today_outlined,
    'payments_outlined': Icons.payments_outlined,
    'build_outlined': Icons.build_outlined,
    'security_outlined': Icons.security_outlined,
  };

  // String'den IconData'ya dönüşüm
  static IconData getIcon(String iconName) {
    return icons[iconName] ?? Icons.circle_outlined;
  }

  // Tüm ikonları liste olarak al
  static List<MapEntry<String, IconData>> getAllIcons() {
    return icons.entries.toList();
  }

  // IconData'yı String'e dönüştür
  static String? getIconName(IconData icon) {
    return icons.entries
        .firstWhere(
          (entry) => entry.value == icon,
          orElse: () =>
              const MapEntry('circle_outlined', Icons.circle_outlined),
        )
        .key;
  }
}
