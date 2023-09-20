import 'dart:async';
import 'dart:io';

import 'package:advance_pdf_viewer2/src/io/helper.dart'
     if (dart.library.io) 'package:advance_pdf_viewer2/src/io/helper.dart'
     if (dart.library.html) 'package:advance_pdf_viewer2/src/web/helper.dart';
import 'package:advance_pdf_viewer2/src/page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class PDFDocument {
  static const MethodChannel _channel =
  MethodChannel('flutter_plugin_pdf_viewer');

  String? filePathPublic;
  late int count;
  final _pages = <PDFPage>[];
  bool _preloaded = false;
  String? get filePath => filePathPublic;

  /// Load a PDF File from a given File
  /// [File file], file to be loaded
  ///
  static Future<PDFDocument> fromFile(dynamic file) async {

    if (kIsWeb) {
      return fromFileWeb(file);
    } else {
      file as File;
      final document = PDFDocument();
      document.filePathPublic = file.path;
      try {
        final pageCount = await _channel
            .invokeMethod('getNumberOfPages', {'filePath': file.path});
        document.count = document.count = int.parse(pageCount as String);
      } catch (e) {
        throw Exception('Error reading PDF!');
      }
      return document;
    }
  }



  /// Load a PDF File from a given URL.
  /// File is saved in cache
  /// [String url] url of the pdf file
  /// [Map<String,String headers] headers to pass for the [url]
  /// [CacheManager cacheManager] to provide configuration for
  /// cache management
  static Future<PDFDocument> fromURL(String url,
      {Map<String, String>? headers, CacheManager? cacheManager}) async {

    if (kIsWeb) {
      throw Exception('unsupported for web');
    } else {
      // Download into cache
      final f = await (cacheManager ?? DefaultCacheManager())
          .getSingleFile(url, headers: headers);
      final document = PDFDocument();
      document.filePathPublic = f.path;
      try {
        final pageCount =
        await _channel.invokeMethod('getNumberOfPages', {'filePath': f.path});
        document.count = document.count = int.parse(pageCount as String);
      } catch (e) {
        throw Exception('Error reading PDF!');
      }
      return document;
    }
  }

  /// Load a PDF File from assets folder
  /// [String asset] path of the asset to be loaded
  ///
  static Future<PDFDocument> fromAsset(String asset) async {

    if (kIsWeb) {
      return fromAssetWeb(asset);
    } else {
      File file;
      try {
        final dir = await getApplicationDocumentsDirectory();
        file = File("${dir.path}/${DateTime
            .now()
            .millisecondsSinceEpoch}.pdf");
        final data = await rootBundle.load(asset);
        final bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes, flush: true);
      } catch (e) {
        throw Exception('Error parsing asset file!');
      }
      final document = PDFDocument();
      document.filePathPublic = file.path;

      try {
        final pageCount = await _channel
            .invokeMethod('getNumberOfPages', {'filePath': file.path});
        document.count = document.count = int.parse(pageCount as String);
      } catch (e) {
        throw Exception('Error reading PDF!');
      }
      return document;
    }
  }




  /// Load specific page
  ///
  /// [page] defaults to `1` and must be equal or above it
  Future<PDFPage> get({
    int page = 1,
    final Function(double)? onZoomChanged,
    final int? zoomSteps,
    final double? minScale,
    final double? maxScale,
    final double? panLimit,
  }) async {
    assert(page > 0);
    if (_preloaded && _pages.isNotEmpty) return _pages[page - 1];

    final data = kIsWeb ? await getPageWeb(page,filePathPublic!) : await _channel
        .invokeMethod('getPage', {'filePath': filePathPublic, 'pageNumber': page});
    return PDFPage(
      data as String?,
      page,
      onZoomChanged: onZoomChanged,
      zoomSteps: zoomSteps ?? 3,
      minScale: minScale ?? 1.0,
      maxScale: maxScale ?? 5.0,
      panLimit: panLimit ?? 1.0,
    );
  }

  Future<void> preloadPages({
    final Function(double)? onZoomChanged,
    final int? zoomSteps,
    final double? minScale,
    final double? maxScale,
    final double? panLimit,
  }) async {
    int countvar = 1;
    for (final _ in List.filled(count, null)) {
      final data = kIsWeb ? await getPageWeb(countvar,filePathPublic!) : await _channel.invokeMethod(
          'getPage', {'filePath': filePathPublic, 'pageNumber': countvar});
      _pages.add(PDFPage(
        data as String?,
        countvar,
        onZoomChanged: onZoomChanged,
        zoomSteps: zoomSteps ?? 3,
        minScale: minScale ?? 1.0,
        maxScale: maxScale ?? 5.0,
        panLimit: panLimit ?? 1.0,
      ));
      countvar++;
    }
    _preloaded = true;
  }

  // Stream all pages
  Stream<PDFPage?> getAll({final Function(double)? onZoomChanged}) {
    return Future.forEach<PDFPage?>(List.filled(count, null), (i) async {
      final data = kIsWeb ? await getPageWeb(i as int,filePathPublic!) : await _channel
          .invokeMethod('getPage', {'filePath': filePathPublic, 'pageNumber': i});
      return PDFPage(
        data as String?,
        1,
        onZoomChanged: onZoomChanged,
      );
    }).asStream() as Stream<PDFPage?>;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PDFDocument &&
              runtimeType == other.runtimeType &&
              filePathPublic == other.filePathPublic;

  @override
  int get hashCode => Object.hash(filePathPublic, count);





}
