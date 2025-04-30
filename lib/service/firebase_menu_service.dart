import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';

class FirebaseMenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'menus';

  // Menüleri getir
  Stream<List<MenuModel>> getMenus() {
    return _firestore
        .collection(_collection)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MenuModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Menü ekle
  Future<void> addMenu(MenuModel menu) async {
    await _firestore.collection(_collection).add(menu.toFirestore());
  }

  // Menü güncelle
  Future<void> updateMenu(MenuModel menu) async {
    await _firestore
        .collection(_collection)
        .doc(menu.id)
        .update(menu.toFirestore());
  }

  // Menü sil
  Future<void> deleteMenu(String menuId) async {
    await _firestore.collection(_collection).doc(menuId).delete();
  }

  // Menü sıralamasını güncelle
  Future<void> reorderMenus(List<MenuModel> menus) async {
    final batch = _firestore.batch();

    for (var i = 0; i < menus.length; i++) {
      final menu = menus[i].copyWith(order: i);
      final docRef = _firestore.collection(_collection).doc(menu.id);
      batch.update(docRef, {'order': i});
    }

    await batch.commit();
  }
}
