// lib/presentation/customer/storefront/widgets/mock_marketplace_data.dart

import '../../../../data/models/product_model.dart';

class MockMarketplaceData {
  static final List<Map<String, dynamic>> mockVendors = [
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
        'absorbOutrightFee': false,
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
        'absorbOutrightFee': true,
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
        'absorbOutrightFee': false,
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
        'absorbOutrightFee': true,
      },
      'socials': {
        'whatsappGroup': 'https://wa.me/2348077778888',
        'instagram': 'lagos_gadget_hub',
      },
    },
  ];

  static final List<Map<String, dynamic>> mockProducts = [
    {
      'id': 'mock_product_zara_1',
      'vendorId': 'mock_vendor_zara',
      'storeName': 'Zara Styles',
      'code': 'ZARA-SHIRT-01',
      'name': 'Oversized Linen Shirt',
      'description': '100% pure linen oversized summer shirt. Breathable and premium.',
      'price': 15000.0,
      'availableStock': 12,
      'images': [
        'https://picsum.photos/400/400?random=31',
        'https://picsum.photos/400/400?random=310',
        'https://picsum.photos/400/400?random=311'
      ],
      'category': 'Apparel',
      'allowReservation': true,
      'modelType': 'strict',
      'isFeatured': true,
      'campaignTag': 'Trending Now',
      'discountedPrice': 12000.0,
      'status': 'approved',
    },
    {
      'id': 'mock_product_zara_2',
      'vendorId': 'mock_vendor_zara',
      'storeName': 'Zara Styles',
      'code': 'ZARA-DENIM-02',
      'name': 'Classic Slim Denim',
      'description': 'High-stretch raw indigo slim jeans for everyday luxury.',
      'price': 25000.0,
      'availableStock': 8,
      'images': [
        'https://picsum.photos/400/400?random=32',
        'https://picsum.photos/400/400?random=320'
      ],
      'category': 'Apparel',
      'allowReservation': true,
      'modelType': 'direct',
      'isFeatured': false,
      'campaignTag': 'New Arrival',
      'status': 'approved',
    },
    {
      'id': 'mock_product_zara_3',
      'vendorId': 'mock_vendor_zara',
      'storeName': 'Zara Styles',
      'code': 'ZARA-BOOTS-03',
      'name': 'Handcrafted Leather Boots',
      'description': 'Genuine Italian leather chelsea boots with cushioned insoles.',
      'price': 65000.0,
      'availableStock': 4,
      'images': ['https://picsum.photos/400/400?random=33'],
      'category': 'Footwear',
      'allowReservation': false,
      'modelType': 'strict',
      'isFeatured': true,
      'status': 'approved',
    },
    {
      'id': 'mock_product_temu_1',
      'vendorId': 'mock_vendor_temu',
      'storeName': 'Temu Express',
      'code': 'TEMU-HUM-01',
      'name': 'RGB Desktop Humidifier',
      'description': 'Ultra-quiet cool mist humidifier with color-changing LED strips.',
      'price': 8000.0,
      'availableStock': 30,
      'images': ['https://picsum.photos/400/400?random=34'],
      'category': 'Household',
      'allowReservation': true,
      'modelType': 'strict',
      'isFeatured': true,
      'campaignTag': 'Flash Sale',
      'discountedPrice': 4500.0,
      'status': 'approved',
    },
    {
      'id': 'mock_product_temu_2',
      'vendorId': 'mock_vendor_temu',
      'storeName': 'Temu Express',
      'code': 'TEMU-LAMP-02',
      'name': 'Wireless Charging LED Desk Lamp',
      'description': 'Eye-protection lamp with 3 brightness modes and 15W Qi charge pad.',
      'price': 18000.0,
      'availableStock': 15,
      'images': ['https://picsum.photos/400/400?random=35'],
      'category': 'Household',
      'allowReservation': true,
      'modelType': 'direct',
      'isFeatured': false,
      'campaignTag': 'Best Price',
      'discountedPrice': 15000.0,
      'status': 'approved',
    },
    {
      'id': 'mock_product_temu_3',
      'vendorId': 'mock_vendor_temu',
      'storeName': 'Temu Express',
      'code': 'TEMU-BLEND-03',
      'name': 'Mini Portable Electric Blender',
      'description': 'USB rechargeable personal smoothie maker with 6-blade setup.',
      'price': 12000.0,
      'availableStock': 0,
      'images': ['https://picsum.photos/400/400?random=36'],
      'category': 'Household',
      'allowReservation': false,
      'modelType': 'strict',
      'isFeatured': false,
      'status': 'approved',
    },
    {
      'id': 'mock_product_pin_1',
      'vendorId': 'mock_vendor_pinterest',
      'storeName': 'Pinterest Curations',
      'code': 'PIN-MAC-01',
      'name': 'Woven Macrame Wall Hanging',
      'description': 'Bohemian chic hand-woven cotton wall tapestry with wooden dowel.',
      'price': 14000.0,
      'availableStock': 6,
      'images': ['https://picsum.photos/400/400?random=37'],
      'category': 'Decor',
      'allowReservation': true,
      'modelType': 'strict',
      'isFeatured': true,
      'campaignTag': 'Almost Gone',
      'status': 'approved',
    },
    {
      'id': 'mock_product_pin_2',
      'vendorId': 'mock_vendor_pinterest',
      'storeName': 'Pinterest Curations',
      'code': 'PIN-VASE-02',
      'name': 'Pampas Grass Glass Vase',
      'description': 'Set of 3 dry pampas grass stems with a premium ribbed glass vase.',
      'price': 9500.0,
      'availableStock': 10,
      'images': ['https://picsum.photos/400/400?random=38'],
      'category': 'Decor',
      'allowReservation': true,
      'modelType': 'strict',
      'isFeatured': false,
      'campaignTag': 'Hot Item',
      'status': 'approved',
    },
    {
      'id': 'mock_product_gadget_1',
      'vendorId': 'mock_vendor_gadget',
      'storeName': 'Lagos Gadget Hub',
      'code': 'GDGT-PODS-01',
      'name': 'Wireless Active Noise Pods',
      'description': 'Premium noise-cancelling wireless earbuds with 30-hour battery case.',
      'price': 45000.0,
      'availableStock': 20,
      'images': ['https://picsum.photos/400/400?random=39'],
      'category': 'Audio',
      'allowReservation': true,
      'modelType': 'strict',
      'isFeatured': true,
      'campaignTag': 'Discounted',
      'discountedPrice': 38000.0,
      'status': 'approved',
    },
  ];

  static List<Product> getProductsForVendor(String vendorId) {
    return mockProducts
        .where((p) => p['vendorId'] == vendorId)
        .map((p) => Product.fromMap(p, p['id']))
        .toList();
  }

  static Map<String, dynamic>? getVendorDetails(String vendorId) {
    try {
      return mockVendors.firstWhere((v) => v['uid'] == vendorId);
    } catch (_) {
      return null;
    }
  }
}
