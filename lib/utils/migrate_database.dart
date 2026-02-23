import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMigration {
  static Future<void> addDescriptionFieldToAllProducts() async {
    try {
      print('🔄 Début de la migration...');

      final snapshot = await FirebaseFirestore.instance
          .collection('stock')
          .get();
      int count = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Vérifier si le champ description existe déjà
        if (!data.containsKey('description')) {
          await doc.reference.update({'description': ''});
          count++;
          print('✅ Document ${doc.id} mis à jour');
        }
      }

      print('🎉 Migration terminée ! $count documents mis à jour.');
    } catch (e) {
      print('❌ Erreur lors de la migration: $e');
    }
  }
}
