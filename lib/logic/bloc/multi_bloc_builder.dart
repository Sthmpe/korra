import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MultiBlocBuilder2<B1 extends StateStreamable<S1>, S1,
    B2 extends StateStreamable<S2>, S2> extends StatelessWidget {
  final BlocWidgetBuilder2<S1, S2> builder;

  const MultiBlocBuilder2({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B1, S1>(
      builder: (context, state1) {
        return BlocBuilder<B2, S2>(
          builder: (context, state2) {
            return builder(context, state1, state2);
          },
        );
      },
    );
  }
}

typedef BlocWidgetBuilder2<S1, S2> = Widget Function(
  BuildContext context,
  S1 state1,
  S2 state2,
);
