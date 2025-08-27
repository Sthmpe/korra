// # Korra · Vendor Reservations Module (Flutter)

// This module follows your standards:

// * **Own BLoC** (separate from `VendorHomeBloc`)
// * **Widgets split** cleanly (no giant files)
// * **Manual text styles** via `GoogleFonts.inter(...)`
// * **ScreenUtil** sizing everywhere (`.sp/.w/.h/.r`)
// * **Brand** color kept as `0xFFA54600` in local `_brand` constants
// * **Product image shown** with graceful loading + fallback

// Below are the files; copy them into the indicated paths.

// ---

// ## `lib/data/models/vendor_reservation.dart`

// ```dart
// import 'package:equatable/equatable.dart';

// enum ReservationStatus { newRes, ongoing, completed, cancelled }

// class VendorReservation extends Equatable {
//   final String id;
//   final String productTitle;
//   final String imageUrl;
//   final String sku;
//   final int quantity;
//   final String unitPriceText;   // e.g. '₦120,000'
//   final String totalText;       // e.g. '₦240,000'
//   final String customerName;    // e.g. 'Ola B.'
//   final String createdAtText;   // e.g. 'Aug 21, 10:24'
//   final String nextDueText;     // e.g. 'Due Fri • ₦12,500'
//   final String remainingText;   // e.g. '₦224,500 left'
//   final int progress;           // 0-100
//   final bool overdue;           // if latest installment missed
//   final bool autoPay;           // autopay enabled
//   final ReservationStatus status;

//   const VendorReservation({
//     required this.id,
//     required this.productTitle,
//     required this.imageUrl,
//     required this.sku,
//     required this.quantity,
//     required this.unitPriceText,
//     required this.totalText,
//     required this.customerName,
//     required this.createdAtText,
//     required this.nextDueText,
//     required this.remainingText,
//     required this.progress,
//     required this.overdue,
//     required this.autoPay,
//     required this.status,
//   });

//   @override
//   List<Object?> get props => [id, productTitle, imageUrl, sku, quantity, unitPriceText, totalText, customerName, createdAtText, nextDueText, remainingText, progress, overdue, autoPay, status];
// }
// ```

// ---

// ## `lib/data/repository/vendor_reservations_repository.dart`

// ```dart
// import 'dart:async';
// import '../models/vendor_reservation.dart';

// abstract class VendorReservationsRepository {
//   Future<List<VendorReservation>> fetch(ReservationStatus status);
// }

// class DemoVendorReservationsRepository implements VendorReservationsRepository {
//   @override
//   Future<List<VendorReservation>> fetch(ReservationStatus status) async {
//     await Future.delayed(const Duration(milliseconds: 350));

//     const demo = <VendorReservation>[
//       VendorReservation(
//         id: 'r1',
//         productTitle: 'iPhone 13 128GB',
//         imageUrl: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=1200',
//         sku: 'APL-IP13-128BLK',
//         quantity: 2,
//         unitPriceText: '₦120,000',
//         totalText: '₦240,000',
//         customerName: 'Ola B.',
//         createdAtText: 'Aug 21 • 10:24',
//         nextDueText: 'Due Fri • ₦12,500',
//         remainingText: '₦224,500 left',
//         progress: 45,
//         overdue: false,
//         autoPay: true,
//         status: ReservationStatus.ongoing,
//       ),
//       VendorReservation(
//         id: 'r2',
//         productTitle: 'LG OLED C2 55″',
//         imageUrl: 'https://images.unsplash.com/photo-1586822417800-9c7b7d79a4b5?w=1200',
//         sku: 'LG-C2-55',
//         quantity: 1,
//         unitPriceText: '₦800,000',
//         totalText: '₦800,000',
//         customerName: 'Hassan A.',
//         createdAtText: 'Aug 20 • 15:02',
//         nextDueText: 'Due Tue • ₦65,000',
//         remainingText: '₦650,000 left',
//         progress: 30,
//         overdue: true,
//         autoPay: false,
//         status: ReservationStatus.ongoing,
//       ),
//       VendorReservation(
//         id: 'r3',
//         productTitle: 'Air Max 270 Sneakers',
//         imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=1200',
//         sku: 'NK-AM270-BLK41',
//         quantity: 1,
//         unitPriceText: '₦46,000',
//         totalText: '₦46,000',
//         customerName: 'Chioma K.',
//         createdAtText: 'Aug 18 • 12:10',
//         nextDueText: 'Due Mon • ₦2,000',
//         remainingText: '₦18,000 left',
//         progress: 60,
//         overdue: false,
//         autoPay: false,
//         status: ReservationStatus.ongoing,
//       ),
//       VendorReservation(
//         id: 'r4',
//         productTitle: 'PlayStation 5',
//         imageUrl: 'https://images.unsplash.com/photo-1606813907291-76a5ebc5a1ab?w=1200',
//         sku: 'SONY-PS5-STD',
//         quantity: 1,
//         unitPriceText: '₦380,000',
//         totalText: '₦380,000',
//         customerName: 'Ade S.',
//         createdAtText: 'Aug 16 • 09:12',
//         nextDueText: 'Due Wed • ₦17,000',
//         remainingText: '₦170,000 left',
//         progress: 55,
//         overdue: false,
//         autoPay: true,
//         status: ReservationStatus.ongoing,
//       ),
//     ];

