import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class WebFileService {
  static Future<void> downloadText({
    required String filename,
    required String content,
    required String mimeType,
  }) async {
    if (!kIsWeb) {
      return;
    }

    final bytes = utf8.encode(content);
    final blob = html.Blob(<Object>[bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    try {
      final anchor = html.AnchorElement(href: url)
        ..download = filename
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } finally {
      html.Url.revokeObjectUrl(url);
    }
  }

  static Future<String?> pickTextFile({
    String accept = '.json,application/json',
  }) async {
    if (!kIsWeb) {
      return null;
    }

    final input = html.FileUploadInputElement()..accept = accept;
    final changeFuture = input.onChange.first;
    final focusFuture = html.window.onFocus.first;

    input.click();
    await Future.any<void>(<Future<void>>[changeFuture, focusFuture]);

    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      return null;
    }

    final reader = html.FileReader();
    final completer = Completer<String?>();

    reader.onLoad.first.then((_) {
      completer.complete(reader.result as String?);
    });
    reader.onError.first.then((_) {
      completer.completeError(
        StateError('Unable to read the selected backup file.'),
      );
    });

    reader.readAsText(file);
    return completer.future;
  }
}
