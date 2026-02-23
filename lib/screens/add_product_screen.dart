import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/categories.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../services/category_service.dart';
import '../providers/category_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newCategoryController = TextEditingController();

  // NOUVEAU: Controller pour la recherche de catégories
  final TextEditingController _searchCategoryController =
      TextEditingController();

  bool _isUploading = false;
  String? _selectedImageUrl;
  String? _selectedCategory;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Liste dynamique des catégories
  late List<String> _categories;
  late Map<String, IconData> _icons;
  late Map<String, Color> _colors;

  // NOUVEAU: Liste filtrée pour la recherche
  List<String> _filteredCategories = [];

  @override
  void initState() {
    super.initState();

    // Initialiser les animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _animationController.forward();

    // Écouter les changements du provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(
        context,
        listen: false,
      ).addListener(_onCategoriesChanged);
    });

    // NOUVEAU: Écouter les changements dans la recherche
    _searchCategoryController.addListener(_filterCategories);

    _loadCategories();
  }

  // NOUVEAU: Filtrer les catégories selon la recherche
  void _filterCategories() {
    String query = _searchCategoryController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredCategories = List.from(_categories);
    } else {
      _filteredCategories = _categories
          .where((category) => category.toLowerCase().contains(query))
          .toList();
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Callback quand les catégories changent
  void _onCategoriesChanged() {
    if (mounted) {
      _loadCategories();
    }
  }

  void _loadCategories() {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    setState(() {
      _categories = List.from(categoryProvider.categories);
      _icons = Map.from(categoryProvider.icons);
      _colors = Map.from(categoryProvider.colors);
      _filteredCategories = List.from(
        _categories,
      ); // Initialiser la liste filtrée
    });
  }

  @override
  void dispose() {
    Provider.of<CategoryProvider>(
      context,
      listen: false,
    ).removeListener(_onCategoriesChanged);

    // NOUVEAU: Disposer le controller de recherche
    _searchCategoryController.dispose();

    _animationController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _categoryController.text = category;
    });
    Navigator.pop(context);
  }

  Future<void> _addNewCategory() async {
    String newCategory = _newCategoryController.text.trim();

    if (newCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Veuillez entrer un nom de catégorie'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_categories.contains(newCategory)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Cette catégorie existe déjà'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      await Provider.of<CategoryProvider>(
        context,
        listen: false,
      ).addCategory(newCategory);

      _newCategoryController.clear();
      _searchCategoryController
          .clear(); // NOUVEAU: Vider la recherche après ajout
      Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Catégorie "$newCategory" ajoutée avec succès'),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(String category) async {
    if (defaultProductCategories.contains(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.lock_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Impossible de supprimer une catégorie par défaut'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_selectedCategory == category) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Impossible de supprimer la catégorie sélectionnée'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.cardBg, AppTheme.darkBg],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: AppTheme.neonShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: AppTheme.errorRed,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Confirmation',
                  style: GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Voulez-vous vraiment supprimer la catégorie',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.primaryPurple, width: 1),
                  ),
                  child: Text(
                    '"$category"',
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cette action est irréversible.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorRed,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Supprimer',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      try {
        await Provider.of<CategoryProvider>(
          context,
          listen: false,
        ).removeCategory(category);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Catégorie "$category" supprimée'),
                ],
              ),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Erreur: $e')),
                ],
              ),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showCategoryDialog() {
    _filteredCategories = List.from(_categories); // Réinitialiser le filtre
    _searchCategoryController.clear(); // Vider la recherche

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.cardBg, AppTheme.darkBg],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: AppTheme.neonShadow,
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryPurple.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppTheme.cyberGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.category_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Choisir une catégorie',
                              style: GoogleFonts.orbitron(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            onPressed: () {
                              _newCategoryController.clear();
                              _searchCategoryController.clear();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Formulaire pour ajouter une nouvelle catégorie
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryPurple.withOpacity(0.1),
                              AppTheme.electricBlue.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryPurple.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newCategoryController,
                                style: GoogleFonts.inter(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Nouvelle catégorie...',
                                  hintStyle: GoogleFonts.inter(
                                    color: Colors.grey,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.add_rounded,
                                    color: AppTheme.primaryPurple,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) => _addNewCategory(),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: AppTheme.cyberGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: _addNewCategory,
                                tooltip: 'Ajouter une catégorie',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // NOUVEAU: Champ de recherche des catégories
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.glassEffect,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryPurple.withOpacity(0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _searchCategoryController,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Rechercher une catégorie...',
                            hintStyle: GoogleFonts.inter(color: Colors.grey),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppTheme.primaryPurple,
                            ),
                            suffixIcon:
                                _searchCategoryController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _searchCategoryController.clear();
                                      setState(() {
                                        _filteredCategories = List.from(
                                          _categories,
                                        );
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value.isEmpty) {
                                _filteredCategories = List.from(_categories);
                              } else {
                                _filteredCategories = _categories
                                    .where(
                                      (category) => category
                                          .toLowerCase()
                                          .contains(value.toLowerCase()),
                                    )
                                    .toList();
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Liste des catégories filtrées
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: _filteredCategories.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchCategoryController.text.isEmpty
                                          ? 'Aucune catégorie'
                                          : 'Aucune catégorie trouvée',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredCategories.length,
                                itemBuilder: (context, index) {
                                  final category = _filteredCategories[index];
                                  final isSelected =
                                      _selectedCategory == category;
                                  final isDefault = defaultProductCategories
                                      .contains(category);

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _selectCategory(category),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      AppTheme.primaryPurple
                                                          .withOpacity(0.3),
                                                      AppTheme.electricBlue
                                                          .withOpacity(0.3),
                                                    ],
                                                  )
                                                : null,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppTheme.primaryPurple
                                                  : Colors.white.withOpacity(
                                                      0.1,
                                                    ),
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Icône de la catégorie
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppTheme.primaryPurple
                                                            .withOpacity(0.2)
                                                      : AppTheme.glassEffect,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  _icons[category] ??
                                                      Icons.category_rounded,
                                                  color: isSelected
                                                      ? AppTheme.primaryPurple
                                                      : (_colors[category] ??
                                                            AppTheme
                                                                .primaryPurple),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Nom de la catégorie
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      category,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 16,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : Colors.white70,
                                                      ),
                                                    ),
                                                    if (isDefault)
                                                      Text(
                                                        'Catégorie par défaut',
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 11,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              // Badge sélection
                                              if (isSelected)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    right: 8,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppTheme.primaryPurple,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                ),
                                              // Bouton de suppression (seulement pour catégories non-défaut)
                                              if (!isDefault)
                                                IconButton(
                                                  icon: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      color:
                                                          Colors.red.shade300,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _deleteCategory(category),
                                                  tooltip:
                                                      'Supprimer la catégorie',
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),

                    // Footer
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppTheme.darkBg.withOpacity(0.9),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      Map<String, dynamic> productData = {
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'quantity': int.parse(_quantityController.text),
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      String imageUrl = _imageUrlController.text.trim();
      if (imageUrl.isNotEmpty) {
        if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
          productData['imageUrl'] = imageUrl;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.warning_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('URL invalide. Le produit sera ajouté sans image.'),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          productData['imageUrl'] = "";
        }
      } else {
        productData['imageUrl'] = "";
      }

      await FirebaseFirestore.instance.collection('stock').add(productData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Produit ajouté avec succès'),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Ajouter un produit',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cyberGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.neonShadow,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ajout en cours...',
                    style: GoogleFonts.orbitron(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veuillez patienter',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : GradientBackground(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Carte Informations produit
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.cardBg, AppTheme.darkBg],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppTheme.primaryPurple.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: AppTheme.neonShadow,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.cyberGradient,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.info_outline_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Informations générales',
                                        style: GoogleFonts.orbitron(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _nameController,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Nom du produit',
                                      labelStyle: GoogleFonts.inter(
                                        color: Colors.grey,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.shopping_bag_rounded,
                                        color: AppTheme.primaryPurple,
                                      ),
                                      hintText: 'Ex: PC Gamer ASUS',
                                      hintStyle: GoogleFonts.inter(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer le nom du produit';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Champ Catégorie
                                  InkWell(
                                    onTap: _showCategoryDialog,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.glassEffect,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.primaryPurple
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _selectedCategory != null
                                                ? (_icons[_selectedCategory] ??
                                                      Icons.category_rounded)
                                                : Icons.category_rounded,
                                            color: AppTheme.primaryPurple,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _selectedCategory ??
                                                  'Sélectionnez une catégorie',
                                              style: GoogleFonts.inter(
                                                color: _selectedCategory != null
                                                    ? Colors.white
                                                    : Colors.grey,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons
                                                .arrow_drop_down_circle_rounded,
                                            color: AppTheme.primaryPurple,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Controller caché pour validation
                                  const SizedBox(height: 0),
                                  TextFormField(
                                    controller: _categoryController,
                                    style: const TextStyle(
                                      height: 0,
                                      fontSize: 0,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez sélectionner une catégorie';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _descriptionController,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Description (optionnel)',
                                      labelStyle: GoogleFonts.inter(
                                        color: Colors.grey,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.description_rounded,
                                        color: AppTheme.primaryPurple,
                                      ),
                                      hintText: 'Description du produit...',
                                      hintStyle: GoogleFonts.inter(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Carte Quantité et Prix
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.cardBg, AppTheme.darkBg],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppTheme.primaryPurple.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: AppTheme.neonShadow,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.cyberGradient,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.inventory_2_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Stock et prix',
                                        style: GoogleFonts.orbitron(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _quantityController,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Quantité',
                                      labelStyle: GoogleFonts.inter(
                                        color: Colors.grey,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.numbers_rounded,
                                        color: AppTheme.primaryPurple,
                                      ),
                                      hintText: '0',
                                      hintStyle: GoogleFonts.inter(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer la quantité';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Veuillez entrer un nombre valide';
                                      }
                                      if (int.parse(value) < 0) {
                                        return 'La quantité ne peut pas être négative';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _priceController,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Prix (MAD)',
                                      labelStyle: GoogleFonts.inter(
                                        color: Colors.grey,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.attach_money_rounded,
                                        color: AppTheme.primaryPurple,
                                      ),
                                      hintText: '0.00',
                                      hintStyle: GoogleFonts.inter(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer le prix';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Veuillez entrer un prix valide';
                                      }
                                      if (double.parse(value) < 0) {
                                        return 'Le prix ne peut pas être négatif';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Carte Image
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.cardBg, AppTheme.darkBg],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppTheme.primaryPurple.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: AppTheme.neonShadow,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.cyberGradient,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.image_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Image du produit',
                                        style: GoogleFonts.orbitron(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _imageUrlController,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'URL de l\'image',
                                      labelStyle: GoogleFonts.inter(
                                        color: Colors.grey,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.link_rounded,
                                        color: AppTheme.primaryPurple,
                                      ),
                                      hintText: 'https://exemple.com/image.jpg',
                                      hintStyle: GoogleFonts.inter(
                                        color: Colors.grey,
                                      ),
                                      suffixIcon:
                                          _imageUrlController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.clear_rounded,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _imageUrlController.clear();
                                                  _selectedImageUrl = null;
                                                });
                                              },
                                            )
                                          : null,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedImageUrl = value;
                                      });
                                    },
                                  ),
                                  if (_selectedImageUrl != null &&
                                      _selectedImageUrl!.isNotEmpty &&
                                      (_selectedImageUrl!.startsWith('http')))
                                    Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.primaryPurple
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Stack(
                                          children: [
                                            Image.network(
                                              _selectedImageUrl!,
                                              height: 200,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      height: 200,
                                                      color: AppTheme.greyLight,
                                                      child: Center(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .broken_image_rounded,
                                                              size: 50,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              'Image invalide',
                                                              style:
                                                                  GoogleFonts.inter(
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                              loadingBuilder:
                                                  (
                                                    context,
                                                    child,
                                                    loadingProgress,
                                                  ) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Container(
                                                      height: 200,
                                                      color: AppTheme.greyLight,
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    );
                                                  },
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.7),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color:
                                                        AppTheme.primaryPurple,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: const [
                                                    Icon(
                                                      Icons.visibility_rounded,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Aperçu',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Bouton d'ajout
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.cyberGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.neonShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: addProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_circle_rounded),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AJOUTER LE PRODUIT',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