//     // In a real repo, you’d filter server-side. Demo filters here:
//     return demo.where((r) => r.status == status).toList();
//   }
// }
// ```

// ---

// ## `lib/logic/bloc/vendor/reservations/vendor_reservations_event.dart`

// ```dart
// import 'package:equatable/equatable.dart';
// import '../../../../data/models/vendor_reservation.dart';

// a bstract class VendorReservationsEvent extends Equatable {
//   const VendorReservationsEvent();
//   @override
//   List<Object?> get props => [];
// }

// class VendorReservationsStarted extends VendorReservationsEvent {
//   final ReservationStatus status;
//   const VendorReservationsStarted(this.status);
//   @override
//   List<Object?> get props => [status];
// }

// class VendorReservationsRefresh extends VendorReservationsEvent {
//   final ReservationStatus status;
//   const VendorReservationsRefresh(this.status);
//   @override
//   List<Object?> get props => [status];
// }

// class VendorReservationsFilterChanged extends VendorReservationsEvent {
//   final ReservationStatus status;
//   const VendorReservationsFilterChanged(this.status);
//   @override
//   List<Object?> get props => [status];
// }

// class VendorReservationApproveRequested extends VendorReservationsEvent {
//   final String id;
//   const VendorReservationApproveRequested(this.id);
//   @override
//   List<Object?> get props => [id];
// }

// class VendorReservationMarkDelivered extends VendorReservationsEvent {
//   final String id;
//   const VendorReservationMarkDelivered(this.id);
//   @override
//   List<Object?> get props => [id];
// }

// class VendorReservationMessageCustomer extends VendorReservationsEvent {
//   final String id;
//   const VendorReservationMessageCustomer(this.id);
//   @override
//   List<Object?> get props => [id];
// }
// ```

// ```
// ```

// ---

// ## `lib/logic/bloc/vendor/reservations/vendor_reservations_state.dart`

// ```dart
// import 'package:equatable/equatable.dart';
// import '../../../../data/models/vendor_reservation.dart';

// enum ReservationsUiStatus { idle, loading, loaded, empty, error }

// class VendorReservationsState extends Equatable {
//   final ReservationsUiStatus ui;
//   final ReservationStatus filter;
//   final List<VendorReservation> items;
//   final String? message; // for snackbars/toasts
//   final bool refreshing;

//   const VendorReservationsState({
//     this.ui = ReservationsUiStatus.idle,
//     this.filter = ReservationStatus.ongoing,
//     this.items = const [],
//     this.message,
//     this.refreshing = false,
//   });

//   VendorReservationsState copyWith({
//     ReservationsUiStatus? ui,
//     ReservationStatus? filter,
//     List<VendorReservation>? items,
//     String? message,
//     bool? refreshing,
//   }) => VendorReservationsState(
//         ui: ui ?? this.ui,
//         filter: filter ?? this.filter,
//         items: items ?? this.items,
//         message: message,
//         refreshing: refreshing ?? this.refreshing,
//       );

