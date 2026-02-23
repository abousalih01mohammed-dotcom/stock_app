import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_app/screens/add_product_screen.dart';
import 'package:stock_app/screens/view_stock_screen.dart';
import 'package:stock_app/screens/lock_screen.dart';
import 'package:stock_app/theme/app_theme.dart';
import 'package:stock_app/widgets/glass_card.dart';
import 'package:stock_app/widgets/neumorphic_button.dart';
import 'package:stock_app/constants/categories.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final bool firebaseInitialized;

  const HomeScreen({super.key, required this.firebaseInitialized});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  // Animation pour le carrousel publicitaire
  late PageController _pageController;
  late AnimationController _autoScrollController;
  int _currentAdPage = 0;

  // État des notifications de diminution de stock
  List<Map<String, dynamic>> _stockDecreaseNotifications = [];
  bool _hasNotifications = false;

  // Map pour stocker les anciennes valeurs des quantités
  Map<String, int> _previousQuantities = {};

  // Référence Firestore pour les notifications
  late CollectionReference _notificationsRef;

  // État de la recherche (version améliorée comme ViewStockScreen)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilterCategory = 'Toutes';
  List<QueryDocumentSnapshot> _filteredProducts = [];
  bool _isSearching = false;
  bool _showSearchBar = false;
  final formatCurrency = NumberFormat('#,##0', 'fr_FR');

  // Données pour le carrousel publicitaire
  final List<Map<String, dynamic>> _advertisements = [
    {
      'title': 'LAKRIRAA STOCK',
      'subtitle': 'Gestion de stock professionnelle',
      'color1': AppTheme.primaryPurple,
      'color2': AppTheme.electricBlue,
      'icon': Icons.inventory_2_rounded,
    },
    {
      'title': 'STOCK LAKRIRAA',
      'subtitle': 'Simple & Efficace',
      'color1': AppTheme.electricBlue,
      'color2': AppTheme.neonPink,
      'icon': Icons.storage_rounded,
    },
    {
      'title': 'LAKRIRAA',
      'subtitle': 'Votre partenaire de confiance',
      'color1': AppTheme.neonPink,
      'color2': AppTheme.primaryPurple,
      'icon': Icons.verified_rounded,
    },
    {
      'title': 'STOCK PRO',
      'subtitle': 'Par Lakriraa',
      'color1': AppTheme.secondaryPurple,
      'color2': AppTheme.electricBlue,
      'icon': Icons.analytics_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Initialiser le carrousel publicitaire
    _pageController = PageController(initialPage: 0);
    _autoScrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Auto-défilement du carrousel
    _autoScrollController.addListener(() {
      if (_autoScrollController.isCompleted) {
        if (mounted) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          setState(() {
            _currentAdPage = (_currentAdPage + 1) % _advertisements.length;
          });
        }
        _autoScrollController.reset();
      }
    });

    // Initialiser la référence Firestore
    _notificationsRef = FirebaseFirestore.instance.collection('notifications');

    // Charger les notifications existantes
    _loadNotifications();

    // Écouter les diminutions de stock
    _listenToStockDecreases();

    // Initialiser les quantités précédentes
    _initializePreviousQuantities();

    // Vérifier périodiquement les notifications expirées
    _startExpiryChecker();

    // Ajouter le listener de recherche (comme dans ViewStockScreen)
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  // Méthode de filtrage des produits (comme dans ViewStockScreen)
  List<QueryDocumentSnapshot> _filterProducts(
    List<QueryDocumentSnapshot> products,
  ) {
    if (_searchQuery.isEmpty && _selectedFilterCategory == 'Toutes') {
      return [];
    }

    return products.where((product) {
      final data = product.data() as Map<String, dynamic>?;
      final productName = data?['name']?.toString().toLowerCase() ?? '';
      final productCategory = data?['category']?.toString() ?? '';
      final productDescription =
          data?['description']?.toString().toLowerCase() ?? '';

      // Filtre par catégorie
      if (_selectedFilterCategory != 'Toutes' &&
          productCategory != _selectedFilterCategory) {
        return false;
      }

      // Filtre par recherche (nom, catégorie ou description)
      if (_searchQuery.isNotEmpty) {
        return productName.contains(_searchQuery) ||
            productCategory.toLowerCase().contains(_searchQuery) ||
            productDescription.contains(_searchQuery);
      }

      return true;
    }).toList();
  }

  // Afficher les détails d'un produit
  void _showProductDetails(QueryDocumentSnapshot product) {
    final data = product.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkBg,
          title: Text(
            data['name'] ?? 'Détails du produit',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        data['imageUrl'],
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 150,
                          width: 150,
                          color: AppTheme.glassEffect,
                          child: Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Catégorie',
                  data['category'] ?? 'Non spécifié',
                ),
                _buildDetailRow('Quantité', '${data['quantity'] ?? 0}'),
                _buildDetailRow('Prix', '${data['price'] ?? 0} MAD'),
                if (data['description'] != null &&
                    data['description'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description:',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['description'],
                          style: GoogleFonts.inter(color: Colors.grey.shade300),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(color: AppTheme.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  // Afficher le bottom sheet de filtre (comme dans ViewStockScreen)
  void _showFilterBottomSheet(BuildContext context) {
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
              ...productCategories.map((category) {
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
                          categoryIcons[category] ?? Icons.category,
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
              if (_selectedFilterCategory != 'Toutes')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: () {
                      setState(() => _selectedFilterCategory = 'Toutes');
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Effacer le filtre',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Charger les notifications depuis Firestore
  Future<void> _loadNotifications() async {
    if (!widget.firebaseInitialized) return;

    try {
      final now = DateTime.now();
      final snapshot = await _notificationsRef
          .where('expiry', isGreaterThan: now)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _stockDecreaseNotifications = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'productId': data['productId'],
            'productName': data['productName'],
            'oldQuantity': data['oldQuantity'],
            'newQuantity': data['newQuantity'],
            'decreaseAmount': data['decreaseAmount'],
            'timestamp': (data['timestamp'] as Timestamp).toDate(),
            'expiry': (data['expiry'] as Timestamp).toDate(),
            'category': data['category'],
            'imageUrl': data['imageUrl'] ?? '',
          };
        }).toList();
        _hasNotifications = _stockDecreaseNotifications.isNotEmpty;
      });
    } catch (e) {
      print('❌ Erreur chargement notifications: $e');
    }
  }

  // Sauvegarder une notification dans Firestore
  Future<void> _saveNotification(Map<String, dynamic> notification) async {
    if (!widget.firebaseInitialized) return;

    try {
      await _notificationsRef.doc(notification['id']).set({
        'productId': notification['productId'],
        'productName': notification['productName'],
        'oldQuantity': notification['oldQuantity'],
        'newQuantity': notification['newQuantity'],
        'decreaseAmount': notification['decreaseAmount'],
        'timestamp': Timestamp.fromDate(notification['timestamp']),
        'expiry': Timestamp.fromDate(notification['expiry']),
        'category': notification['category'],
        'imageUrl': notification['imageUrl'],
        'read': false,
      });
    } catch (e) {
      print('❌ Erreur sauvegarde notification: $e');
    }
  }

  // Supprimer une notification de Firestore
  Future<void> _deleteNotification(String notificationId) async {
    if (!widget.firebaseInitialized) return;

    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      print('❌ Erreur suppression notification: $e');
    }
  }

  Future<void> _initializePreviousQuantities() async {
    if (!widget.firebaseInitialized) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stock')
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _previousQuantities[doc.id] = data['quantity'] as int? ?? 0;
      }
    } catch (e) {
      print('❌ Erreur initialisation quantités: $e');
    }
  }

  void _listenToStockDecreases() {
    if (!widget.firebaseInitialized) return;

    FirebaseFirestore.instance.collection('stock').snapshots().listen((
      snapshot,
    ) {
      if (!mounted) return;

      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.modified) {
          final docId = docChange.doc.id;
          final newData = docChange.doc.data() as Map<String, dynamic>;
          final newQuantity = newData['quantity'] as int? ?? 0;

          final oldQuantity = _previousQuantities[docId] ?? newQuantity;

          if (newQuantity < oldQuantity) {
            final decreaseAmount = oldQuantity - newQuantity;
            final now = DateTime.now();
            final notificationId = '${docId}_${now.millisecondsSinceEpoch}';

            final newNotification = {
              'id': notificationId,
              'productId': docId,
              'productName': newData['name'] ?? 'Produit inconnu',
              'oldQuantity': oldQuantity,
              'newQuantity': newQuantity,
              'decreaseAmount': decreaseAmount,
              'timestamp': now,
              'expiry': now.add(const Duration(days: 1)),
              'category': newData['category'] ?? 'Autre',
              'imageUrl': newData['imageUrl'] ?? '',
            };

            _saveNotification(newNotification);

            setState(() {
              _stockDecreaseNotifications.add(newNotification);
              _previousQuantities[docId] = newQuantity;
              _cleanExpiredNotifications();
              _hasNotifications = _stockDecreaseNotifications.isNotEmpty;
            });
          } else {
            _previousQuantities[docId] = newQuantity;
          }
        } else if (docChange.type == DocumentChangeType.added) {
          final docId = docChange.doc.id;
          final newData = docChange.doc.data() as Map<String, dynamic>;
          _previousQuantities[docId] = newData['quantity'] as int? ?? 0;
        }
      }
    });
  }

  void _cleanExpiredNotifications() {
    final now = DateTime.now();
    final expiredIds = <String>[];

    _stockDecreaseNotifications.removeWhere((notification) {
      final expiry = notification['expiry'] as DateTime;
      final isExpired = expiry.isBefore(now);
      if (isExpired) {
        expiredIds.add(notification['id']);
      }
      return isExpired;
    });

    for (var id in expiredIds) {
      _deleteNotification(id);
    }
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkBg,
          title: Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: AppTheme.electricBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Alerte Stock',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: _stockDecreaseNotifications.isEmpty
                ? Center(
                    child: Text(
                      'Aucune notification',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _stockDecreaseNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _stockDecreaseNotifications[index];
                      final expiry = notification['expiry'] as DateTime;
                      final timeLeft = expiry.difference(DateTime.now());
                      final hoursLeft = timeLeft.inHours;
                      final minutesLeft = timeLeft.inMinutes % 60;

                      Color urgencyColor = hoursLeft < 6
                          ? AppTheme.errorRed
                          : hoursLeft < 12
                          ? AppTheme.warningOrange
                          : AppTheme.electricBlue;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: AppTheme.glassEffect,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: urgencyColor.withOpacity(0.3),
                          ),
                        ),
                        child: ListTile(
                          leading: notification['imageUrl'].isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    notification['imageUrl'],
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 40,
                                      height: 40,
                                      color: AppTheme.glassEffect,
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.glassEffect,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.inventory,
                                    color: Colors.grey,
                                  ),
                                ),
                          title: Text(
                            notification['productName'],
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stock: ${notification['oldQuantity']} → ${notification['newQuantity']} (‑${notification['decreaseAmount']})',
                                style: GoogleFonts.inter(
                                  color: urgencyColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 12,
                                    color: urgencyColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expire dans: ${hoursLeft}h ${minutesLeft}min',
                                    style: GoogleFonts.inter(
                                      color: urgencyColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: Colors.grey),
                            onPressed: () async {
                              await _deleteNotification(notification['id']);
                              setState(() {
                                _stockDecreaseNotifications.removeAt(index);
                                _hasNotifications =
                                    _stockDecreaseNotifications.isNotEmpty;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            if (_stockDecreaseNotifications.isNotEmpty)
              TextButton(
                onPressed: () async {
                  for (var notification in _stockDecreaseNotifications) {
                    await _deleteNotification(notification['id']);
                  }
                  setState(() {
                    _stockDecreaseNotifications.clear();
                    _hasNotifications = false;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Tout effacer'),
              ),
          ],
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _selectedFilterCategory = 'Toutes';
      }
    });
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LockScreen(firebaseInitialized: widget.firebaseInitialized),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var fade = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );
          var scale = Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          );
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }

  void _startExpiryChecker() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        setState(() {
          _cleanExpiredNotifications();
          _hasNotifications = _stockDecreaseNotifications.isNotEmpty;
        });
        _startExpiryChecker();
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    _autoScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: CyberpunkBackgroundPainter(
                    animation: _backgroundAnimation.value,
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('stock')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            // Déterminer les produits filtrés
            if (snapshot.hasData && snapshot.data != null) {
              _filteredProducts = _filterProducts(snapshot.data!.docs);
            }

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220,
                  floating: true,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.cyberGradient,
                              boxShadow: AppTheme.neonShadow,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/lakriraastock.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LAKRIRAA',
                            style: GoogleFonts.orbitron(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [AppTheme.primaryPurple, AppTheme.darkBg],
                          radius: 1.5,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BIENVENUE',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.7),
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'GESTIONNAIRE',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    // Bouton de recherche
                    IconButton(
                      icon: Icon(
                        _showSearchBar ? Icons.close : Icons.search_rounded,
                        size: 24,
                      ),
                      onPressed: _toggleSearch,
                      tooltip: _showSearchBar
                          ? 'Fermer la recherche'
                          : 'Rechercher',
                    ),
                    // Bouton de filtre (apparaît seulement quand la recherche est active)
                    if (_showSearchBar)
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
                    // Notifications
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, size: 24),
                          onPressed: () {
                            if (_hasNotifications) {
                              _showNotificationDialog(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Aucune notification'),
                                  backgroundColor: Colors.grey,
                                ),
                              );
                            }
                          },
                        ),
                        if (_hasNotifications)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppTheme.neonPink,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        if (_hasNotifications)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              child: Text(
                                '${_stockDecreaseNotifications.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 24),
                      onPressed: _logout,
                      tooltip: 'Déconnexion',
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // Barre de recherche (si active)
                if (_showSearchBar)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
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
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText:
                                    'Rechercher par nom, catégorie ou description...',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.grey,
                                ),
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
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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

                // ALERTE SI NOTIFICATIONS EN ATTENTE
                if (_hasNotifications && !_showSearchBar)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: GestureDetector(
                        onTap: () => _showNotificationDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.electricBlue.withOpacity(0.2),
                                AppTheme.primaryPurple.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.electricBlue.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.electricBlue.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_active_rounded,
                                  color: AppTheme.electricBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notifications',
                                      style: GoogleFonts.orbitron(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${_stockDecreaseNotifications.length} notification${_stockDecreaseNotifications.length > 1 ? 's' : ''} de stock',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // RÉSULTATS DE RECHERCHE (si actifs)
                if (_showSearchBar && _filteredProducts.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = _filteredProducts[index];
                        final data = product.data() as Map<String, dynamic>;
                        final quantity =
                            (data['quantity'] as num?)?.toInt() ?? 0;
                        final price =
                            (data['price'] as num?)?.toDouble() ?? 0.0;

                        Color stockColor = quantity <= 5
                            ? AppTheme.errorRed
                            : quantity <= 10
                            ? AppTheme.warningOrange
                            : AppTheme.successGreen;

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50,
                            child: FadeInAnimation(
                              child: GestureDetector(
                                onTap: () => _showProductDetails(product),
                                child: GlassCard(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Image du produit avec indicateur de stock
                                      Stack(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: AppTheme.glassEffect,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child:
                                                data['imageUrl'] != null &&
                                                    data['imageUrl'].isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.network(
                                                      data['imageUrl'],
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (_, __, ___) => Icon(
                                                            Icons.image,
                                                            color: Colors.grey,
                                                          ),
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons
                                                        .image_not_supported_rounded,
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
                                      const SizedBox(width: 12),
                                      // Informations du produit
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['name'] ?? 'Sans nom',
                                              style: GoogleFonts.orbitron(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${data['category'] ?? 'Autre'}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppTheme.primaryPurple,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: stockColor
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: stockColor,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '$quantity en stock',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      color: stockColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${formatCurrency.format(price)} MAD',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color:
                                                        AppTheme.electricBlue,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Flèche pour détails
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryPurple
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: AppTheme.primaryPurple,
                                          size: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }, childCount: _filteredProducts.length),
                    ),
                  ),

                // MESSAGE SI AUCUN RÉSULTAT DE RECHERCHE
                if (_showSearchBar &&
                    _searchQuery.isNotEmpty &&
                    _filteredProducts.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun résultat trouvé',
                              style: GoogleFonts.orbitron(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Essayez avec d\'autres termes',
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // MENUS PRINCIPAUX (si recherche inactive ou sans résultats)
                if (!_showSearchBar ||
                    (_showSearchBar &&
                        _filteredProducts.isEmpty &&
                        _searchQuery.isEmpty)) ...[
                  // MENUS PRINCIPAUX (icônes seulement)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final menus = [
                          {
                            'icon': Icons.add_circle_outline,
                            'color': AppTheme.primaryPurple,
                            'route': const AddProductScreen(),
                            'tooltip': 'Ajouter un produit',
                          },
                          {
                            'icon': Icons.storage_rounded,
                            'color': AppTheme.electricBlue,
                            'route': const ViewStockScreen(),
                            'tooltip': 'Voir le stock',
                          },
                        ];

                        final menu = menus[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 800),
                          child: SlideAnimation(
                            verticalOffset: 100,
                            curve: Curves.elasticOut,
                            child: FadeInAnimation(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: NeumorphicButton(
                                  isActive: true,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => menu['route'] as Widget,
                                        transitionsBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
                                              var fade =
                                                  Tween<double>(
                                                    begin: 0.0,
                                                    end: 1.0,
                                                  ).animate(
                                                    CurvedAnimation(
                                                      parent: animation,
                                                      curve: Curves.easeInOut,
                                                    ),
                                                  );
                                              var scale =
                                                  Tween<double>(
                                                    begin: 0.8,
                                                    end: 1.0,
                                                  ).animate(
                                                    CurvedAnimation(
                                                      parent: animation,
                                                      curve: Curves.elasticOut,
                                                    ),
                                                  );
                                              return FadeTransition(
                                                opacity: fade,
                                                child: ScaleTransition(
                                                  scale: scale,
                                                  child: child,
                                                ),
                                              );
                                            },
                                      ),
                                    );
                                  },
                                  child: Center(
                                    child: Icon(
                                      menu['icon'] as IconData,
                                      color: menu['color'] as Color,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }, childCount: 2),
                    ),
                  ),

                  // CARROUSEL PUBLICITAIRE
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            height: 150,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _advertisements.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentAdPage = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final ad = _advertisements[index];
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [ad['color1'], ad['color2']],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ad['color1'].withOpacity(0.5),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Effet de brillance
                                      Positioned.fill(
                                        child: Opacity(
                                          opacity: 0.1,
                                          child: Icon(
                                            ad['icon'],
                                            size: 100,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              ad['title'],
                                              style: GoogleFonts.orbitron(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: 2,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    blurRadius: 10,
                                                    offset: const Offset(2, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              ad['subtitle'],
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Indicateurs de page
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _advertisements.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: _currentAdPage == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: _currentAdPage == index
                                      ? LinearGradient(
                                          colors: [
                                            _advertisements[index]['color1'],
                                            _advertisements[index]['color2'],
                                          ],
                                        )
                                      : null,
                                  color: _currentAdPage == index
                                      ? null
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// PAINTER POUR FOND CYBERPUNK
class CyberpunkBackgroundPainter extends CustomPainter {
  final double animation;

  CyberpunkBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryPurple.withOpacity(0.1 * animation)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < size.width; i += 50) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }

    for (int i = 0; i < size.height; i += 50) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }

    final lightPaint = Paint()
      ..color = AppTheme.electricBlue.withOpacity(0.3 * animation)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    for (int i = 0; i < 10; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (i / 10) + (20 * animation),
          size.height * (i / 10) - (10 * animation),
        ),
        10,
        lightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CyberpunkBackgroundPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
