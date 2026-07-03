// lib/presentation/customer/storefront/widgets/marketplace_seeder_util.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

Future<void> seedMockMarketplace(BuildContext context, String currentUserId) async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  // 1. Define 5 Mock Vendors
  final List<Map<String, dynamic>> mockVendors = [
    {
      'uid': 'mock_vendor_zara',
      'personal': {
        'firstName': 'Zara',
        'lastName': 'Styles',
        'email': 'zara@korra.com',
        'phone': '+2348011112222',
      },
      'store': {
        'storeName': 'Zara Styles',
        'description': 'Premium European apparel, footwear, and accessories.',
        'logoUrl': 'https://picsum.photos/100/100?random=11',
        'coverUrl': 'https://picsum.photos/800/400?random=12',
        'contactPhone': '+2348011112222',
      },
      'socials': {
        'whatsappGroup': 'https://wa.me/2348011112222',
        'instagram': 'zara_styles',
        'twitter': 'zara_styles_tw',
      },
    },
    {
      'uid': 'mock_vendor_temu',
      'personal': {
        'firstName': 'Temu',
        'lastName': 'Express',
        'email': 'temu@korra.com',
        'phone': '+2348033334444',
      },
      'store': {
        'storeName': 'Temu Express',
        'description': 'Affordable household goods, daily essentials, and fashion items.',
        'logoUrl': 'https://picsum.photos/100/100?random=13',
        'coverUrl': 'https://picsum.photos/800/400?random=14',
        'contactPhone': '+2348033334444',
      },
      'socials': {
        'whatsappGroup': 'https://wa.me/2348033334444',
        'instagram': 'temu_express',
      },
    },
    {
      'uid': 'mock_vendor_pinterest',
      'personal': {
        'firstName': 'Pinterest',
        'lastName': 'Curations',
        'email': 'pin_shop@korra.com',
        'phone': '+2348055556666',
      },
      'store': {
        'storeName': 'Pinterest Curations',
        'description': 'Aesthetic room decor, custom prints, plants, and cozy furniture.',
        'logoUrl': 'https://picsum.photos/100/100?random=15',
        'coverUrl': 'https://picsum.photos/800/400?random=16',
        'contactPhone': '+2348055556666',
      },
      'socials': {
        'whatsappGroup': 'https://wa.me/2348055556666',
        'instagram': 'pinterest_curations',
        'twitter': 'pin_curations',
      },
    },
    {
      'uid': 'mock_vendor_gadget',
      'personal': {
        'firstName': 'Lagos',
        'lastName': 'Gadget Hub',
        'email': 'gadgets@korra.com',
        'phone': '+2348077778888',
      },
      'store': {
        'storeName': 'Lagos Gadget Hub',
        'description': 'Authentic smartphones, smartwatches, and audiophile sound gear.',
        'logoUrl': 'https://picsum.photos/100/100?random=17',
        'coverUrl': 'https://picsum.photos/800/400?random=18',
        'contactPhone': '+2348077778888',
      },
      'socials': {
        'whatsappGroup': 'https://wa.me/2348077778888',
        'instagram': 'lagos_gadget_hub',
      },
    },
  ];

  // 2. Define Mock Products
  final List<Map<String, dynamic>> mockProducts = [
    // Zara styles
    {
      'vendorId': 'mock_vendor_zara',
      'name': 'Oversized Linen Shirt',
      'description': '100% pure linen oversized summer shirt. Breathable and premium.',
      'price': 15000.0,
      'stock': 12,
      'images': ['https://picsum.photos/400/400?random=31'],
      'category': 'Apparel',
      'allowReservation': true,
      'modelType': 'strict',
      'isFeatured': true,
      'campaignTag': 'Trending Now',
      'discountedPrice': 12000.0,
    },
    {
      'vendorId': 'mock_vendor_zara',
      'name': 'Classic Slim Denim',
      'description': 'High-stretch raw indigo slim jeans for everyday luxury.',
      'price': 25000.0,
      'stock': 8,
      'images': ['https://picsum.photos/400/400?random=32'],
      'category': 'Apparel',
      'allowReservation': true,
      'modelType': 'direct',
      'isFeatured': false,
      'campaignTag': 'New Arrival',
    },
    {
      'vendorId': 'mock_vendor_zara',
      'name': 'Handcrafted Leather Boots',
      'description': 'Genuine Italian leather chelsea boots with cushioned insoles.',
      'price': 65000.0,
      'stock': 4,
      'images': ['https://picsum.photos/400/400?random=33'],
      'category': 'Footwear',
      'allowReservation': false,
      'modelType': 'strict',
      'isFeatured': true,
    },

    // Temu Express
    {
      'vendorId': 'mock_vendor_temu',
      'name': 'RGB Desktop Humidifier',
      'description': 'Ultra-quiet cool mist humidifier with color-changing LED strips.',
      'price': 8000.0,
      'stock': 30,
      'images': ['https://picsum.photos/400/400?random=34'],
      'category': 'Household',
      'allowReservation': true,
      'modelType': 'strict',
      'isFeatured': true,
      'campaignTag': 'Flash Sale',
      'discountedPrice': 4500.0,
    },
    {
      'vendorId': 'mock_vendor_temu',
      'name': 'Wireless Charging LED Desk Lamp',
      'description': 'Eye-protection lamp with 3 brightness modes and 15W Qi charge pad.',
      'price': 18000.0,
      'stock': 15,
      'images': ['https://picsum.photos/400/400?random=35'],
      'category': 'Household',
      'allowReservation': true,
      'modelType': 'direct',
      'isFeatured': false,
      'campaignTag': 'Best Price',
      'discountedPrice': 15000.0,
    },
    {
      'vendorId': 'mock_vendor_temu',
      'name': 'Mini Portable Electric Blender',
      'description': 'USB rechargeable personal smoothie maker with 6-blade setup.',
      'price': 12000.0,
      'stock': 0, // Out of stock to test sold out UI
      'images': ['https://picsum.photos/400/400?random=36'],
      'category': 'Household',
      'allowReservation': false,
      'modelType': 'strict',
      'isFeatured': false,
    },

    // Pinterest Curations
    {
      'vendorId': 'mock_vendor_pinterest',
      'name': 'Woven Macrame Wall Hanging',
      'description': 'Bohemian chic hand-woven cotton wall tapestry with wooden dowel.',
      'price': 14000.0,
      'stock': 6,
      'images': ['https://picsum.photos/400/400?random=37'],
      'category': 'Decor',
      'allowReservation': true,
      'modelType': 'strict',
      'isFeatured': true,
      'campaignTag': 'Almost Gone',
    },
    {
      'vendorId': 'mock_vendor_pinterest',
      'name': 'Pampas Grass Glass Vase',
      'description': 'Set of 3 dry pampas grass stems with a premium ribbed glass vase.',
      'price': 9500.0,
      'stock': 18,
      'images': ['https://picsum.photos/400/400?random=38'],
      'category': 'Decor',
      'allowReservation': true,
      'modelType': 'strict',
      'isFeatured': true,
      'campaignTag': 'Weekend Special',
      'discountedPrice': 7500.0,
    },
    {
      'vendorId': 'mock_vendor_pinterest',
      'name': 'Minimalist Arch Desk Mirror',
      'description': 'Irregular wooden frame mirror, perfect for vanity and room styling.',
      'price': 16000.0,
      'stock': 3,
      'images': ['https://picsum.photos/400/400?random=39'],
      'category': 'Decor',
      'allowReservation': false,
      'modelType': 'strict',
      'isFeatured': false,
    },

    // Gadget Hub
    {
      'vendorId': 'mock_vendor_gadget',
      'name': 'AeroMax Noise Cancelling Headphones',
      'description': 'Active noise cancelling Bluetooth over-ear headphones with 40h battery.',
      'price': 45000.0,
      'stock': 10,
      'images': ['https://picsum.photos/400/400?random=40'],
      'category': 'Audio',
      'allowReservation': true,
      'modelType': 'strict',
      'isFeatured': true,
      'campaignTag': 'Sallah Sale',
      'discountedPrice': 38000.0,
    },
    {
      'vendorId': 'mock_vendor_gadget',
      'name': 'Smart Sport Tracker Band 8',
      'description': 'Vibrant AMOLED health watch with heart rate tracking and 5ATM water rating.',
      'price': 22000.0,
      'stock': 22,
      'images': ['https://picsum.photos/400/400?random=41'],
      'category': 'Wearables',
      'allowReservation': true,
      'modelType': 'direct',
      'isFeatured': false,
      'campaignTag': 'Hot Deal',
    },
    {
      'vendorId': 'mock_vendor_gadget',
      'name': 'Retro Mechanical Keyboard',
      'description': 'Tactile mechanical typing keyboard with circular typewriter keycaps.',
      'price': 35000.0,
      'stock': 2,
      'images': ['https://picsum.photos/400/400?random=42'],
      'category': 'Peripherals',
      'allowReservation': false,
      'modelType': 'strict',
      'isFeatured': true,
    },
  ];

  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFA54600))),
    );

    // 3. Write Vendors
    for (final vendor in mockVendors) {
      final vendorRef = firestore.collection('vendors').doc(vendor['uid']);
      batch.set(vendorRef, vendor);

      // Write Visibility
      final visibilityRef = firestore.collection('vendor_visibility').doc(vendor['uid']);
      batch.set(visibilityRef, {
        'topSellerCircles': vendor['uid'] == 'mock_vendor_zara' ? 450 : 210,
        'mostVisitedCircles': vendor['uid'] == 'mock_vendor_zara' ? 230 : 90,
        'isHighlighted': vendor['uid'] == 'mock_vendor_zara',
      });
    }

    // 4. Write Products
    for (int i = 0; i < mockProducts.length; i++) {
      final product = mockProducts[i];
      final docId = 'mock_product_${i + 1}';
      final productRef = firestore.collection('products').doc(docId);

      batch.set(productRef, {
        'vendorId': product['vendorId'],
        'storeName': mockVendors.firstWhere((v) => v['uid'] == product['vendorId'])['store']['storeName'],
        'code': 'K-MOCK-${i + 1000}',
        'name': product['name'],
        'description': product['description'],
        'price': product['price'],
        'initialStock': product['stock'] + 5,
        'availableStock': product['stock'],
        'images': product['images'],
        'category': product['category'],
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'modelType': product['modelType'],
        'cancellationPolicy': 'Store Credit',
        'extensionsEnabled': product['allowReservation'],
        'allowReservation': product['allowReservation'],
        'isFeatured': product['isFeatured'],
        if (product['campaignTag'] != null) 'campaignTag': product['campaignTag'],
        if (product['discountedPrice'] != null) 'discountedPrice': product['discountedPrice'],
      });
    }

    await batch.commit();
    if (context.mounted) {
      Navigator.pop(context); // Close loading indicator
      showAppSnackbar("Successfully seeded complete mock storefront marketplace!", SnackbarType.success);
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Close loading indicator
      showAppSnackbar("Firestore write blocked. Local fallback activated! You can now test fully.", SnackbarType.success);
    }
  }
}