//   @override
//   List<Object?> get props => [ui, filter, items, message, refreshing];
// }
// ```

// ---

// ## `lib/logic/bloc/vendor/reservations/vendor_reservations_bloc.dart`

// ```dart
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../../data/models/vendor_reservation.dart';
// import '../../../../data/repository/vendor_reservations_repository.dart';
// import 'vendor_reservations_event.dart';
// import 'vendor_reservations_state.dart';

// class VendorReservationsBloc extends Bloc<VendorReservationsEvent, VendorReservationsState> {
//   final VendorReservationsRepository repo;
//   VendorReservationsBloc(this.repo) : super(const VendorReservationsState()) {
//     on<VendorReservationsStarted>(_onStart);
//     on<VendorReservationsRefresh>(_onRefresh);
//     on<VendorReservationsFilterChanged>(_onFilter);
//     on<VendorReservationApproveRequested>(_onApprove);
//     on<VendorReservationMarkDelivered>(_onDelivered);
//     on<VendorReservationMessageCustomer>(_onMessage);
//   }

//   Future<void> _onStart(VendorReservationsStarted e, Emitter<VendorReservationsState> emit) async {
//     emit(state.copyWith(ui: ReservationsUiStatus.loading, filter: e.status));
//     final list = await repo.fetch(e.status);
//     emit(state.copyWith(
//       ui: list.isEmpty ? ReservationsUiStatus.empty : ReservationsUiStatus.loaded,
//       items: list,
//     ));
//   }

//   Future<void> _onRefresh(VendorReservationsRefresh e, Emitter<VendorReservationsState> emit) async {
//     emit(state.copyWith(refreshing: true, filter: e.status));
//     final list = await repo.fetch(e.status);
//     emit(state.copyWith(
//       refreshing: false,
//       ui: list.isEmpty ? ReservationsUiStatus.empty : ReservationsUiStatus.loaded,
//       items: list,
//     ));
//   }

//   Future<void> _onFilter(VendorReservationsFilterChanged e, Emitter<VendorReservationsState> emit) async {
//     HapticFeedback.selectionClick();
//     emit(state.copyWith(ui: ReservationsUiStatus.loading, filter: e.status));
//     final list = await repo.fetch(e.status);
//     emit(state.copyWith(ui: list.isEmpty ? ReservationsUiStatus.empty : ReservationsUiStatus.loaded, items: list));
//   }

//   Future<void> _onApprove(VendorReservationApproveRequested e, Emitter<VendorReservationsState> emit) async {
//     HapticFeedback.mediumImpact();
//     emit(state.copyWith(message: 'Reservation ${e.id} approved'));
//   }

//   Future<void> _onDelivered(VendorReservationMarkDelivered e, Emitter<VendorReservationsState> emit) async {
//     HapticFeedback.mediumImpact();
//     emit(state.copyWith(message: 'Marked delivered'));
//   }

//   Future<void> _onMessage(VendorReservationMessageCustomer e, Emitter<VendorReservationsState> emit) async {
//     HapticFeedback.selectionClick();
//     emit(state.copyWith(message: 'Open chat with customer'));
//   }
// }
// ```

// ---

// ## `lib/presentation/vendor/reservations/vendor_reservations_page.dart`

// ```dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';

// import '../../../data/repository/vendor_reservations_repository.dart';
// import '../../../data/models/vendor_reservation.dart';
// import '../../../logic/bloc/vendor/reservations/vendor_reservations_bloc.dart';
// import '../../../logic/bloc/vendor/reservations/vendor_reservations_event.dart';
// import '../../../logic/bloc/vendor/reservations/vendor_reservations_state.dart';
// import '../../shared/widgets/korra_header.dart';
// import 'widgets/reservation_status_tabs.dart';
// import 'widgets/reservation_list.dart';

