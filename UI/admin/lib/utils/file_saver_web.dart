import 'dart:convert';
import 'dart:html' as html;

Future<bool> savePdfFile({
  required List<int> bytes,
  required String suggestedName,
}) async {
  final base64Data = base64Encode(bytes);
  final dataUrl = 'data:application/pdf;base64,$base64Data';

  final anchor = html.AnchorElement(href: dataUrl)
    ..download = suggestedName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  return true;
}