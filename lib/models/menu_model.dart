import 'package:flutter/material.dart';

class MenuModel {
  final String id;
  final String title;
  final String route;
  final String icon;
  final List<String> roles;
  final bool isActive;
  final int order;
  final String? badge;

  const MenuModel({
    required this.id,
    required this.title,
    required this.route,
    required this.icon,
    required this.roles,
    required this.order,
    this.isActive = true,
    this.badge,
  });

  // Firestore'dan gelen veriyi MenuModel'e çevir
  factory MenuModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return MenuModel(
      id: documentId,
      title: data['title'] ?? '',
      route: data['route'] ?? '',
      icon: data['icon'] ?? 'dashboard_outlined',
      roles: List<String>.from(data['roles'] ?? []),
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      badge: data['badge'],
    );
  }

  // MenuModel'i Firestore'a gönderilecek veriye çevir
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'route': route,
      'icon': icon,
      'roles': roles,
      'isActive': isActive,
      'order': order,
      'badge': badge,
    };
  }

  // MenuModel'i kopyala ve bazı alanları güncelle
  MenuModel copyWith({
    String? title,
    String? route,
    String? icon,
    List<String>? roles,
    bool? isActive,
    int? order,
    String? badge,
  }) {
    return MenuModel(
      id: id,
      title: title ?? this.title,
      route: route ?? this.route,
      icon: icon ?? this.icon,
      roles: roles ?? this.roles,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      badge: badge ?? this.badge,
    );
  }

  @override
  String toString() {
    return 'MenuModel(id: $id, title: $title, route: $route, roles: $roles, isActive: $isActive, order: $order)';
  }
}
