import 'package:flutter/material.dart';
import '../features/home/home_page.dart';
import '../features/add/add_item_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String addItem = '/add-item';

  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const HomePage(),
    addItem: (context) => const AddItemPage(),
  };
}
