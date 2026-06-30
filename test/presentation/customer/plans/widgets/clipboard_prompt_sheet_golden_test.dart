import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:korra/data/models/customer/customer_model.dart';
import 'package:korra/data/models/product_model.dart';
import 'package:korra/data/models/customer/plans.dart';
import 'package:korra/presentation/customer/plans/widgets/clipboard_scanner_helper.dart';
import 'package:korra/logic/bloc/vendor/product/vendor_products_state.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // Disable HTTP font fetching in testing sandbox
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('ClipboardPromptSheet Golden UI Test', (WidgetTester tester) async {
    // 1. Create Mock Instances
    final mockProduct = Product(
      id: 'prod_123',
      vendorId: 'vendor_456',
      storeName: 'Sneaker Hub',
      code: 'K-SMTN-91F175A',
      name: 'Nike Air Max 270',
      description: 'A premium lifestyle and running sneaker.',
      price: 85000.0,
      initialStock: 10,
      availableStock: 5,
      images: ['https://example.com/nike.jpg'],
      category: 'Footwear',
      status: ProductStatus.approved,
      modelType: ProductModelType.strict,
      cancellationPolicy: 'No Cancellation',
      extensionsEnabled: false,
      baseDuration: '10 Days',
      noticePeriod: '2 Days',
      totalMaxTime: '12 Days',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockCustomer = Customer(
      uid: 'cust_789',
      firstName: 'John',
      lastName: 'Doe',
      otherName: '',
      phone: '08012345678',
      email: 'john.doe@test.com',
      dob: DateTime(1995, 5, 15),
      gender: 'Male',
      address: '123 Korra Way',
      city: 'Lagos',
      stateName: 'Lagos State',
      nin: '12345678901',
      bvn: '22222222222',
      ninVerified: true,
      bvnVerified: true,
      walletReference: 'REF_789',
      accountNumber: '1234567890',
      accountName: 'JOHN DOE KORRA',
      bankName: 'Wema Bank',
      availableBalance: 120000.0,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockProductResult = ProductFetchResult(
      id: 'prod_123',
      data: {
        'name': 'Nike Air Max 270',
        'price': 85000.0,
        'storeName': 'Sneaker Hub',
      },
    );

    // 2. Render Widget in Isolated Frame with ScreenUtil Initialized
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844), // Standard mobile resolution
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ClipboardPromptSheet(
                product: mockProduct,
                productResult: mockProductResult,
                customer: mockCustomer,
                customerUid: 'cust_789',
                walletBalance: 120000.0,
              ),
            ),
          ),
        ),
      ),
    );

    // 3. Let font/image components pump and settle
    await tester.pumpAndSettle();

    // 4. Assert Golden File
    await expectLater(
      find.byType(ClipboardPromptSheet),
      matchesGoldenFile('goldens/clipboard_prompt_sheet.png'),
    );
  });
}
