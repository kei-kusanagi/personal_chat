// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

void downloadFile(context, String url) async {
  bool dounloadError = false;
  String errorMessage = '';
  await FileDownloader.downloadFile(
    url: url,
    onDownloadCompleted: (String path) {
      dounloadError = false;
      context.showSnackBar(
        message: 'guardado en la galeria 📂',
        messageColor: Theme.of(context).colorScheme.inversePrimary,
        title: '📎 Tu archivo fue',
      );
    },
    onDownloadError: (String error) {
      dounloadError = true;

      errorMessage = error;
    },
  );
  if (dounloadError) {
    context.showErrorSnackBar(
        message: '❌ Error al descargar el archivo: $errorMessage');
  }
}
