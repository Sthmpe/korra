import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/customer/plans.dart';
import 'customer_repository.dart';

extension CustomerPlans on CustomerRepository {
  // -----------------------------------------------------------
  // 🔹 MAIN CREATE FLOW (Clean + Readable)
  // -----------------------------------------------------------
  Future<Plan?> createPlan({
    required String productCode,
    required String customerId,
    required double downPayment,
    String? cadenceType,
    required bool commitmentEnabled,
    required ProductFetchResult productFeteched,
  }) async {
    try {
      // 1. Load product
      final product = productFeteched.data;

      // 2. Validate stock
      if (!checkStock(product)) return null;

      // 3. Get wallet
      // final walletSnap = await getWallet(customerId);
      // if (walletSnap == null) return null;
      // final wallet = walletSnap.data()!;

      // 4. Check wallet balance
      // if (!checkBalance(wallet, downPayment)) return null;

      // 5. Create One-Time Account (Monnify – commented)
      // final String reservedAccountNumber = await createOneTimeAccount(
      //   customerId,
      //   downPayment,
      // );

      // 6. Deduct wallet
      // await deductWallet(customerId, downPayment);

      // 7. Internal auto-transfer (Monnify – commented)
      // await internalReserveTransfer(
      //   customerId,
      //   reservedAccountNumber,
      //   downPayment,
      // );

      // 8. Reduce stock
      await decreaseStock(productFeteched.id, product);

      // 9. Build plan model
      final plan = Plan.create(
        generatedId: firestore.collection("plans").doc().id,
        vendorId: product["vendorId"],
        title: product["name"],
        imageUrls: List<String>.from(product["images"] ?? []),
        totalAmount: product["price"].toDouble(),
        storeName: product["storeName"],
        customerId: customerId,
        productCode: productCode,
        downPayment: downPayment,
        cadenceType: cadenceType,
        commitmentEnabled: commitmentEnabled,
      );

      // 10. Save plan
      await savePlan(plan);

      return plan;
    } catch (e) {
      debugPrint("Error in creating reservation plan: $e");
      return null;
    }
  }

  // -----------------------------------------------------------
  // 🔸 HELPERS
  // -----------------------------------------------------------

  Future<ProductFetchResult?> getProduct(String productCode) async {
    final snap = await firestore
        .collection("products")
        .where("productCode", isEqualTo: productCode)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      debugPrint("❌ Product not found");
      return null;
    }

    final doc = snap.docs.first;

    return ProductFetchResult(data: doc.data(), id: doc.id);
  }

  bool checkStock(Map<String, dynamic> product) {
    final stock = product["availableStock"] ?? 0;
    if (stock <= 0) {
      debugPrint("❌ Product out of stock");
      return false;
    }
    return true;
  }

  // Future<DocumentSnapshot<Map<String, dynamic>>?> getWallet(
  //     String customerId) async {
  //   final snap = await firestore.collection(_wallets).doc(customerId).get();
  //   if (!snap.exists) {
  //     debugPrint("❌ Customer wallet missing");
  //     return null;
  //   }
  //   return snap;
  // }

  // bool checkBalance(Map<String, dynamic> wallet, double required) {
  //   final balance = wallet["balance"]?.toDouble() ?? 0;
  //   if (balance < required) {
  //     debugPrint("❌ Insufficient wallet balance");
  //     return false;
  //   }
  //   return true;
  // }

  // Future<void> deductWallet(String customerId, double amount) async {
  //   final walletRef = firestore.collection(_wallets).doc(customerId);

  //   await firestore.runTransaction((transaction) async {
  //     final snap = await transaction.get(walletRef);
  //     final balance = snap["balance"].toDouble();

  //     transaction.update(walletRef, {
  //       "balance": balance - amount,
  //       "updatedAt": DateTime.now(),
  //     });
  //   });
  // }

  Future<void> decreaseStock(String docId, Map<String, dynamic> product) async {
    final stock = (product["availableStock"] ?? 0);

    await firestore.collection("products").doc(docId).update({
      "availableStock": stock - 1,
      "updatedAt": DateTime.now(),
    });
  }

  // Future<String> _createOneTimeAccount(
  //   String customerId,
  //   double amount,
  // ) async {
  //   /*
  //   final account = await monnifyRepo.createReservedAccount(
  //     customerId: customerId,
  //     amount: amount,
  //   );
  //   return account.accountNumber;
  //   */
  //   return "TEMP-ACC"; // Remove later
  // }

  // Future<void> _internalReserveTransfer(
  //   String fromCustomerId,
  //   String toReservedAcc,
  //   double amount,
  // ) async {
  //   /*
  //   await monnifyRepo.internalWalletTransfer(...);
  //   */
  // }

  // -----------------------------------------------------------
  // 🔸 SAVE PLAN
  // -----------------------------------------------------------
  Future<void> savePlan(Plan plan) async {
    await firestore.collection("plans").doc(plan.id).set(plan.toMap());
  }

  // -----------------------------------------------------------
  // 🔸 FETCH PLANS (ALL for customer)
  // -----------------------------------------------------------
  Future<List<Plan>> fetchPlansByCustomer(String customerId) async {
    try {
      final snapshot = await firestore
          .collection("plans")
          .where("customerId", isEqualTo: customerId)
          .orderBy("createdAt", descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Plan.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching customer plans: $e");
      return [];
    }
  }

  // -----------------------------------------------------------
  // 🔸 FETCH PLANS PAGINATED
  // -----------------------------------------------------------
  Future<List<Plan>> fetchPlansPaginated({
    required String customerId,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    int limit = 10,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firestore
          .collection("plans")
          .where("customerId", isEqualTo: customerId)
          .orderBy("createdAt", descending: true)
          .limit(limit);

      if (lastDoc != null) query = query.startAfterDocument(lastDoc);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data(); // now Map<String, dynamic>
        return Plan.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint("Error fetching paginated plans: $e");
      return [];
    }
  }

  // -----------------------------------------------------------
  // 🔸 UPDATE PLAN
  // -----------------------------------------------------------
  Future<bool> updatePlan(String planId, Plan updated) async {
    try {
      await firestore.collection("plans").doc(planId).update({
        ...updated.toMap(),
        "updatedAt": DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint("Error updating plan: $e");
      return false;
    }
  }

  // -----------------------------------------------------------
  // 🔸 STREAM CUSTOMER PLANS (real-time)
  // -----------------------------------------------------------
  Stream<List<Plan>> streamCustomerPlans(String customerId) {
    return firestore
        .collection("plans")
        .where("customerId", isEqualTo: customerId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Plan.fromMap(doc.data(), doc.id)).toList(),
        );
  }
}
