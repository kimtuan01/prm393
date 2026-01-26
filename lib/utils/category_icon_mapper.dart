import 'package:flutter/material.dart';

class CategoryIconMapper {
  static IconData fromKey(String key) {
    switch (key) {
      case 'food':
        return Icons.restaurant;
      case 'restaurant':
        return Icons.restaurant_menu;
      case 'car':
        return Icons.local_gas_station;
      case 'salary':
        return Icons.attach_money;
      case 'home':
        return Icons.home;
      case 'bill':
        return Icons.receipt_long;
      case 'shopping':
        return Icons.shopping_bag;
      case 'clothing':
        return Icons.checkroom;
      case 'health':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      case 'entertainment':
        return Icons.movie;
      case 'beauty':
        return Icons.spa;
      case 'fitness':
        return Icons.fitness_center;
      case 'travel':
        return Icons.flight;
      case 'family':
        return Icons.family_restroom;
      case 'fee':
        return Icons.money_off;
      case 'other':
        return Icons.more_horiz;
      case 'bonus':
      case 'gift':
        return Icons.card_giftcard;
      case 'freelance':
        return Icons.work;
      case 'business':
        return Icons.storefront;
      case 'investment':
        return Icons.trending_up;
      case 'cashback':
        return Icons.monetization_on;
      case 'other_income':
        return Icons.more_horiz;
      case 'loan':
        return Icons.account_balance;
      case 'debt':
        return Icons.credit_card;
      case 'collect':
        return Icons.call_received;
      case 'repay':
        return Icons.payments;
      default:
        return Icons.category;
    }
  }

  /// Returns an asset path for a known key, otherwise null.
  static String? assetForKey(String key) {
    const map = {
      'food': 'assets/icons/food.png',
      'restaurant': 'assets/icons/restaurant.png',
      'education': 'assets/icons/education.png',
      'bill': 'assets/icons/invoice.png',
      'invoice': 'assets/icons/invoice.png',
      'salary': 'assets/icons/salary.png',
      'online-shopping': 'assets/icons/online-shopping.png',
      'shopping': 'assets/icons/shopping.png',
      'massage': 'assets/icons/massage.png',
      'beauty': 'assets/icons/massage.png',
      'apartment': 'assets/icons/apartment.png',
      'hospital': 'assets/icons/hospital.png',
      'position': 'assets/icons/position.png',
      'entertainment': 'assets/icons/cinema.png',
    };

    return map[key];
  }
}
