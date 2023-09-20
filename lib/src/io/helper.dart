import 'dart:async';

import 'package:advance_pdf_viewer2/src/document.dart';
import 'package:flutter/services.dart';

Future<PDFDocument> fromFileWeb(dynamic file) async {
  throw Exception('unimplemented for io');
}


Future<PDFDocument> fromAssetWeb(String asset) async {
  throw Exception('unimplemented for io');
}


Future<String> getPageWeb(int page,String filePathPublic) async {
  throw Exception('unimplemented for io');
}

Future<Uint8List> getUint8ListFromBlobUrl(String blobUrl) async {
  throw Exception('unimplemented for io');
}
