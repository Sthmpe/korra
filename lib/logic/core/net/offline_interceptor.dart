import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'net_cubit.dart';

class OfflineInterceptor extends Interceptor {
  OfflineInterceptor(this.ctx);
  final BuildContext ctx;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final online = ctx.read<NetCubit>().state == NetState.online;
    if (!online) {
      return handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
        error: 'OFFLINE',
      ));
    }
    super.onRequest(options, handler);
  }
}


// Attach when building Dio:

// final dio = Dio()..interceptors.add(OfflineInterceptor(Get.context!));
