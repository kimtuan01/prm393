import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../../models/category_group.dart';
import '../firebase/firebase_category_repository.dart';
import '../../utils/category_seed.dart';

class CategoryGroupService {
  static const _boxName = 'category_groups';
  final FirebaseCategoryRepository _firebaseRepo = FirebaseCategoryRepository();

  // Known variant -> canonical mapping used for duplicate detection
  static const Map<String, String> _canonicalMap = {
    'du lịch & nghỉ dưỡng': 'du lịch',
    'gia đình & trẻ em': 'gia đình',
    'hóa đơn & tiện ích': 'hóa đơn',
    'quần áo & phụ kiện': 'quần áo',
    'thể thao & fitness': 'thể thao',
    'y tế & sức khỏe': 'y tế',
  };

  Box<CategoryGroup> get _box => Hive.box<CategoryGroup>(_boxName);

  String _normalize(String s) => s.trim().toLowerCase();
  String _canonicalName(String s) =>
      _canonicalMap[_normalize(s)] ?? _normalize(s);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (!Hive.isBoxOpen(_boxName)) await Hive.openBox<CategoryGroup>(_boxName);

    try {
      final prefs = Hive.box('preferences');
      final already = prefs.get('category_cleanup_done') as bool? ?? false;
      if (!already) {
        // Schedule cleanup in background to avoid blocking UI/init
        Future.microtask(() async {
          try {
            final summary = await CategorySeed.runFullCleanup(this);
            prefs.put('category_cleanup_done', true);
            debugPrint('✅ Category cleanup applied (background): $summary');
          } catch (e) {
            debugPrint('⚠️ Background category cleanup failed: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ Category cleanup/init failed: $e');
    }

    _initialized = true;
  }

  List<CategoryGroup> _deduplicated(List<CategoryGroup> list) {
    final Map<String, List<CategoryGroup>> groups = {};
    for (final cat in list) {
      final key = '${cat.type.index}::${_canonicalName(cat.name)}';
      groups.putIfAbsent(key, () => []).add(cat);
    }

    final result = <CategoryGroup>[];
    for (final entry in groups.entries) {
      final items = entry.value;
      items.sort((a, b) {
        if (a.isSystem != b.isSystem) return a.isSystem ? -1 : 1;
        return a.createdAt.compareTo(b.createdAt);
      });
      result.add(items.first);
    }
    return result;
  }

  Future<List<CategoryGroup>> getAll({CategoryType? type}) async {
    await init();

    final list = _box.values.toList();

    if (type == null) {
      // Deduplicate on-the-fly and return canonical list for UI safety
      return _deduplicated(list);
    }

    final filtered = list.where((e) => e.type == type).toList();
    return _deduplicated(filtered);
  }

  Future<void> add(CategoryGroup group, {String? userId}) async {
    final incomingCanonical = _canonicalName(group.name);

    // Disallow adding a user category that duplicates an existing system category (same type)
    final existing = _box.values.toList();
    final duplicateSystem = existing.any(
      (e) =>
          e.isSystem &&
          _canonicalName(e.name) == incomingCanonical &&
          e.type == group.type,
    );
    if (duplicateSystem && !group.isSystem) {
      throw ArgumentError('Tên nhóm trùng với danh mục hệ thống');
    }

    // Disallow any duplicate name within same type (variant-aware)
    final duplicateAny = existing.any(
      (e) =>
          _canonicalName(e.name) == incomingCanonical && e.type == group.type,
    );
    if (duplicateAny) {
      throw ArgumentError('Nhóm danh mục đã tồn tại');
    }

    // 🔥 HYBRID: Save locally first
    await _box.put(group.id, group);

    // 🌐 CLOUD SYNC: Upload to Firebase asynchronously
    if (userId != null) {
      _firebaseRepo.saveCategory(userId, group).catchError((e) {
        print('⚠️ [Category] Cloud sync failed, will retry later: $e');
      });
    }
  }

  /// Update an existing CategoryGroup.
  ///
  /// By default, system categories (isSystem==true) cannot have their name
  /// or type changed by normal calls. Pass [allowSystemEdit=true] only when
  /// the caller is an admin performing a controlled change (or tests).
  Future<void> update(
    CategoryGroup group, {
    bool allowSystemEdit = false,
    String? userId,
  }) async {
    final existing = _box.get(group.id);
    if (existing == null) {
      throw ArgumentError('Nhóm danh mục không tồn tại');
    }

    if (existing.isSystem && !allowSystemEdit) {
      // Disallow renaming or type change for system categories
      if (existing.name.trim().toLowerCase() !=
              group.name.trim().toLowerCase() ||
          existing.type != group.type) {
        throw ArgumentError(
          'Không thể chỉnh sửa tên hoặc loại của danh mục hệ thống',
        );
      }
    }

    // Also prevent creating a non-system group with the same canonical name as an existing system group
    final incomingCanonical = _canonicalName(group.name);
    final duplicateSystem = _box.values.any(
      (e) =>
          e.isSystem &&
          _canonicalName(e.name) == incomingCanonical &&
          e.type == group.type &&
          e.id != group.id,
    );
    if (duplicateSystem && !group.isSystem) {
      throw ArgumentError('Tên nhóm trùng với danh mục hệ thống');
    }

    // Prevent creating any duplicate canonical name within same type
    final duplicateAny = _box.values.any(
      (e) =>
          _canonicalName(e.name) == incomingCanonical &&
          e.type == group.type &&
          e.id != group.id,
    );
    if (duplicateAny) {
      throw ArgumentError('Nhóm danh mục đã tồn tại');
    }

    // 🔥 HYBRID: Save locally first
    await _box.put(group.id, group);

    // 🌐 CLOUD SYNC: Upload to Firebase asynchronously
    if (userId != null) {
      _firebaseRepo.saveCategory(userId, group).catchError((e) {
        print('⚠️ [Category] Cloud update failed: $e');
      });
    }
  }

  Future<void> delete(String id, {String? userId, bool force = false}) async {
    final group = _box.get(id);
    if (group == null) return;
    if (group.isSystem && !force) {
      throw ArgumentError('Không thể xóa danh mục hệ thống');
    }

    // 🔥 HYBRID: Delete locally first
    await _box.delete(id);

    // 🌐 CLOUD SYNC: Delete from Firebase
    if (userId != null) {
      _firebaseRepo.deleteCategory(userId, id).catchError((e) {
        print('⚠️ [Category] Cloud delete failed: $e');
      });
    }
  }

  /// Delete all system categories (DEV only). Use with caution.
  Future<void> deleteSystemCategories() async {
    final toDelete = _box.values.where((g) => g.isSystem).toList();
    for (final g in toDelete) {
      await _box.delete(g.id);
    }
  }

  bool get isEmpty => _box.isEmpty;
}
