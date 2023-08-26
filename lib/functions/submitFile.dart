import 'dart:io';

import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thumblr/thumblr.dart';

import '../constants.dart';
import '../screens/chat_page.dart';

String supabaseUrl = 'https://bdhwkukeejylmfoxyygb.supabase.co';
String supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaHdrdWtlZWp5bG1mb3h5eWdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTAyMzM1MjMsImV4cCI6MjAwNTgwOTUyM30.9civyOj1ITEsIAFcwc0nrQB6ihqEcsg2hp2emylRaRQ';

void submitFile(context) async {
  String supabaseFilePath = '';
  String thumbnailFilePath = '';
  String pickedFileName = '';
  final myUserId = supabase.auth.currentUser!.id;
  final SupabaseClient client = SupabaseClient(supabaseUrl, supabaseKey);
  var pickedFile = await FilePicker.platform.pickFiles(allowMultiple: false);

  if (pickedFile != null) {
    final file = File(pickedFile.files.first.path!);
    await client.storage
        .from('Files')
        .upload(pickedFile.files.first.name, file)
        .then((response) {
      supabaseFilePath = response;
    });

    bool _isVideo(String url) {
      final videoExtensions = ['.mp4', '.avi', '.mov', '.mkv', '.flv', '.wmv'];
      final fileExtension = url.toLowerCase();

      return videoExtensions
          .any((extension) => fileExtension.endsWith(extension));
    }

    bool isVideoLink = _isVideo(supabaseFilePath);
    Uint8List? _imageBytes;
    String? _imagePath;
    if (isVideoLink) {
      if (Platform.isWindows) {
        Thumbnail? _thumb;
        try {
          _thumb = await generateThumbnail(
            filePath: pickedFile.files.first.path!,
            position: 0.0,
          );
        } on PlatformException catch (e) {
          debugPrint('Failed to generate thumbnail: ${e.message}');
        } catch (e) {
          debugPrint('Failed to generate thumbnail: ${e.toString()}');
        }

        Thumbnail? _thumbnail = _thumb;
        if (_thumb?.image != null) {
          _thumb!.image
              .toByteData(format: ui.ImageByteFormat.png)
              .then((byteData) async {
            if (byteData != null) {
              _imageBytes = byteData.buffer.asUint8List();
              final directory = await getTemporaryDirectory();
              pickedFileName = pickedFile.files.first.name;

              pickedFileName =
                  pickedFileName.substring(0, pickedFileName.lastIndexOf('.'));
              final imagePath = '${directory.path}/${pickedFileName}.png';
              final imageFile = File(imagePath);

              await imageFile.writeAsBytes(_imageBytes!);
              _imagePath = imagePath;
              thumbnailFilePath = imagePath;
            }
          });
        } else {
          _imageBytes = null;
          _imagePath = null;
        }
      } else {
        try {
          String? thumbnailPath = await videoThumbnail(
              'https://bdhwkukeejylmfoxyygb.supabase.co/storage/v1/object/public/$supabaseFilePath');
          final miniatura = File(thumbnailPath!);
          pickedFileName = pickedFile.files.first.name;

          pickedFileName =
              pickedFileName.substring(0, pickedFileName.lastIndexOf('.'));

          await client.storage
              .from('Files')
              .upload('$pickedFileName.png', miniatura)
              .then((response) {
            thumbnailFilePath =
                'https://bdhwkukeejylmfoxyygb.supabase.co/storage/v1/object/public/$response';
          });
        } catch (e) {
          print(e);
        }
      }
    } else {
      thumbnailFilePath = '';
    }

    try {
      await supabase.from('messages').insert({
        'profile_id': myUserId,
        'content':
            'https://bdhwkukeejylmfoxyygb.supabase.co/storage/v1/object/public/$supabaseFilePath',
        'file_path': thumbnailFilePath
      });

      context.showSnackBar(
        message: "📎 Archivo subido 📂",
        messageColor: Colors.blue,
        title: '😎 Listo!!!',
      );
    } on StorageException catch (error) {
      context.showErrorSnackBar(
        message: error.message,
      );
    } catch (e) {
      context.showErrorSnackBar(
        message: unexpectedErrorMessage,
      );
    }
  }
}
