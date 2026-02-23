import 'package:flutter/material.dart';
import '../services/category_service.dart';

// Constantes pour les catégories du magasin informatique (catégories par défaut)
const List<String> defaultProductCategories = [
  'PC',
  'Ordinateur Portable',
  'Écran',
  'Clavier',
  'Souris',
  'Casque Audio',
  'AirPods',
  'Webcam',
  'Microphone',
  'Disque Dur',
  'SSD',
  'RAM',
  'Carte Graphique',
  'Processeur',
  'Tablette',
  'Smartphone',
  'Routeur',
  'Câble',
  'Adaptateur',
  'Imprimante',
  'Scanner',
  'Projecteur',
  'Accessoires',
  'Autre',
];

// Map pour les icônes par catégorie (icônes par défaut)
Map<String, IconData> defaultCategoryIcons = {
  'PC': Icons.computer,
  'Ordinateur Portable': Icons.laptop,
  'Écran': Icons.tv,
  'Clavier': Icons.keyboard,
  'Souris': Icons.mouse,
  'Casque Audio': Icons.headphones,
  'AirPods': Icons.headset,
  'Webcam': Icons.videocam,
  'Microphone': Icons.mic,
  'Disque Dur': Icons.storage,
  'SSD': Icons.sd_storage,
  'RAM': Icons.memory,
  'Carte Graphique': Icons.video_chat,
  'Processeur': Icons.memory,
  'Tablette': Icons.tablet,
  'Smartphone': Icons.phone_android,
  'Routeur': Icons.router,
  'Câble': Icons.usb,
  'Adaptateur': Icons.power,
  'Imprimante': Icons.print,
  'Scanner': Icons.scanner,
  'Projecteur': Icons.slideshow,
  'Accessoires': Icons.build,
  'Autre': Icons.category,
};

// Couleurs par catégorie (couleurs par défaut)
Map<String, Color> defaultCategoryColors = {
  'PC': Colors.blue,
  'Ordinateur Portable': Colors.indigo,
  'Écran': Colors.cyan,
  'Clavier': Colors.teal,
  'Souris': Colors.green,
  'Casque Audio': Colors.purple,
  'AirPods': Colors.deepPurple,
  'Webcam': Colors.orange,
  'Microphone': Colors.deepOrange,
  'Disque Dur': Colors.brown,
  'SSD': Colors.blueGrey,
  'RAM': Colors.red,
  'Carte Graphique': Colors.pink,
  'Processeur': Colors.amber,
  'Tablette': Colors.lightBlue,
  'Smartphone': Colors.lightGreen,
  'Routeur': Colors.lime,
  'Câble': Colors.yellow,
  'Adaptateur': Colors.amber,
  'Imprimante': Colors.cyan,
  'Scanner': Colors.teal,
  'Projecteur': Colors.indigo,
  'Accessoires': Colors.grey,
  'Autre': Colors.grey,
};

// Getters dynamiques qui utilisent le service
List<String> get productCategories => CategoryService().categories;
Map<String, IconData> get categoryIcons => CategoryService().icons;
Map<String, Color> get categoryColors => CategoryService().colors;

// Fonction d'initialisation à appeler au démarrage de l'app
Future<void> initializeCategories() async {
  await CategoryService().initialize();
}
