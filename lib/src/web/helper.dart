import 'dart:async';
import 'dart:convert';

import 'package:advance_pdf_viewer2/src/document.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

import 'dart:html' as html;

Future<PDFDocument> fromFileWeb(dynamic file) async {
  file as html.File;
  final document = PDFDocument();
  document.filePathPublic = file.relativePath;
  try {
    PdfDocument testdoc = await PdfDocument.openFile(file.relativePath ?? '');

// final result = await context.callMethod('getNumberOfPages', [file.relativePath]);
//  final pageCount = result['pageCount'] as String;
//  document.count = int.parse(pageCount);

    document.count = testdoc.pagesCount;
  } catch (e) {
    throw Exception('Error reading PDF!');
  }
  return document;
}


Future<PDFDocument> fromAssetWeb(String asset) async {
final document = PDFDocument();
try {
// Load the asset data.
final data = await rootBundle.load(asset);
final bytes = data.buffer.asUint8List();

// Create a Blob from the asset data.
final blob = html.Blob([Uint8List.fromList(bytes)]);

// Get the URL of the Blob.
final url = html.Url.createObjectUrlFromBlob(blob);

PdfDocument testdoc = await PdfDocument.openAsset(asset);
final result = testdoc.pagesCount;

// Call the JavaScript function 'getNumberOfPages' with the URL.
// final result = context.callMethod('getNumberOfPages', [url]);

// Release the URL object to free up resources.
//html.Url.revokeObjectUrl(url);

// Process 'result' as needed to extract information from JavaScript.
final pageCount = result;

document.filePathPublic = asset;

document.count = pageCount;
} catch (e) {
throw Exception('Error reading PDF!');
}
return document;
}


Future<String> getPageWeb(int page,String filePathPublic) async {
  var bytes = await getUint8ListFromBlobUrl(filePathPublic??'');
  PdfDocument testdoc = await PdfDocument.openData(bytes);
  PdfPage pagee = await testdoc.getPage(page);
  PdfPageImage? pageImage = await pagee.render(width: pagee.width, height: pagee.height,format: PdfPageImageFormat.png);

  final blob = html.Blob([pageImage?.bytes]);

  // Create a data URL from the Blob.
  final url = html.Url.createObjectUrl(blob);

  return url;
}

Future<Uint8List> getUint8ListFromBlobUrl(String blobUrl) async {
  final request = await html.HttpRequest.request(blobUrl, responseType: 'blob');
  final blob = request.response as html.Blob;

  // Create a FileReader to read the Blob data.
  final reader = html.FileReader();
  final completer = Completer<Uint8List>();

  reader.onLoad.listen((event) {
    final dataUrl = reader.result as String;
    final base64String = dataUrl.split(',')[1];
    final uint8List = Uint8List.fromList(base64.decode(base64String));
    completer.complete(uint8List);
  });

  reader.onError.listen((event) {
    completer.completeError('Error reading Blob data.');
  });

  reader.readAsDataUrl(blob);

  return completer.future;
}
