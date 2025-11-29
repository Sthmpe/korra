import 'package:intl/intl.dart';
import 'customer_model.dart';

extension CustomerUI on Customer {
  
  // 1. Smart Name Display
  String get displayName {
    if (firstName.isEmpty && lastName.isEmpty) return "Valued Customer";
    return "$firstName $lastName".trim();
  }

  // 2. Avatar Initials
  String get initials {
    String first = firstName.isNotEmpty ? firstName[0] : '';
    String last = lastName.isNotEmpty ? lastName[0] : '';
    if (first.isEmpty && last.isEmpty) return 'KU'; // Korra User
    return (first + last).toUpperCase();
  }

  // 3. Formatted Balance (₦1,200.00)
  String get formattedBalance {
    return NumberFormat.currency(symbol: '₦', decimalDigits: 2).format(availableBalance);
  }

  // 4. Masked Bank Details (GTBank •••• 4829)
  String get bankDisplay {
    if (bankName == null || accountNumber == null) return "No bank linked";
    
    // Safety check for short account numbers
    String last4 = accountNumber!.length >= 4 
        ? accountNumber!.substring(accountNumber!.length - 4) 
        : accountNumber!;
        
    return "$bankName •••• $last4";
  }

  // 5. Verified Check
  bool get isFullyVerified => ninVerified && bvnVerified;
}