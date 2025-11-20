import 'package:flutter/material.dart';

import '../../../data/models/customer/plans.dart';

class CreatePlanScreen extends StatefulWidget {
  final ProductFetchResult product;

  const CreatePlanScreen({super.key, required this.product});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  double downPayment = 0.0;
  String cadenceType = "monthly";
  bool commitmentEnabled = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product.data;

    return Scaffold(
      appBar: AppBar(title: Text(product['name'] ?? 'Product')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images carousel
            SizedBox(
              height: 200,
              child: PageView(
                children: (product['images'] as List<dynamic>? ?? [])
                    .map((url) => Image.network(url, fit: BoxFit.cover))
                    .toList(),
              ),
            ),
            SizedBox(height: 16),

            Text('Store: ${product['storeName'] ?? 'Store'}'),
            SizedBox(height: 8),
            Text('Total Price: ₦${product['price']}'),
            SizedBox(height: 16),

            // Down payment
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter down payment',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() {
                  downPayment = double.tryParse(v) ?? 0;
                });
              },
            ),
            SizedBox(height: 16),

            // Payment cadence
            DropdownButtonFormField<String>(
              value: cadenceType,
              items: ['daily', 'weekly', 'monthly']
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => cadenceType = val!),
              decoration: InputDecoration(
                labelText: 'Payment Frequency',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Commitment toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Enable Commitment'),
                Switch(
                  value: commitmentEnabled,
                  onChanged: (val) => setState(() => commitmentEnabled = val),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final walletBalance = await getWalletBalance(); // implement
                  if (walletBalance < downPayment) {
                    // Redirect to TopUp
                    Get.to(() => TopUpScreen());
                    return;
                  }

                  final plan = Plan.create(
                    generatedId: firestore.collection('plans').doc().id,
                    vendorId: product['vendorId'],
                    title: product['name'],
                    imageUrls: List<String>.from(product['images'] ?? []),
                    totalAmount: product['price'].toDouble(),
                    storeName: product['storeName'],
                    customerId: 'CURRENT_CUSTOMER_ID', // pass actual id
                    productCode: product['productCode'],
                    downPayment: downPayment,
                    cadenceType: cadenceType,
                    commitmentEnabled: commitmentEnabled,
                  );

                  await savePlan(plan); // implement repository save
                  Get.back(); // or navigate to plan detail
                },
                child: Text('Create Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
