import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_app/screens/splash_screen.dart';
import 'package:stock_app/theme/app_theme.dart';
import 'package:stock_app/widgets/gradient_background.dart';
import 'package:stock_app/constants/categories.dart';
import 'package:stock_app/services/category_service.dart';
import 'package:stock_app/providers/category_provider.dart'; // NOUVEAU
import 'package:provider/provider.dart'; // NOUVEAU
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;

  try {
    // 1. Initialiser Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    print('🔥 Firebase connecté avec succès');

    // 2. MIGRATION: Transférer les anciennes catégories locales vers Firestore
    await CategoryService().migrateLocalCategories();
    print('📦 Migration des catégories terminée');

    // 3. CORRECTION: Déplacer les produits avec catégories invalides vers 'Autre'
    await _fixInvalidCategories();
    print('🔧 Correction des produits terminée');

    // 4. Initialiser les catégories
    await initializeCategories();
    print('📁 Catégories chargées');
  } catch (e) {
    print('❌ Erreur lors de l\'initialisation: $e');
  }

  runApp(
    // AJOUT DU PROVIDER POUR LA MISE À JOUR AUTOMATIQUE
    ChangeNotifierProvider(
      create: (context) => CategoryProvider(),
      child: MyApp(firebaseInitialized: firebaseInitialized),
    ),
  );
}

// 🔧 FONCTION DE CORRECTION DES CATÉGORIES INVALIDES
Future<void> _fixInvalidCategories() async {
  try {
    print('🔍 Vérification des catégories invalides...');

    // Récupérer toutes les catégories valides
    final validCategories = <String>{};

    // Ajouter les catégories par défaut
    validCategories.addAll(defaultProductCategories);

    // Ajouter les catégories personnalisées depuis Firestore
    try {
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      for (var doc in categoriesSnapshot.docs) {
        validCategories.add(doc['name'] as String);
      }
    } catch (e) {
      print('⚠️ Impossible de charger les catégories Firestore: $e');
    }

    // Récupérer tous les produits
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('stock')
        .get();

    int fixedCount = 0;
    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var product in productsSnapshot.docs) {
      final data = product.data();
      final category = data['category'] as String? ?? 'Autre';

      // Si la catégorie n'est pas valide, la changer en 'Autre'
      if (!validCategories.contains(category)) {
        print('🔄 Correction: "$category" -> "Autre" pour ${data['name']}');

        batch.update(product.reference, {
          'category': 'Autre',
          '_fixed_category': true,
          '_original_category': category,
          '_fixed_at': FieldValue.serverTimestamp(),
        });
        fixedCount++;
      }
    }

    if (fixedCount > 0) {
      await batch.commit();
      print('✅ $fixedCount produits corrigés (déplacés vers "Autre")');
    } else {
      print('✅ Aucun produit à corriger');
    }
  } catch (e) {
    print('❌ Erreur lors de la correction: $e');
  }
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;

  const MyApp({super.key, required this.firebaseInitialized});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lakriraa Stock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: GradientBackground(
        child: SplashScreen(firebaseInitialized: firebaseInitialized),
      ),
    );
  }
}
