import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../models/shopping_list_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _recipes =>
      _db.collection('recipes');
  CollectionReference<Map<String, dynamic>> get _shoppingLists =>
      _db.collection('shoppingLists');

  Future<void> saveUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<List<Recipe>> getRecipes() async {
    final snapshot = await _recipes.get();
    return snapshot.docs
        .map((doc) => Recipe.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<Recipe>> getRecipesByBudget(double budget) async {
    final snapshot = await _recipes
        .where('estimatedCost', isLessThanOrEqualTo: budget)
        .orderBy('estimatedCost')
        .get();
    return snapshot.docs
        .map((doc) => Recipe.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> saveShoppingList(ShoppingList list) async {
    await _shoppingLists.doc(list.id).set(list.toMap(), SetOptions(merge: true));
  }

  Future<void> addRecipe(Recipe recipe) async {
    await _recipes.doc(recipe.id).set(recipe.toMap(), SetOptions(merge: true));
  }

  Stream<List<Recipe>> watchRecipes() {
    return _recipes.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Recipe.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Generic CRUD utilities for any collection
  Future<void> createOrUpdateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection(collection).doc(docId).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<Map<String, dynamic>?> readDocument({
    required String collection,
    required String docId,
  }) async {
    final doc = await _db.collection(collection).doc(docId).get();
    return doc.data();
  }

  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    await _db.collection(collection).doc(docId).delete();
  }
}
