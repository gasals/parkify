import 'dart:io';

import 'package:file_selector/file_selector.dart';

Future<bool> savePdfFile({
  required List<int> bytes,
  required String suggestedName,
}) async {
  final location = await getSaveLocation(
    suggestedName: suggestedName,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'PDF', extensions: ['pdf']),
    ],
  );

  if (location == null) {
    return false;
  }

  final file = File(location.path);
  await file.writeAsBytes(bytes, flush: true);
  return true;
}