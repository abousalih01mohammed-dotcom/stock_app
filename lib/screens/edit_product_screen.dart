import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../constants/categories.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final DocumentSnapshot productData;

  const EditProductScreen({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late String productName;
  late String category;
  late int quantity;
  late double price;
  late String description;
  File? _imageFile;
  bool _isUploading = false;
  String? _selectedCategory;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    final data = widget.productData.data() as Map<String, dynamic>;
    productName = data['name'] ?? '';
    category = data['category'] ?? '';
    quantity = data['quantity'] ?? 0;
    price = (data['price'] ?? 0).toDouble();
    description = data['description'] ?? '';
    _selectedCategory = category;
    _currentImageUrl = data['imageUrl'] ?? '';
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      this.category = category;
    });
    Navigator.pop(context);
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: 400,
            child: Column(
              children: [
                const Text(
                  'Choisir une catégorie',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: productCategories.length,
                    itemBuilder: (context, index) {
                      final cat = productCategories[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.veryLightPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            categoryIcons[cat] ?? Icons.category_rounded,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                        title: Text(cat),
                        onTap: () => _selectCategory(cat),
                        selected: _selectedCategory == cat,
                        selectedTileColor: AppTheme.veryLightPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String> uploadImage() async {
    if (_imageFile == null) return _currentImageUrl ?? '';

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = FirebaseStorage.instance.ref().child('products/$fileName');
    UploadTask uploadTask = ref.putFile(_imageFile!);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);

    try {
      String imageUrl = await uploadImage();

      await FirebaseFirestore.instance
          .collection('stock')
          .doc(widget.productId)
          .update({
        'name': productName,
        'category': category,
        'quantity': quantity,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Produit mis à jour avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> deleteProduct() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Voulez-vous vraiment supprimer ce produit ?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isUploading = true);
      try {
        await FirebaseFirestore.instance
            .collection('stock')
            .doc(widget.productId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produit supprimé'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat('#,##0', 'fr_FR');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Modifier le produit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                  ),
                  SizedBox(height: 20),
                  Text('Mise à jour en cours...',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          : GradientBackground(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Carte Image
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.veryLightPurple,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.image_rounded,
                                      color: AppTheme.primaryPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Image du produit',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: GestureDetector(
                                  onTap: pickImage,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppTheme.greyMedium,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: _imageFile != null
                                              ? Image.file(
                                                  _imageFile!,
                                                  width: 200,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                )
                                              : (_currentImageUrl != null &&
                                                      _currentImageUrl!
                                                          .isNotEmpty)
                                                  ? Image.network(
                                                      _currentImageUrl!,
                                                      width: 200,
                                                      height: 200,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          color: AppTheme
                                                              .greyLight,
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .broken_image_rounded,
                                                                size: 50,
                                                                color: Colors
                                                                    .grey
                                                                    .shade400,
                                                              ),
                                                              const Text(
                                                                  'Image invalide'),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Container(
                                                      color: AppTheme.greyLight,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .add_photo_alternate_rounded,
                                                            size: 50,
                                                            color: Colors
                                                                .grey.shade400,
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          Text(
                                                            'Appuyez pour\nchanger l\'image',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              color: Colors.grey
                                                                  .shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 5,
                                        bottom: 5,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryPurple,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.edit_rounded,
                                            color: Colors.white,
                                            size: 20,
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

                      const SizedBox(height: 16),

                      // Carte Informations
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.veryLightPurple,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      color: AppTheme.primaryPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Informations générales',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                initialValue: productName,
                                decoration: InputDecoration(
                                  labelText: 'Nom du produit',
                                  prefixIcon: Icon(
                                    Icons.shopping_bag_rounded,
                                    color: AppTheme.primaryPurple,
                                  ),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Veuillez entrer le nom'
                                    : null,
                                onChanged: (v) => productName = v,
                              ),
                              const SizedBox(height: 16),

                              // Sélecteur de catégorie
                              InkWell(
                                onTap: _showCategoryDialog,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Catégorie',
                                    prefixIcon: Icon(
                                      _selectedCategory != null
                                          ? (categoryIcons[_selectedCategory] ??
                                              Icons.category_rounded)
                                          : Icons.category_rounded,
                                      color: AppTheme.primaryPurple,
                                    ),
                                    suffixIcon: Icon(
                                      Icons.arrow_drop_down_circle_rounded,
                                      color: AppTheme.primaryPurple,
                                    ),
                                  ),
                                  child: Text(
                                    _selectedCategory ??
                                        'Sélectionnez une catégorie',
                                    style: TextStyle(
                                      color: _selectedCategory != null
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: description,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  prefixIcon: Icon(
                                    Icons.description_rounded,
                                    color: AppTheme.primaryPurple,
                                  ),
                                ),
                                maxLines: 3,
                                onChanged: (v) => description = v,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Carte Stock et Prix
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.veryLightPurple,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_rounded,
                                      color: AppTheme.primaryPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Stock et prix',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                initialValue: quantity.toString(),
                                decoration: InputDecoration(
                                  labelText: 'Quantité',
                                  prefixIcon: Icon(
                                    Icons.numbers_rounded,
                                    color: AppTheme.primaryPurple,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v == null || int.tryParse(v) == null
                                        ? 'Quantité invalide'
                                        : null,
                                onChanged: (v) =>
                                    quantity = int.tryParse(v) ?? 0,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: price.toString(),
                                decoration: InputDecoration(
                                  labelText: 'Prix (MAD)',
                                  prefixIcon: Icon(
                                    Icons.attach_money_rounded,
                                    color: AppTheme.primaryPurple,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v == null || double.tryParse(v) == null
                                        ? 'Prix invalide'
                                        : null,
                                onChanged: (v) =>
                                    price = double.tryParse(v) ?? 0.0,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Boutons d'action
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: updateProduct,
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Enregistrer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: deleteProduct,
                              icon: const Icon(Icons.delete_rounded),
                              label: const Text('Supprimer'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
