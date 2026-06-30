// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';

@JS('MonnifySDK')
extension type MonnifySDK._(JSObject _) implements JSObject {
  external static void initialize(JSAny config);
}

void initializeMonnifyWeb({
  required double amount,
  required String apiKey,
  required String contractCode,
  required String paymentReference,
  required String email,
  required String name,
  required String uid,
  required void Function() onComplete,
  required void Function() onClose,
}) {
  // Convert Dart callbacks to JS functions using .toJS
  final onCompleteJS = (() {
    onComplete();
  }).toJS;

  final onCloseJS = (() {
    onClose();
  }).toJS;

  final Map<String, dynamic> configMap = {
    'amount': amount,
    'currency': 'NGN',
    'reference': paymentReference,
    'customerFullName': name,
    'customerEmail': email,
    'apiKey': apiKey,
    'contractCode': contractCode,
    'paymentDescription': 'Korra Wallet Deposit',
    'metadata': {
      'customerUid': uid,
    },
    'onComplete': onCompleteJS,
    'onClose': onCloseJS,
  };

  // Convert the Dart Map recursively to a JS Object using .jsify()
  final configJS = configMap.jsify();
  if (configJS != null) {
    MonnifySDK.initialize(configJS);
  }
}