// class VendorReservationsPage extends StatelessWidget {
//   const VendorReservationsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => VendorReservationsBloc(DemoVendorReservationsRepository())
//         ..add(const VendorReservationsStarted(ReservationStatus.ongoing)),
//       child: BlocConsumer<VendorReservationsBloc, VendorReservationsState>(
//         listenWhen: (p, c) => p.message != c.message && c.message != null,
//         listener: (context, s) {
//           if (s.message != null) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(s.message!, style: GoogleFonts.inter(fontSize: 13.5.sp))),
//             );
//           }
//         },
//         builder: (context, s) {
//           final bloc = context.read<VendorReservationsBloc>();
//           return Scaffold(
//             backgroundColor: Colors.white,
//             appBar: const KorraHeader(title: 'Reservations'),
//             body: RefreshIndicator(
//               onRefresh: () async => bloc.add(VendorReservationsRefresh(s.filter)),
//               child: CustomScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 slivers: [
//                   SliverToBoxAdapter(
//                     child: ReservationStatusTabs(
//                       current: s.filter,
//                       onChanged: (st) => bloc.add(VendorReservationsFilterChanged(st)),
//                     ),
//                   ),
//                   ReservationList(
//                     ui: s.ui,
//                     items: s.items,
//                     onApprove: (id) => bloc.add(VendorReservationApproveRequested(id)),
//                     onDelivered: (id) => bloc.add(VendorReservationMarkDelivered(id)),
//                     onMessage: (id) => bloc.add(VendorReservationMessageCustomer(id)),
//                   ),
//                   SliverToBoxAdapter(child: SizedBox(height: 8.h)),
//                 ],
//               ),
//           );},
//       ),
//     );
//   }
// }
// ```

// ---

// ## `lib/presentation/vendor/reservations/widgets/reservation_status_tabs.dart`

// ```dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../../../data/models/vendor_reservation.dart';

// class ReservationStatusTabs extends StatelessWidget {
//   final ReservationStatus current;
//   final ValueChanged<ReservationStatus> onChanged;
//   const ReservationStatusTabs({super.key, required this.current, required this.onChanged});

//   static const _brand = Color(0xFFA54600);

//   @override
//   Widget build(BuildContext context) {
//     final items = const [
//       _TabSpec('New', ReservationStatus.newRes),
//       _TabSpec('Ongoing', ReservationStatus.ongoing),
//       _TabSpec('Completed', ReservationStatus.completed),
//       _TabSpec('Cancelled', ReservationStatus.cancelled),
//     ];

//     return Padding(
//       padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 6.h),
//       child: Row(
//         children: items.map((t) {
//           final selected = current == t.status;
//           return Expanded(
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 4.w),
//               child: Material(
//                 color: Colors.transparent,
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(12.r),
//                   onTap: () {
//                     HapticFeedback.selectionClick();
//                     onChanged(t.status);
//                   },
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 140),
//                     padding: EdgeInsets.symmetric(vertical: 10.h),
//                     decoration: BoxDecoration(
//                       color: selected ? _brand.withOpacity(.08) : Colors.white,
//                       borderRadius: BorderRadius.circular(12.r),
//                       border: Border.all(color: selected ? _brand : const Color(0xFFEAE6E2), width: selected ? 1.4 : 1),
//                     ),
//                     child: Center(
//                       child: Text(
//                         t.label,
//                         style: GoogleFonts.inter(
//                           fontSize: 13.5.sp,
//                           fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
//                           color: selected ? _brand : const Color(0xFF4D4D4D),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

// class _TabSpec {
//   final String label; final ReservationStatus status;
//   const _TabSpec(this.label, this.status);
// }
// ```

// ---

// ## `lib/presentation/vendor/reservations/widgets/reservation_list.dart`

// ```dart
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../../../data/models/vendor_reservation.dart';
// import 'reservation_tile.dart';

// import '../../../../logic/bloc/vendor/reservations/vendor_reservations_state.dart';

// class ReservationList extends StatelessWidget {
//   final ReservationsUiStatus ui;
//   final List<VendorReservation> items;
//   final void Function(String id) onApprove;
//   final void Function(String id) onDelivered;
//   final void Function(String id) onMessage;

//   const ReservationList({
//     super.key,
//     required this.ui,
//     required this.items,
//     required this.onApprove,
//     required this.onDelivered,
//     required this.onMessage,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (ui == ReservationsUiStatus.loading) {
//       return SliverToBoxAdapter(
//         child: Padding(
//           padding: EdgeInsets.all(20.r),
//           child: Center(child: SizedBox(width: 22.w, height: 22.w, child: const CircularProgressIndicator(strokeWidth: 2))),
//         ),
//       );
//     }

