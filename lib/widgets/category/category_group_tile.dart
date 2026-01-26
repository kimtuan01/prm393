import 'package:flutter/material.dart';
import '../../models/category_group.dart';
import '../../utils/category_icon_mapper.dart';

class CategoryGroupTile extends StatelessWidget {
  final CategoryGroup group;
  final VoidCallback? onDelete; // ✅ CHO PHÉP NULL

  const CategoryGroupTile({super.key, required this.group, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(group.colorValue),
        child: Builder(
          builder: (context) {
            final asset = CategoryIconMapper.assetForKey(group.iconKey);
            if (asset != null) {
              return ClipOval(
                child: Image.asset(
                  asset,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      CategoryIconMapper.fromKey(group.iconKey),
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
      title: Text(group.name),
      subtitle: group.isSystem ? const Text('Mặc định') : null,
      trailing: onDelete == null
          ? null
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
    );
  }
}
