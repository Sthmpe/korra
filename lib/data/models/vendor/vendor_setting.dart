import 'payout/payout_details.dart';

class VendorSettings {
  final PayoutDetails payoutDetails;
  final bool isPinSet;

  VendorSettings({
    required this.payoutDetails,
    required this.isPinSet,
  });
}