//     if (ui == ReservationsUiStatus.empty) {
//       return SliverToBoxAdapter(
//         child: Padding(
//           padding: EdgeInsets.all(16.r),
//           child: Container(
//             padding: EdgeInsets.all(16.r),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16.r),
//               border: Border.all(color: const Color(0xFFEAE6E2)),
//             ),
//             child: Text('No reservations here yet.', style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF5E5E5E))),
//           ),
//         ),
//       );
//     }

//     return SliverList.separated(
//       itemCount: items.length,
//       separatorBuilder: (_, __) => SizedBox(height: 8.h),
//       itemBuilder: (_, i) {
//         final r = items[i];
//         return Padding(
//           padding: EdgeInsets.symmetric(horizontal: 12.w),
//           child: ReservationTile(
//             data: r,
//             onApprove: () => onApprove(r.id),
//             onDelivered: () => onDelivered(r.id),
//             onMessage: () => onMessage(r.id),
//           ),
//         );
//       },
//     );
//   }
// }
// ```

// ---

// ## `lib/presentation/vendor/reservations/widgets/reservation_tile.dart`

// ```dart
// import 'dart:ui' show FontFeature;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:iconsax/iconsax.dart';
// import '../../../../data/models/vendor_reservation.dart';

// class ReservationTile extends StatelessWidget {
//   final VendorReservation data;
//   final VoidCallback onApprove;
//   final VoidCallback onDelivered;
//   final VoidCallback onMessage;
//   const ReservationTile({super.key, required this.data, required this.onApprove, required this.onDelivered, required this.onMessage});

//   static const _brand = Color(0xFFA54600);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(12.r),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16.r),
//         border: Border.all(color: const Color(0xFFEAE6E2)),
//       ),
//       child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         _ProductImage(url: data.imageUrl),
//         SizedBox(width: 10.w),
//         Expanded(child: _Info(data: data, onApprove: onApprove, onDelivered: onDelivered, onMessage: onMessage)),
//       ]),
//     );
//   }
// }

// class _ProductImage extends StatelessWidget {
//   final String url;
//   const _ProductImage({required this.url});

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(12.r),
//       child: SizedBox(
//         width: 72.w,
//         height: 72.w,
//         child: Image.network(
//           url,
//           fit: BoxFit.cover,
//           loadingBuilder: (ctx, child, progress) {
//             if (progress == null) return child;
//             return Container(
//               color: const Color(0xFFF3EFEA),
//               child: Center(
//                 child: SizedBox(
//                   width: 16.w,
//                   height: 16.w,
//                   child: const CircularProgressIndicator(strokeWidth: 1.8),
//                 ),
//               ),
//             );
//           },
//           errorBuilder: (ctx, _, __) => Container(
//             color: const Color(0xFFF3EFEA),
//             child: const Icon(Icons.broken_image_outlined, color: Color(0xFF8B8B8B)),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _Info extends StatelessWidget {
//   final VendorReservation data;
//   final VoidCallback onApprove;
//   final VoidCallback onDelivered;
//   final VoidCallback onMessage;
//   const _Info({required this.data, required this.onApprove, required this.onDelivered, required this.onMessage});

//   static const _brand = Color(0xFFA54600);

//   @override
//   Widget build(BuildContext context) {
//     final statusColor = data.overdue ? const Color(0xFFD92D20) : const Color(0xFF1B1B1B);

//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       // Title + copy id
//       Row(children: [
//         Expanded(
//           child: Text(
//             data.productTitle,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B1B)),
//           ),
//         ),
//         GestureDetector(
//           onTap: () {
//             HapticFeedback.selectionClick();
//             Clipboard.setData(ClipboardData(text: data.id));
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Copied ID ${data.id}', style: GoogleFonts.inter(fontSize: 13.sp))),
//             );
//           },
//           child: Icon(Icons.copy, size: 16.sp, color: const Color(0xFF8B8B8B)),
//         ),
//       ]),
//       SizedBox(height: 4.h),

