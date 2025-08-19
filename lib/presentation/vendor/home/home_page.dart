import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/bloc/vendor/home/vendor_home_bloc.dart';
import '../../../logic/bloc/vendor/home/vendor_home_event.dart';
import '../../shared/widgets/korra_header.dart';
import 'vendor_home_body.dart';

class VendorHomePage extends StatelessWidget {
  const VendorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorHomeBloc()..add(const VendorHomeStarted()),
      child: const Scaffold(
        backgroundColor: Colors.white,
        appBar: KorraHeader(title: 'Home'),
        body: VendorHomeBody(),
      ),
    );
  }
}
