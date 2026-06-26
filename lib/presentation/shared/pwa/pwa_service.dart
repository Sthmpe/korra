// This magically imports the Web file if running on Web, and the Unsupported file if on Mobile!
export 'pwa_unsupported.dart' if (dart.library.html) 'pwa_web.dart';