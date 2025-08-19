import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_event.dart';
import '../../shared/widgets/korra_header.dart';
import 'vendor_products_body.dart';

class VendorProductsPage extends StatelessWidget {
  const VendorProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorProductsBloc()..add(const VendorProductsStarted()),
      child: const Scaffold(
        backgroundColor: Colors.white,
        appBar: KorraHeader(title: 'Products'),
        body: VendorProductsBody(),
      ),
    );
  }
}
