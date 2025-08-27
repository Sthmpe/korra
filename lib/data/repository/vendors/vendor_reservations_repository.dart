import 'dart:async';
import '../../models/vendor/vendor_reservation.dart';

abstract class VendorReservationsRepository {
  Future<List<VendorReservation>> fetchAll();
}

class DemoVendorReservationsRepository implements VendorReservationsRepository {
  @override
  Future<List<VendorReservation>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 280));
    final now = DateTime.now();

    return <VendorReservation>[
      // 1
      VendorReservation(
        id: 'R-1001',
        productTitle: 'Bose 700',
        productImageUrl: 'https://images.unsplash.com/photo-1518441978-1a86c5f26d8e?w=1200',
        sku: 'BOSE-700-BLK',
        quantity: 1,
        unitPrice: 240000,
        total: 240000,
        paid: 45000,
        createdAt: now.subtract(const Duration(days: 2, hours: 5)),
        nextDueAt: now.add(const Duration(days: 3)),
        approved: false, // new
        cancelled: false,
        autoPay: true,
        customerName: 'John D.',
      ),
      // 2
      VendorReservation(
        id: 'R-1002',
        productTitle: 'iPhone 13 128GB',
        productImageUrl: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=1200',
        sku: 'APL-IP13-128-BLK',
        quantity: 1,
        unitPrice: 380000,
        total: 380000,
        paid: 210000,
        createdAt: now.subtract(const Duration(days: 5, hours: 2)),
        nextDueAt: now.subtract(const Duration(days: 1)), // overdue
        approved: true,
        cancelled: false,
        autoPay: false,
        customerName: 'Ada O.',
      ),
      // 3
      VendorReservation(
        id: 'R-1003',
        productTitle: 'AirPods Pro 2',
        productImageUrl: 'https://images.unsplash.com/photo-1585386959984-a41552231603?w=1200',
        sku: 'APL-APP2',
        quantity: 1,
        unitPrice: 145000,
        total: 145000,
        paid: 145000, // completed
        createdAt: now.subtract(const Duration(days: 10)),
        nextDueAt: null,
        approved: true,
        cancelled: false,
        autoPay: false,
        customerName: 'Mike S.',
      ),
      // 4
      VendorReservation(
        id: 'R-1004',
        productTitle: 'LG OLED C2 55″',
        productImageUrl: 'https://images.unsplash.com/photo-1586822417800-9c7b7d79a4b5?w=1200',
        sku: 'LG-C2-55',
        quantity: 1,
        unitPrice: 800000,
        total: 800000,
        paid: 0,
        createdAt: now.subtract(const Duration(days: 8)),
        nextDueAt: null,
        approved: true,
        cancelled: true, // cancelled
        autoPay: false,
        customerName: 'Lola K.',
      ),
      // 5
      VendorReservation(
        id: 'R-1005',
        productTitle: 'PlayStation 5',
        productImageUrl: 'https://images.unsplash.com/photo-1606813907291-76a5ebc5a1ab?w=1200',
        sku: 'SONY-PS5-STD',
        quantity: 1,
        unitPrice: 380000,
        total: 380000,
        paid: 210000,
        createdAt: now.subtract(const Duration(days: 6)),
        nextDueAt: now.add(const Duration(days: 4)),
        approved: true,
        cancelled: false,
        autoPay: true,
        customerName: 'Ade S.',
      ),
      // 6
      VendorReservation(
        id: 'R-1006',
        productTitle: 'MacBook Air M2',
        productImageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=1200',
        sku: 'APL-MBA-M2-13',
        quantity: 1,
        unitPrice: 950000,
        total: 950000,
        paid: 320000,
        createdAt: now.subtract(const Duration(days: 9, hours: 3)),
        nextDueAt: now.subtract(const Duration(days: 2)), // overdue
        approved: true,
        cancelled: false,
        autoPay: true,
        customerName: 'Sara P.',
      ),
      // 7
      VendorReservation(
        id: 'R-1007',
        productTitle: 'Air Max 270 Sneakers',
        productImageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=1200',
        sku: 'NK-AM270-BLK41',
        quantity: 1,
        unitPrice: 46000,
        total: 46000,
        paid: 28000,
        createdAt: now.subtract(const Duration(days: 3)),
        nextDueAt: now.add(const Duration(days: 1)),
        approved: true,
        cancelled: false,
        autoPay: false,
        customerName: 'Chioma K.',
      ),
      // 8
      VendorReservation(
        id: 'R-1008',
        productTitle: 'Men’s Denim Jacket',
        productImageUrl: 'https://images.unsplash.com/photo-1548883354-7622d3f7ad24?w=1200',
        sku: 'ST-DENIM-M-42',
        quantity: 1,
        unitPrice: 32500,
        total: 32500,
        paid: 6500,
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        nextDueAt: now.add(const Duration(days: 5)),
        approved: false, // new
        cancelled: false,
        autoPay: false,
        customerName: 'Ife N.',
      ),
      // 9
      VendorReservation(
        id: 'R-1009',
        productTitle: 'Leather Tote Bag',
        productImageUrl: 'https://images.unsplash.com/photo-1547949003-9792a18a2601?w=1200',
        sku: 'BM-TOTE-LEA-BRN',
        quantity: 1,
        unitPrice: 60000,
        total: 60000,
        paid: 60000, // completed
        createdAt: now.subtract(const Duration(days: 12)),
        nextDueAt: null,
        approved: true,
        cancelled: false,
        autoPay: false,
        customerName: 'Sade O.',
      ),
      // 10
      VendorReservation(
        id: 'R-1010',
        productTitle: 'Floral Summer Dress',
        productImageUrl: 'https://images.unsplash.com/photo-1503342217505-b0a15cf70489?w=1200',
        sku: 'BM-SUM-DRS-S',
        quantity: 1,
        unitPrice: 40000,
        total: 40000,
        paid: 4000,
        createdAt: now.subtract(const Duration(days: 7)),
        nextDueAt: null,
        approved: true,
        cancelled: true, // cancelled
        autoPay: false,
        customerName: 'Amina T.',
      ),
      // 11
      VendorReservation(
        id: 'R-1011',
        productTitle: 'Apple Watch Series 8',
        productImageUrl: 'https://images.unsplash.com/photo-1516574187841-cb9cc2ca948b?w=1200',
        sku: 'APL-WATCH-S8',
        quantity: 1,
        unitPrice: 185000,
        total: 185000,
        paid: 185000, // completed
        createdAt: now.subtract(const Duration(days: 15)),
        nextDueAt: null,
        approved: true,
        cancelled: false,
        autoPay: true,
        customerName: 'Ruth A.',
      ),
      // 12
      VendorReservation(
        id: 'R-1012',
        productTitle: 'Canon EOS R Camera',
        productImageUrl: 'https://images.unsplash.com/photo-1519183071298-a2962be96f86?w=1200',
        sku: 'CAN-EOSR-BODY',
        quantity: 1,
        unitPrice: 650000,
        total: 650000,
        paid: 220000,
        createdAt: now.subtract(const Duration(days: 11, hours: 6)),
        nextDueAt: now.add(const Duration(days: 6)),
        approved: true,
        cancelled: false,
        autoPay: true,
        customerName: 'Bolu F.',
      ),
      // 13
      VendorReservation(
        id: 'R-1013',
        productTitle: 'Sony WH-1000XM4',
        productImageUrl: 'https://images.unsplash.com/photo-1515202913167-d9a698095ebf?w=1200',
        sku: 'SONY-XM4-BLK',
        quantity: 1,
        unitPrice: 210000,
        total: 210000,
        paid: 0,
        createdAt: now.subtract(const Duration(hours: 20)),
        nextDueAt: now.add(const Duration(days: 3)),
        approved: false, // new
        cancelled: false,
        autoPay: true,
        customerName: 'Uche M.',
      ),
      // 14
      VendorReservation(
        id: 'R-1014',
        productTitle: 'Samsung Galaxy S22',
        productImageUrl: 'https://images.unsplash.com/photo-1512499617640-c2f999098b2b?w=1200',
        sku: 'SMS-S22-128BLK',
        quantity: 1,
        unitPrice: 420000,
        total: 420000,
        paid: 140000,
        createdAt: now.subtract(const Duration(days: 4, hours: 8)),
        nextDueAt: now.add(const Duration(days: 2)),
        approved: true,
        cancelled: false,
        autoPay: false,
        customerName: 'Henry I.',
      ),
      // 15
      VendorReservation(
        id: 'R-1015',
        productTitle: 'Whirlpool Refrigerator 360L',
        productImageUrl: 'https://images.unsplash.com/photo-1556911220-e15b29be8cbd?w=1200',
        sku: 'WHIRL-360L',
        quantity: 1,
        unitPrice: 560000,
        total: 560000,
        paid: 560000, // completed
        createdAt: now.subtract(const Duration(days: 20)),
        nextDueAt: null,
        approved: true,
        cancelled: false,
        autoPay: false,
        customerName: 'Ngozi E.',
      ),
      // 16
      VendorReservation(
        id: 'R-1016',
        productTitle: '3-Seater Fabric Sofa',
        productImageUrl: 'https://images.unsplash.com/photo-1493666438817-866a91353ca9?w=1200',
        sku: 'SOFA-FAB-3S-GRY',
        quantity: 1,
        unitPrice: 480000,
        total: 480000,
        paid: 120000,
        createdAt: now.subtract(const Duration(days: 13)),
        nextDueAt: null,
        approved: true,
        cancelled: true, // cancelled
        autoPay: false,
        customerName: 'Yusuf G.',
      ),
      // 17
      VendorReservation(
        id: 'R-1017',
        productTitle: 'JBL Flip 6 Speaker',
        productImageUrl: 'https://images.unsplash.com/photo-1519677100203-a0e668c92439?w=1200',
        sku: 'JBL-FLP6-BLK',
        quantity: 1,
        unitPrice: 120000,
        total: 120000,
        paid: 60000,
        createdAt: now.subtract(const Duration(days: 2)),
        nextDueAt: now.add(const Duration(days: 7)),
        approved: true,
        cancelled: false,
        autoPay: true,
        customerName: 'Kemi A.',
      ),
      // 18
      VendorReservation(
        id: 'R-1018',
        productTitle: 'Xbox Series X',
        productImageUrl: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=1200',
        sku: 'MS-XBOXX-1TB',
        quantity: 1,
        unitPrice: 360000,
        total: 360000,
        paid: 110000,
        createdAt: now.subtract(const Duration(days: 6, hours: 5)),
        nextDueAt: now.subtract(const Duration(days: 1)), // overdue
        approved: true,
        cancelled: false,
        autoPay: false,
        customerName: 'Femi B.',
      ),
      // 19
      VendorReservation(
        id: 'R-1019',
        productTitle: 'Nikon 85mm f/1.8 Lens',
        productImageUrl: 'https://images.unsplash.com/photo-1504215680853-026ed2a45def?w=1200',
        sku: 'NKN-85-18G',
        quantity: 1,
        unitPrice: 420000,
        total: 420000,
        paid: 420000, // completed
        createdAt: now.subtract(const Duration(days: 18)),
        nextDueAt: null,
        approved: true,
        cancelled: false,
        autoPay: false,
        customerName: 'Tunde C.',
      ),
      // 20
      VendorReservation(
        id: 'R-1020',
        productTitle: 'Kitchen Stand Mixer',
        productImageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1200',
        sku: 'KITCH-MIX-900W',
        quantity: 1,
        unitPrice: 85000,
        total: 85000,
        paid: 15000,
        createdAt: now.subtract(const Duration(hours: 15)),
        nextDueAt: now.add(const Duration(days: 4)),
        approved: false, // new
        cancelled: false,
        autoPay: true,
        customerName: 'Zainab J.',
      ),
    ];
  }
}
