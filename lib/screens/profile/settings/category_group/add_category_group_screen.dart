import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../models/category_group.dart';
import '../../../../services/data/category_group_service.dart';

class AddCategoryGroupScreen extends StatefulWidget {
  const AddCategoryGroupScreen({super.key});

  @override
  State<AddCategoryGroupScreen> createState() => _AddCategoryGroupScreenState();
}

class _AddCategoryGroupScreenState extends State<AddCategoryGroupScreen> {
  final _nameController = TextEditingController();
  CategoryType _type = CategoryType.expense;

  final _service = CategoryGroupService();

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final group = CategoryGroup(
      id: const Uuid().v4(),
      name: name,
      type: _type,
      iconKey: 'category',
      colorValue: Colors.teal.value,
      createdAt: DateTime.now(),
    );

    try {
      await _service.add(group);
      if (mounted) Navigator.pop(context, true);
    } on ArgumentError catch (e) {
      // Show friendly error message (duplicate or forbidden)
      final msg = e.message ?? 'Không thể lưu danh mục';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lỗi khi lưu danh mục')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm nhóm danh mục')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên nhóm'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CategoryType>(
              value: _type,
              items: const [
                DropdownMenuItem(
                  value: CategoryType.expense,
                  child: Text('Khoản chi'),
                ),
                DropdownMenuItem(
                  value: CategoryType.income,
                  child: Text('Khoản thu'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
              decoration: const InputDecoration(labelText: 'Loại'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Lưu')),
          ],
        ),
      ),
    );
  }
}
