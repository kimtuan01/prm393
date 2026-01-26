import 'package:flutter/material.dart';

class CategoryGroupTabs extends StatelessWidget {
  final TabController controller;

  const CategoryGroupTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Theme.of(context).colorScheme.primary,
      tabs: const [
        Tab(text: 'Khoản chi'),
        Tab(text: 'Khoản thu'),
      ],
    );
  }
}
