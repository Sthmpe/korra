import 'package:equatable/equatable.dart';
import 'signup_vendor_event.dart';

class SignupVendorState extends Equatable {
  final int pageIndex;            // 0..4
  final int totalPages;           // 5
  final bool loading;

  // V1
  final bool registered;
  final String cac;
  final String legalName;

  // V2
  final String storeName;
  final Presence presence;
  final List<String> categories;

  // V3
  final String address;
  final String city;
  final String stateName;
  final String mapsLink;

  // V4
  final String ownerFirst;
  final String ownerLast;
  final String ownerOther;
  final String ownerPhone;

 
  // New-V4
  final String email;
  final DateTime? dob;
  final Gender gender;

  // New-V5
  final String nin;
  final String bvn;

  // final String email;
  final String password;
  final String confirm;
  final bool hidePass;
  final bool hideConf;

  const SignupVendorState({
    this.pageIndex = 0,
    this.totalPages = 7,
    this.loading = false,
    this.registered = false,
    this.cac = '',
    this.legalName = '',
    this.storeName = '',
    this.presence = Presence.online,
    this.categories = const [],
    this.address = '',
    this.city = '',
    this.stateName = '',
    this.mapsLink = '',
    this.ownerFirst = '',
    this.ownerLast = '',
    this.ownerOther = '',
    this.ownerPhone = '',
    this.dob,
    this.gender = Gender.undisclosed,
    this.nin = '',
    this.bvn = '',
    this.email = '',
    this.password = '',
    this.confirm = '',
    this.hidePass = true,
    this.hideConf = true,
  });

  SignupVendorState copyWith({
    int? pageIndex, bool? loading,
    bool? registered, String? cac, String? legalName,
    String? storeName, Presence? presence, List<String>? categories,
    String? address, String? city, String? stateName, String? mapsLink,
    String? ownerFirst, String? ownerLast, String? ownerPhone,
    String? ownerOther,
    String? email, DateTime? dob, Gender? gender,
    String? nin, String? bvn,
    String? password, String? confirm,
    bool? hidePass, bool? hideConf,
  }) {
    return SignupVendorState(
      pageIndex: pageIndex ?? this.pageIndex,
      totalPages: totalPages,
      loading: loading ?? this.loading,
      registered: registered ?? this.registered,
      cac: cac ?? this.cac,
      legalName: legalName ?? this.legalName,
      storeName: storeName ?? this.storeName,
      presence: presence ?? this.presence,
      categories: categories ?? this.categories,
      address: address ?? this.address,
      city: city ?? this.city,
      stateName: stateName ?? this.stateName,
      mapsLink: mapsLink ?? this.mapsLink,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      nin: nin ?? this.nin,
      bvn: bvn ?? this.bvn,
      ownerFirst: ownerFirst ?? this.ownerFirst,
      ownerLast: ownerLast ?? this.ownerLast,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerOther: ownerOther ?? this.ownerOther,
      password: password ?? this.password,
      confirm: confirm ?? this.confirm,
      hidePass: hidePass ?? this.hidePass,
      hideConf: hideConf ?? this.hideConf,
    );
  }

  @override
  List<Object?> get props => [
    pageIndex,totalPages,loading,registered,cac,legalName,storeName,presence,categories,
    address,city,stateName,mapsLink,ownerFirst,ownerLast,ownerPhone,email,password,confirm,hidePass,hideConf
  ];
}
