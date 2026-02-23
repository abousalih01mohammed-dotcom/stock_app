import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/categories.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  List<String> _categories = [];
  Map<String, IconData> _icons = {};
  Map<String, Color> _colors = {};

  // Stream pour les mises à jour en temps réel
  Stream<QuerySnapshot>? _categoriesStream;
  final List<Function> _listeners = [];

  List<String> get categories => _categories;
  Map<String, IconData> get icons => _icons;
  Map<String, Color> get colors => _colors;

  // Initialiser depuis les constantes et Firestore
  Future<void> initialize() async {
    try {
      // 1. Charger les catégories de base (constantes)
      _categories = List.from(defaultProductCategories);
      _icons = Map.from(defaultCategoryIcons);
      _colors = Map.from(defaultCategoryColors);

      // 2. Charger les catégories personnalisées depuis Firestore
      await _loadFromFirestore();

      // 3. Sauvegarder en local pour mode hors-ligne
      await _saveToLocal();

      // 4. Démarrer l'écoute des changements en temps réel
      _startListening();
    } catch (e) {
      print('⚠️ Erreur Firestore: $e, utilisation du cache local');
      await _loadFromLocal();
    }
  }

  // Charger depuis Firestore
  Future<void> _loadFromFirestore() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final category = data['name'] as String;

        if (!_categories.contains(category)) {
          _categories.add(category);
          _icons[category] = Icons.category_rounded;
          _colors[category] = Colors.purple;
        }
      }
    } catch (e) {
      print('Erreur chargement Firestore: $e');
      rethrow;
    }
  }

  // Démarrer l'écoute en temps réel
  void _startListening() {
    _categoriesStream = FirebaseFirestore.instance
        .collection('categories')
        .orderBy('name')
        .snapshots();

    _categoriesStream!.listen((snapshot) {
      _handleFirestoreChanges(snapshot);
    });
  }

  // Gérer les changements Firestore
  void _handleFirestoreChanges(QuerySnapshot snapshot) {
    // Garder les catégories par défaut
    final updatedCategories = List<String>.from(defaultProductCategories);
    final updatedIcons = Map<String, IconData>.from(defaultCategoryIcons);
    final updatedColors = Map<String, Color>.from(defaultCategoryColors);

    // Ajouter les catégories de Firestore
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['name'] as String;

      if (!updatedCategories.contains(category)) {
        updatedCategories.add(category);
        updatedIcons[category] = Icons.category_rounded;
        updatedColors[category] = Colors.purple;
      }
    }

    // Trier les catégories
    updatedCategories.sort();

    // Mettre à jour les listes
    _categories = updatedCategories;
    _icons = updatedIcons;
    _colors = updatedColors;

    // Notifier les listeners
    _notifyListeners();

    // Sauvegarder en local
    _saveToLocal();
  }

  // Sauvegarde locale (cache)
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customCategories = _categories
          .where((c) => !defaultProductCategories.contains(c))
          .toList();
      await prefs.setStringList('custom_categories', customCategories);
    } catch (e) {
      print('Erreur sauvegarde locale: $e');
    }
  }

  // Chargement depuis le cache local
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customCategories = prefs.getStringList('custom_categories') ?? [];

      _categories = List.from(defaultProductCategories);

      for (var category in customCategories) {
        if (!_categories.contains(category)) {
          _categories.add(category);
          _icons[category] = Icons.category_rounded;
          _colors[category] = Colors.purple;
        }
      }

      _categories.sort();
    } catch (e) {
      print('Erreur chargement local: $e');
      _categories = List.from(defaultProductCategories);
    }
  }

  // Ajouter une catégorie
  Future<void> addCategory(String category) async {
    if (_categories.contains(category)) return;

    try {
      // Sauvegarder dans Firestore (le listener mettra à jour automatiquement)
      await FirebaseFirestore.instance.collection('categories').add({
        'name': category,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Pas besoin de mettre à jour manuellement, le listener le fera
    } catch (e) {
      print('❌ Erreur: $e');
      throw Exception('Impossible d\'ajouter la catégorie');
    }
  }

  // Supprimer une catégorie
  Future<void> removeCategory(String category) async {
    if (!_categories.contains(category)) return;
    if (defaultProductCategories.contains(category)) {
      throw Exception('Impossible de supprimer une catégorie par défaut');
    }

    try {
      // Vérifier si des produits utilisent cette catégorie
      final productsUsingCategory = await FirebaseFirestore.instance
          .collection('stock')
          .where('category', isEqualTo: category)
          .limit(1)
          .get();

      if (productsUsingCategory.docs.isNotEmpty) {
        throw Exception('Cette catégorie est utilisée par des produits');
      }

      // Supprimer de Firestore (le listener mettra à jour automatiquement)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('name', isEqualTo: category)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('❌ Erreur suppression: $e');
      rethrow;
    }
  }

  // Ajouter un listener pour les mises à jour
  void addListener(Function callback) {
    _listeners.add(callback);
  }

  // Retirer un listener
  void removeListener(Function callback) {
    _listeners.remove(callback);
  }

  // Notifier tous les listeners
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // Rafraîchir manuellement
  Future<void> refresh() async {
    await _loadFromFirestore();
    _notifyListeners();
  }

  // Migration des anciennes catégories locales vers Firestore
  Future<void> migrateLocalCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localCategories = prefs.getStringList('custom_categories') ?? [];

      for (var category in localCategories) {
        if (defaultProductCategories.contains(category)) continue;

        final existing = await FirebaseFirestore.instance
            .collection('categories')
            .where('name', isEqualTo: category)
            .get();

        if (existing.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('categories').add({
            'name': category,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await initialize();
    } catch (e) {
      print('Erreur migration: $e');
    }
  }
}
