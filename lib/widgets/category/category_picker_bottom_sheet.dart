import 'package:flutter/material.dart';

import '../../models/category_group.dart';
import '../../services/data/category_group_service.dart';
import '../../utils/category_icon_mapper.dart';

class CategoryPickerBottomSheet extends StatelessWidget {
  final CategoryType type;
  final Function(CategoryGroup) onSelected;

  const CategoryPickerBottomSheet({
    super.key,
    required this.type,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final service = CategoryGroupService();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== HANDLE =====
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const Text(
              'Chọn danh mục',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            // ===== CATEGORY GRID =====
            Expanded(
              child: FutureBuilder<List<CategoryGroup>>(
                future: service.getAll(type: type),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Khử trùng lặp theo (type, name) để tránh hiện lặp danh mục
                  final seen = <String>{};
                  final items = snapshot.data!
                      .where(
                        (c) => seen.add(
                          '${c.type.index}-${c.name.trim().toLowerCase()}',
                        ),
                      )
                      .toList();

                  if (items.isEmpty) {
                    return const Center(child: Text('Chưa có danh mục'));
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final group = items[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onSelected(group);
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Color(group.colorValue),
                              child: Builder(
                                builder: (_) {
                                  final asset = CategoryIconMapper.assetForKey(
                                    group.iconKey,
                                  );
                                  if (asset != null) {
                                    return ClipOval(
                                      child: Image.asset(
                                        asset,
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Icon(
                                                CategoryIconMapper.fromKey(
                                                  group.iconKey,
                                                ),
                                                color: Colors.white,
                                              );
                                            },
                                      ),
                                    );
                                  }
                                  return Icon(
                                    CategoryIconMapper.fromKey(group.iconKey),
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              group.name,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
