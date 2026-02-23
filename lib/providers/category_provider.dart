import 'package:flutter/material.dart';
import 'package:stock_app/services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider() {
    _init();
  }

  List<String> get categories => CategoryService().categories;
  Map<String, IconData> get icons => CategoryService().icons;
  Map<String, Color> get colors => CategoryService().colors;

  Future<void> _init() async {
    // S'enregistrer pour les mises à jour
    CategoryService().addListener(_onCategoriesChanged);
  }

  void _onCategoriesChanged() {
    notifyListeners();
  }

  Future<void> addCategory(String category) async {
    await CategoryService().addCategory(category);
    // notifyListeners sera appelé via le listener
  }

  Future<void> removeCategory(String category) async {
    await CategoryService().removeCategory(category);
    // notifyListeners sera appelé via le listener
  }

  Future<void> refresh() async {
    await CategoryService().refresh();
  }

  @override
  void dispose() {
    CategoryService().removeListener(_onCategoriesChanged);
    super.dispose();
  }
}
