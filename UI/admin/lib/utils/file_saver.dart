import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart' as implementation;

Future<bool> savePdfFile({
  required List<int> bytes,
  required String suggestedName,
}) {
  return implementation.savePdfFile(
    bytes: bytes,
    suggestedName: suggestedName,
  );
}