import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_group.dart';

// ============================================================================
// FIREBASE CATEGORY REPOSITORY - Cloud storage for category groups
// ============================================================================

class FirebaseCategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection path: users/{userId}/categories/{categoryId}
  CollectionReference<Map<String, dynamic>> _getUserCategoriesRef(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  // ================= CREATE/UPDATE =================
  Future<void> saveCategory(String userId, CategoryGroup category) async {
    try {
      final ref = _getUserCategoriesRef(userId);
      await ref.doc(category.id).set(_categoryToMap(category));
      print('✅ [Firebase] Saved category: ${category.id}');
    } catch (e) {
      print('❌ [Firebase] Error saving category: $e');
      rethrow;
    }
  }

  // ================= BATCH SAVE =================
  Future<void> saveCategories(
    String userId,
    List<CategoryGroup> categories,
  ) async {
    if (categories.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final ref = _getUserCategoriesRef(userId);

      for (var category in categories) {
        batch.set(ref.doc(category.id), _categoryToMap(category));
      }

      await batch.commit();
      print('✅ [Firebase] Saved ${categories.length} categories');
    } catch (e) {
      print('❌ [Firebase] Error batch saving categories: $e');
      rethrow;
    }
  }

  // ================= READ =================
  Future<List<CategoryGroup>> getAllCategories(String userId) async {
    try {
      final snapshot = await _getUserCategoriesRef(userId).get();
      return snapshot.docs.map((doc) => _categoryFromMap(doc.data())).toList();
    } catch (e) {
      print('❌ [Firebase] Error getting categories: $e');
      return [];
    }
  }

  Future<CategoryGroup?> getCategoryById(
    String userId,
    String categoryId,
  ) async {
    try {
      final doc = await _getUserCategoriesRef(userId).doc(categoryId).get();
      if (!doc.exists) return null;
      return _categoryFromMap(doc.data()!);
    } catch (e) {
      print('❌ [Firebase] Error getting category: $e');
      return null;
    }
  }

  // ================= DELETE =================
  Future<void> deleteCategory(String userId, String categoryId) async {
    try {
      await _getUserCategoriesRef(userId).doc(categoryId).delete();
      print('✅ [Firebase] Deleted category: $categoryId');
    } catch (e) {
      print('❌ [Firebase] Error deleting category: $e');
      rethrow;
    }
  }

  // ================= HELPERS =================
  Map<String, dynamic> _categoryToMap(CategoryGroup category) {
    return {
      'id': category.id,
      'name': category.name,
      'type': category.type.name,
      'iconKey': category.iconKey,
      'colorValue': category.colorValue,
      'isSystem': category.isSystem,
      'createdAt': category.createdAt.toIso8601String(),
    };
  }

  CategoryGroup _categoryFromMap(Map<String, dynamic> map) {
    return CategoryGroup(
      id: map['id'],
      name: map['name'],
      type: CategoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CategoryType.expense,
      ),
      iconKey: map['iconKey'],
      colorValue: map['colorValue'],
      isSystem: map['isSystem'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