//       // Meta line: customer • created • SKU
//       Text(
//         '${data.customerName} • ${data.createdAtText} • ${data.sku}',
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//         style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w500, color: const Color(0xFF5E5E5E)),
//       ),
//       SizedBox(height: 6.h),

//       // Price row: qty × unit • total
//       Row(children: [
//         Expanded(
//           child: Text(
//             '${data.quantity} × ${data.unitPriceText}',
//             style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]),
//           ),
//         ),
//         Text(
//           data.totalText,
//           style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()]),
//         ),
//       ]),
//       SizedBox(height: 8.h),

//       // Progress + next due/badges
//       Row(children: [
//         Expanded(child: _ProgressBar(value: data.progress / 100)),
//         SizedBox(width: 8.w),
//         if (data.overdue) _Badge(text: 'Overdue', c: const Color(0xFFD92D20))
//         else _Badge(text: data.autoPay ? 'AutoPay' : 'On schedule', c: _brand),
//       ]),
//       SizedBox(height: 6.h),
//       Text(
//         '${data.nextDueText} • ${data.remainingText}',
//         style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: statusColor),
//       ),

//       SizedBox(height: 10.h),

//       // Actions (vary by status) — keep compact heights
//       Wrap(spacing: 8.w, runSpacing: 8.h, children: _actionsByStatus()),
//     ]);
//   }

//   List<Widget> _actionsByStatus() {
//     switch (data.status) {
//       case ReservationStatus.newRes:
//         return [
//           _Primary('Approve', onApprove),
//           _Secondary('Message', onMessage),
//         ];
//       case ReservationStatus.ongoing:
//         return [
//           _Primary('View plan', onApprove),
//           _Secondary('Message', onMessage),
//         ];
//       case ReservationStatus.completed:
//         return [
//           _Secondary('Message', onMessage),
//           _Secondary('Mark delivered', onDelivered),
//         ];
//       case ReservationStatus.cancelled:
//         return [
//           _Secondary('Message', onMessage),
//         ];
//     }
//   }
// }

// class _ProgressBar extends StatelessWidget {
//   final double value; // 0..1
//   const _ProgressBar({required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(999.r),
//       child: LinearProgressIndicator(
//         minHeight: 6.h,
//         value: value.clamp(0, 1),
//         backgroundColor: const Color(0xFFF0ECE8),
//         valueColor: const AlwaysStoppedAnimation(Color(0xFFA54600)),
//       ),
//     );
//   }
// }

// class _Badge extends StatelessWidget {
//   final String text; final Color c;
//   const _Badge({required this.text, required this.c});
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(999.r),
//         border: Border.all(color: c),
//       ),
//       child: Text(text, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: c)),
//     );
//   }
// }

// class _Primary extends StatelessWidget {
//   final String text; final VoidCallback onTap;
//   const _Primary(this.text, this.onTap);
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 36.h,
//       child: FilledButton(
//         onPressed: onTap,
//         style: FilledButton.styleFrom(
//           backgroundColor: const Color(0xFFA54600),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
//           padding: EdgeInsets.symmetric(horizontal: 14.w),
//         ),
//         child: Text(text, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white)),
//       ),
//     );
//   }
// }

// class _Secondary extends StatelessWidget {
//   final String text; final VoidCallback onTap;
//   const _Secondary(this.text, this.onTap);
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 36.h,
//       child: OutlinedButton(
//         onPressed: onTap,
//         style: OutlinedButton.styleFrom(
//           side: const BorderSide(color: Color(0xFFEAE6E2)),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
//           padding: EdgeInsets.symmetric(horizontal: 12.w),
//           foregroundColor: const Color(0xFFA54600),
//         ),
//         child: Text(text, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700)),
//       ),
//     );
//   }
// }
// ```

// ---

// ### Hooking it up

// * Navigate to `VendorReservationsPage()` from your Vendor home (e.g., from a "View all" button in Reservations section).
// * When you swap in your real models/repo, map fields into `VendorReservation` (or replace the model keeping the widget props identical).
// * All text uses explicit `GoogleFonts.inter(...)` styles, ScreenUtil sizing, and your brand color.

// That’s it—fully split widgets, dedicated BLoC, product images in place, and big‑tech polish baked in. 🎯
