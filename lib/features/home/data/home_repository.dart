import 'package:cloud_firestore/cloud_firestore.dart';

class HomeRepository {
  HomeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Map<String, dynamic>>> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getNews() {
    return _firestore
        .collection('news')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getMeals() {
    return _firestore
        .collection('meals')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getQuickModules() {
    return _firestore
        .collection('quick_modules')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
  }
}