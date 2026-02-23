import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'edit_product_screen.dart';
import 'add_product_screen.dart';
import '../constants/categories.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/category_provider.dart';

class ViewStockScreen extends StatefulWidget {
  const ViewStockScreen({super.key});

  @override
  State<ViewStockScreen> createState() => _ViewStockScreenState();
}

class _ViewStockScreenState extends State<ViewStockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilterCategory = 'Toutes';
  bool _isUpdatingQuantity = false;

  // NOUVEAU: Set pour garder trace des catégories ouvertes
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(
        context,
        listen: false,
      ).addListener(_onCategoriesChanged);
    });
  }

  void _onCategoriesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    Provider.of<CategoryProvider>(
      context,
      listen: false,
    ).removeListener(_onCategoriesChanged);
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<QueryDocumentSnapshot>> _groupByCategory(
    List<QueryDocumentSnapshot> products,
  ) {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final currentCategories = categoryProvider.categories;

    Map<String, List<QueryDocumentSnapshot>> groupedProducts = {};

    for (String category in currentCategories) {
      groupedProducts[category] = [];
    }

    for (var product in products) {
      final data = product.data() as Map<String, dynamic>?;
      final category = data?['category'] ?? 'Autre';

      if (groupedProducts.containsKey(category)) {
        groupedProducts[category]!.add(product);
      } else {
        if (!groupedProducts.containsKey('Autre')) {
          groupedProducts['Autre'] = [];
        }
        groupedProducts['Autre']!.add(product);
      }
    }

    groupedProducts.removeWhere((key, value) => value.isEmpty);
    return groupedProducts;
  }

  List<QueryDocumentSnapshot> _filterProducts(
    List<QueryDocumentSnapshot> products,
  ) {
    return products.where((product) {
      final data = product.data() as Map<String, dynamic>?;
      final productName = data?['name']?.toString().toLowerCase() ?? '';
      final productCategory = data?['category']?.toString() ?? '';

      if (_selectedFilterCategory != 'Toutes' &&
          productCategory != _selectedFilterCategory) {
        return false;
      }

      if (_searchQuery.isNotEmpty && !productName.contains(_searchQuery)) {
        return false;
      }

      return true;
    }).toList();
  }

  int _getCategoryTotal(List<QueryDocumentSnapshot> products) {
    int total = 0;
    for (var product in products) {
      final data = product.data() as Map<String, dynamic>?;
      total += (data?['quantity'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  double _getCategoryValue(List<QueryDocumentSnapshot> products) {
    double total = 0;
    for (var product in products) {
      final data = product.data() as Map<String, dynamic>?;
      int quantity = (data?['quantity'] as num?)?.toInt() ?? 0;
      double price = (data?['price'] as num?)?.toDouble() ?? 0.0;
      total += quantity * price;
    }
    return total;
  }

  Future<void> _updateQuantity(
    String productId,
    int currentQuantity,
    bool increment,
  ) async {
    int newQuantity = increment ? currentQuantity + 1 : currentQuantity - 1;

    if (newQuantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La quantité ne peut pas être négative'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUpdatingQuantity = true);

    try {
      await FirebaseFirestore.instance
          .collection('stock')
          .doc(productId)
          .update({
            'quantity': newQuantity,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(increment ? '✅ +1 ajouté' : '✅ -1 retiré'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingQuantity = false);
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final categories = categoryProvider.categories;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filtrer par catégorie',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ...categories.map((category) {
                final isSelected = _selectedFilterCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFilterCategory = category);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppTheme.cyberGradient
                          : LinearGradient(
                              colors: [AppTheme.glassEffect, AppTheme.darkBg],
                            ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryPurple
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          categoryProvider.icons[category] ?? Icons.category,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.primaryPurple,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          category,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat('#,##0', 'fr_FR');
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          'Gestion du Stock',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.glassEffect,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryPurple,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                if (_selectedFilterCategory != 'Toutes')
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cyberGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Catégorie: $_selectedFilterCategory',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(
                            () => _selectedFilterCategory = 'Toutes',
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list_rounded),
                if (_selectedFilterCategory != 'Toutes')
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.neonPink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stock')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 80,
                    color: AppTheme.errorRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${snapshot.error}',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.glassEffect,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucun produit disponible',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter un produit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                    ),
                  ),
                ],
              ),
            );
          }

          final allProducts = snapshot.data!.docs;
          final filteredProducts = _filterProducts(allProducts);

          if (filteredProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun résultat trouvé',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final groupedProducts = _groupByCategory(filteredProducts);
          final categories = groupedProducts.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: () async {},
            color: AppTheme.primaryPurple,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final categoryProducts = groupedProducts[category]!;
                final categoryTotal = _getCategoryTotal(categoryProducts);
                final categoryValue = _getCategoryValue(categoryProducts);

                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: PageStorageKey<String>(
                        category,
                      ), // NOUVEAU: Clé unique pour chaque catégorie
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryProvider.icons[category] ??
                              Icons.category_rounded,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      title: Text(
                        category,
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        '${categoryProducts.length} article${categoryProducts.length > 1 ? 's' : ''} • $categoryTotal unités',
                        style: GoogleFonts.inter(
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${formatCurrency.format(categoryValue)} MAD',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 195, 195, 195),
                          ),
                        ),
                      ),

                      // NOUVEAU: Contrôle de l'état d'expansion
                      initiallyExpanded: _expandedCategories.contains(category),
                      onExpansionChanged: (expanded) {
                        setState(() {
                          if (expanded) {
                            _expandedCategories.add(category);
                          } else {
                            _expandedCategories.remove(category);
                          }
                        });
                      },

                      children: categoryProducts.map((product) {
                        final data = product.data() as Map<String, dynamic>?;
                        final imageUrl = data?['imageUrl'] ?? '';
                        final productName = data?['name'] ?? 'Nom inconnu';
                        final quantity =
                            (data?['quantity'] as num?)?.toInt() ?? 0;
                        final price =
                            (data?['price'] as num?)?.toDouble() ?? 0.0;
                        final productId = product.id;

                        Color stockColor = quantity <= 5
                            ? AppTheme.errorRed
                            : quantity <= 10
                            ? AppTheme.warningOrange
                            : AppTheme.successGreen;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.glassEffect),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Stack(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppTheme.glassEffect,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: imageUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                    ),
                                              ),
                                            )
                                          : Icon(
                                              Icons.image_not_supported_rounded,
                                              color: Colors.grey,
                                            ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: stockColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  productName,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category,
                                      style: GoogleFonts.inter(
                                        color: const Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Stock: $quantity unité(s) • ${formatCurrency.format(price)} MAD',
                                      style: GoogleFonts.inter(
                                        color: const Color.fromARGB(
                                          179,
                                          255,
                                          255,
                                          255,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.edit_rounded,
                                    color: AppTheme.primaryPurple,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditProductScreen(
                                          productId: product.id,
                                          productData: product,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassEffect,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.errorRed.withOpacity(0.8),
                                            AppTheme.errorRed,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.errorRed
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _isUpdatingQuantity
                                              ? null
                                              : () => _updateQuantity(
                                                  productId,
                                                  quantity,
                                                  false,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.remove_rounded,
                                              color: _isUpdatingQuantity
                                                  ? Colors.grey
                                                  : Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.darkBg,
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: AppTheme.primaryPurple,
                                          width: 2,
                                        ),
                                        boxShadow: AppTheme.neonShadow,
                                      ),
                                      child: Text(
                                        quantity.toString(),
                                        style: GoogleFonts.orbitron(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                            255,
                                            255,
                                            255,
                                            255,
                                          ),
                                        ),
                                      ),
                                    ),

                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.successGreen.withOpacity(
                                              0.8,
                                            ),
                                            AppTheme.successGreen,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.successGreen
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _isUpdatingQuantity
                                              ? null
                                              : () => _updateQuantity(
                                                  productId,
                                                  quantity,
                                                  true,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.add_rounded,
                                              color: _isUpdatingQuantity
                                                  ? Colors.grey
                                                  : Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
        backgroundColor: AppTheme.primaryPurple,
      ),
    );
  }
}
