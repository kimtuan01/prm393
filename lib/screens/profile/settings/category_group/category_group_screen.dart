import 'package:flutter/material.dart';

import '../../../../config/theme.dart';

import '../../../../models/category_group.dart';
import '../../../../services/data/category_group_service.dart';
import '../../../../widgets/category/category_group_tile.dart';
import 'add_category_group_screen.dart';

class CategoryGroupScreen extends StatefulWidget {
  const CategoryGroupScreen({super.key});

  @override
  State<CategoryGroupScreen> createState() => _CategoryGroupScreenState();
}

class _CategoryGroupScreenState extends State<CategoryGroupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final CategoryGroupService _service = CategoryGroupService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm danh mục'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Khoản chi'),
            Tab(text: 'Khoản thu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(CategoryType.expense),
          _buildList(CategoryType.income),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAdd,
        backgroundColor: AppTheme.primaryTeal,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ================= LIST =================

  Widget _buildList(CategoryType type) {
    return FutureBuilder<List<CategoryGroup>>(
      future: _service.getAll(type: type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var items = snapshot.data ?? [];

        if (items.isEmpty) {
          return const Center(child: Text('Chưa có nhóm danh mục'));
        }

        // Sắp xếp alphabetical, "Khác" ở cuối
        items.sort((a, b) {
          final aIsOther = a.name.contains('Khác');
          final bIsOther = b.name.contains('Khác');
          if (aIsOther && !bIsOther) return 1;
          if (!aIsOther && bIsOther) return -1;
          return a.name.compareTo(b.name);
        });

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final group = items[index];

            return CategoryGroupTile(
              group: group,
              onDelete: group.isSystem
                  ? null
                  : () {
                      _deleteGroup(group.id);
                    },
            );
          },
        );
      },
    );
  }

  // ================= ACTIONS =================

  Future<void> _deleteGroup(String id) async {
    await _service.delete(id);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _goToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCategoryGroupScreen()),
    );
    if (mounted) {
      setState(() {});
    }
  }
}
