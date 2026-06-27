import 'package:flutter/material.dart';

/// Maps stored icon keys to a consistent, premium icon set (rounded family).
class AppIcons {
  static const Map<String, IconData> _map = {
    'category': Icons.category_rounded,
    'restaurant': Icons.restaurant_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'checkroom': Icons.checkroom_rounded,
    'family': Icons.family_restroom_rounded,
    'groups': Icons.groups_rounded,
    'directions_car': Icons.directions_car_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'flight': Icons.flight_rounded,
    'train': Icons.train_rounded,
    'receipt': Icons.receipt_long_rounded,
    'home': Icons.home_rounded,
    'health': Icons.local_hospital_rounded,
    'movie': Icons.movie_rounded,
    'subscriptions': Icons.subscriptions_rounded,
    'school': Icons.school_rounded,
    'spa': Icons.spa_rounded,
    'gift': Icons.card_giftcard_rounded,
    'savings': Icons.savings_rounded,
    'shield': Icons.shield_rounded,
    'pets': Icons.pets_rounded,
    'sports': Icons.sports_esports_rounded,
    'trending_up': Icons.trending_up_rounded,
    'credit_card': Icons.credit_card_rounded,
    'handshake': Icons.handshake_rounded,
    'payments': Icons.payments_rounded,
    'undo': Icons.undo_rounded,
    'store': Icons.storefront_rounded,
    'work': Icons.work_rounded,
    'star': Icons.star_rounded,
    'account_balance': Icons.account_balance_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
  };

  static IconData of(String? key) => _map[key] ?? Icons.category_rounded;

  static const List<String> pickable = [
    'category', 'restaurant', 'shopping_cart', 'shopping_bag', 'checkroom',
    'family', 'groups', 'directions_car', 'fuel', 'flight', 'train', 'receipt',
    'home', 'health', 'movie', 'subscriptions', 'school', 'spa', 'gift',
    'savings', 'shield', 'pets', 'sports', 'trending_up', 'credit_card',
    'handshake', 'payments', 'undo', 'store', 'work', 'star',
    'account_balance', 'wallet',
  ];

  static Color parseColor(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  static const List<String> palette = [
    '#6C5CE7', '#0984E3', '#00B894', '#00CEC9', '#FDCB6E',
    '#E17055', '#D63031', '#E84393', '#A29BFE', '#FF7675',
    '#636E72', '#2D3436', '#FAB1A0', '#55EFC4',
  ];
}
