import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/home/vendor_home_bloc.dart';
import '../../../logic/bloc/vendor/home/vendor_home_event.dart';
import '../../../logic/core/net/net_cubit.dart';
import '../../shared/widgets/korra_header.dart';
import 'vendor_home_body.dart';

class VendorHomePage extends StatelessWidget {
  final VendorRepository vendors;
  final String vendorUid;

  const VendorHomePage({
    super.key,
    required this.vendors,
    required this.vendorUid,
  });

  @override
  Widget build(BuildContext context) {
    // vendors.fetchWallets();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => VendorHomeBloc(
            vendors: vendors,
            vendorUid: vendorUid,
            net: context.read<NetCubit>(),
          )..add(const VendorHomeStarted()),
        ),
        // Add more blocs here if needed
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const KorraHeader(title: 'Home'),
        body: VendorHomeBody(
          vendorUid: vendorUid,
          vendors: vendors,
        ),
      ),
    );
  }
}
