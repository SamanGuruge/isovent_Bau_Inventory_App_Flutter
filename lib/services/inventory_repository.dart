import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AuthRequiredException implements Exception {
  AuthRequiredException({required this.operation, required this.path});

  final String operation;
  final String path;

  @override
  String toString() =>
      'AuthRequiredException(operation: $operation, path: $path)';
}

class InventoryPermissionDeniedException implements Exception {
  InventoryPermissionDeniedException({
    required this.operation,
    required this.path,
    required this.uid,
  });

  final String operation;
  final String path;
  final String uid;

  @override
  String toString() =>
      'InventoryPermissionDeniedException(operation: $operation, path: $path, uid: $uid)';
}

class InventoryRepository {
  InventoryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  User _requireUser({required String operation, required String path}) {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthRequiredException(operation: operation, path: path);
    }
    return user;
  }

  bool _isPermissionDenied(FirebaseException e) =>
      e.code == 'permission-denied';

  void _logBlocked({
    required String operation,
    required String path,
    required String uid,
    String? error,
  }) {
    final projectId = Firebase.app().options.projectId;
    debugPrint(
      '[FirestoreBlocked] projectId=$projectId uid=$uid operation=$operation path=$path error=$error',
    );
  }

  void _logAuthRequired({required String operation, required String path}) {
    final projectId = Firebase.app().options.projectId;
    debugPrint(
      '[FirestoreSkipNoAuth] projectId=$projectId uid=null operation=$operation path=$path',
    );
  }

  Future<void> _signOutSilently() async {
    if (_auth.currentUser != null) {
      await _auth.signOut();
    }
  }

  Stream<List<Map<String, dynamic>>> streamCollection(
    String collection,
  ) async* {
    final path = '$collection/*';
    User user;
    try {
      user = _requireUser(operation: 'query', path: path);
    } on AuthRequiredException catch (e) {
      _logAuthRequired(operation: e.operation, path: e.path);
      yield const [];
      return;
    }

    try {
      await for (final snapshot
          in _firestore
              .collection(collection)
              .orderBy('createdAt', descending: true)
              .snapshots()) {
        yield snapshot.docs
            .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
            .toList();
      }
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) {
        _logBlocked(
          operation: 'query',
          path: path,
          uid: user.uid,
          error: e.message ?? e.code,
        );
        await _signOutSilently();
        throw InventoryPermissionDeniedException(
          operation: 'query',
          path: path,
          uid: user.uid,
        );
      }
      rethrow;
    }
  }

  Future<void> save(
    String collection,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final path = id == null || id.isEmpty ? '$collection/*' : '$collection/$id';
    User user;
    try {
      user = _requireUser(
        operation: id == null || id.isEmpty ? 'add' : 'set',
        path: path,
      );
    } on AuthRequiredException catch (e) {
      _logAuthRequired(operation: e.operation, path: e.path);
      return;
    }

    final payload = <String, dynamic>{
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (id == null || id.isEmpty) {
        await _firestore.collection(collection).add({
          ...payload,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      await _firestore
          .collection(collection)
          .doc(id)
          .set(payload, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) {
        _logBlocked(
          operation: id == null || id.isEmpty ? 'add' : 'set',
          path: path,
          uid: user.uid,
          error: e.message ?? e.code,
        );
        await _signOutSilently();
        return;
      }
      rethrow;
    }
  }

  Future<void> delete(String collection, String id) async {
    final path = '$collection/$id';
    User user;
    try {
      user = _requireUser(operation: 'delete', path: path);
    } on AuthRequiredException catch (e) {
      _logAuthRequired(operation: e.operation, path: e.path);
      return;
    }

    try {
      await _firestore.collection(collection).doc(id).delete();
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) {
        _logBlocked(
          operation: 'delete',
          path: path,
          uid: user.uid,
          error: e.message ?? e.code,
        );
        await _signOutSilently();
        return;
      }
      rethrow;
    }
  }

  Future<void> toggleStatus(String collection, String id, bool active) async {
    final path = '$collection/$id';
    User user;
    try {
      user = _requireUser(operation: 'update', path: path);
    } on AuthRequiredException catch (e) {
      _logAuthRequired(operation: e.operation, path: e.path);
      return;
    }

    try {
      await _firestore.collection(collection).doc(id).update({
        'status': active ? 'Active' : 'Inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) {
        _logBlocked(
          operation: 'update',
          path: path,
          uid: user.uid,
          error: e.message ?? e.code,
        );
        await _signOutSilently();
        return;
      }
      rethrow;
    }
  }

  Future<bool> existsWhere(
    String collection, {
    required String field,
    required dynamic value,
  }) async {
    final path = '$collection/*';
    User user;
    try {
      user = _requireUser(operation: 'query', path: path);
    } on AuthRequiredException catch (e) {
      _logAuthRequired(operation: e.operation, path: e.path);
      return true;
    }

    try {
      final snapshot = await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) {
        _logBlocked(
          operation: 'query',
          path: path,
          uid: user.uid,
          error: e.message ?? e.code,
        );
        await _signOutSilently();
        return true;
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCollection(String collection) async {
    final path = '$collection/*';
    User user;
    try {
      user = _requireUser(operation: 'get', path: path);
    } on AuthRequiredException catch (e) {
      _logAuthRequired(operation: e.operation, path: e.path);
      return const [];
    }

    try {
      final snapshot = await _firestore
          .collection(collection)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
          .toList();
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) {
        _logBlocked(
          operation: 'get',
          path: path,
          uid: user.uid,
          error: e.message ?? e.code,
        );
        await _signOutSilently();
        return const [];
      }
      rethrow;
    }
  }

  Future<void> ensureSeedData() async {
    const seedPath = 'meta/seed';
    User user;
    try {
      user = _requireUser(operation: 'get', path: seedPath);
    } on AuthRequiredException catch (e) {
      _logAuthRequired(operation: e.operation, path: e.path);
      return;
    }

    try {
      final seedRef = _firestore.collection('meta').doc('seed');
      final seedDoc = await seedRef.get();
      if (seedDoc.exists && (seedDoc.data()?['done'] == true)) {
        return;
      }

      await _seedBasicCollection('brands', [
        {'name': 'Lenovo', 'status': 'Active', 'image': 'L'},
        {'name': 'Beats', 'status': 'Active', 'image': 'B'},
        {'name': 'Nike', 'status': 'Active', 'image': 'N'},
        {'name': 'Apple', 'status': 'Active', 'image': 'A'},
        {'name': 'Amazon', 'status': 'Active', 'image': 'AM'},
      ]);

      await _seedBasicCollection('categories', [
        {'name': 'Computers', 'slug': 'computers', 'status': 'Active'},
        {'name': 'Electronics', 'slug': 'electronics', 'status': 'Active'},
        {'name': 'Shoe', 'slug': 'shoe', 'status': 'Active'},
        {'name': 'Furniture', 'slug': 'furniture', 'status': 'Active'},
        {'name': 'Bags', 'slug': 'bags', 'status': 'Active'},
      ]);

      await _seedBasicCollection('subCategories', [
        {
          'name': 'Laptop',
          'category': 'Computers',
          'code': 'CT001',
          'description': 'Efficient Productivity',
          'status': 'Active',
        },
        {
          'name': 'Desktop',
          'category': 'Computers',
          'code': 'CT002',
          'description': 'Compact Design',
          'status': 'Active',
        },
        {
          'name': 'Sneakers',
          'category': 'Shoe',
          'code': 'CT003',
          'description': 'Dynamic Grip',
          'status': 'Active',
        },
      ]);

      await _seedBasicCollection('units', [
        {
          'name': 'Kilograms',
          'shortName': 'kg',
          'noOfProducts': 25,
          'status': 'Active',
        },
        {
          'name': 'Liters',
          'shortName': 'l',
          'noOfProducts': 18,
          'status': 'Active',
        },
        {
          'name': 'Pieces',
          'shortName': 'pcs',
          'noOfProducts': 42,
          'status': 'Active',
        },
      ]);

      await _seedBasicCollection('variantAttributes', [
        {'name': 'Size', 'values': 'XS,S,M,L,XL', 'status': 'Active'},
        {'name': 'Color', 'values': 'Red,Blue,Green', 'status': 'Active'},
        {
          'name': 'Material',
          'values': 'Cotton,Leather,Synthetic',
          'status': 'Active',
        },
      ]);

      await _seedBasicCollection('warranties', [
        {
          'name': 'Replacement Warranty',
          'description': 'Covers replacement of faulty items',
          'duration': '2 Year',
          'status': 'Active',
        },
        {
          'name': 'On-Site Warranty',
          'description': 'Repairs done at customer location',
          'duration': '1 Year',
          'status': 'Active',
        },
      ]);

      await _seedBasicCollection('products', _sampleProducts());

      await seedRef.set({
        'done': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) {
        _logBlocked(
          operation: 'get/set',
          path: seedPath,
          uid: user.uid,
          error: e.message ?? e.code,
        );
        await _signOutSilently();
        throw InventoryPermissionDeniedException(
          operation: 'get/set',
          path: seedPath,
          uid: user.uid,
        );
      }
      rethrow;
    }
  }

  Future<void> seedProductsIfEmpty() async {
    try {
      _requireUser(operation: 'query', path: 'products/*');
    } on AuthRequiredException catch (e) {
      _logAuthRequired(operation: e.operation, path: e.path);
      return;
    }
    await _seedBasicCollection('products', _sampleProducts());
  }

  Future<void> saveManyProducts(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return;
    }
    User user;
    try {
      user = _requireUser(operation: 'batchSet', path: 'products/*');
    } on AuthRequiredException catch (e) {
      _logAuthRequired(operation: e.operation, path: e.path);
      return;
    }
    try {
      final batch = _firestore.batch();
      for (final row in rows) {
        final ref = _firestore.collection('products').doc();
        batch.set(ref, {
          ...row,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) {
        _logBlocked(
          operation: 'batchSet',
          path: 'products/*',
          uid: user.uid,
          error: e.message ?? e.code,
        );
        await _signOutSilently();
        return;
      }
      rethrow;
    }
  }

  Future<void> _seedBasicCollection(
    String collection,
    List<Map<String, dynamic>> rows,
  ) async {
    final path = '$collection/*';
    User user;
    try {
      user = _requireUser(operation: 'query', path: path);
    } on AuthRequiredException catch (e) {
      _logAuthRequired(operation: e.operation, path: e.path);
      return;
    }

    try {
      final existing = await _firestore.collection(collection).limit(1).get();
      if (existing.docs.isNotEmpty) {
        return;
      }

      final batch = _firestore.batch();
      for (final row in rows) {
        final ref = _firestore.collection(collection).doc();
        batch.set(ref, {
          ...row,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) {
        _logBlocked(
          operation: 'query/batchSet',
          path: path,
          uid: user.uid,
          error: e.message ?? e.code,
        );
        await _signOutSilently();
        return;
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> _sampleProducts() {
    return [
      {
        'sku': 'PT001',
        'name': 'Lenovo IdeaPad 3',
        'category': 'Computers',
        'brand': 'Lenovo',
        'price': 600,
        'unit': 'Pc',
        'qty': 100,
        'qtyAlert': 15,
        'store': 'Electro Mart',
        'warehouse': 'Lavish Warehouse',
        'createdBy': 'James Kirwin',
        'manufacturedDate': Timestamp.fromDate(DateTime(2024, 12, 24)),
        'expiryDate': Timestamp.fromDate(DateTime(2026, 12, 20)),
        'status': 'Active',
      },
      {
        'sku': 'PT002',
        'name': 'Beats Pro',
        'category': 'Electronics',
        'brand': 'Beats',
        'price': 160,
        'unit': 'Pc',
        'qty': 25,
        'qtyAlert': 20,
        'store': 'Quantum Gadgets',
        'warehouse': 'Quaint Warehouse',
        'createdBy': 'Francis Chang',
        'manufacturedDate': Timestamp.fromDate(DateTime(2024, 12, 10)),
        'expiryDate': Timestamp.fromDate(DateTime(2026, 12, 7)),
        'status': 'Active',
      },
      {
        'sku': 'PT003',
        'name': 'Nike Jordan',
        'category': 'Shoe',
        'brand': 'Nike',
        'price': 110,
        'unit': 'Pc',
        'qty': 8,
        'qtyAlert': 10,
        'store': 'Prime Bazaar',
        'warehouse': 'Traditional Warehouse',
        'createdBy': 'Antonio Engle',
        'manufacturedDate': Timestamp.fromDate(DateTime(2023, 11, 27)),
        'expiryDate': Timestamp.fromDate(DateTime(2024, 11, 20)),
        'status': 'Active',
      },
    ];
  }
}
