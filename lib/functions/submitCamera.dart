import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';
import '../screens/camera_screen.dart';
import '../screens/chat_page.dart';

void submitCamera(BuildContext context) async {
  Color pickerColor = Theme.of(context).colorScheme.primary;
  final ImagePicker picker = ImagePicker();

  XFile? photo;

  if (Platform.isWindows) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const windows_camera()),
    );
  } else {
    photo = await picker.pickImage(source: ImageSource.camera);
  }

  String filePath = '';
  final myUserId = supabase.auth.currentUser!.id;
  final SupabaseClient client = SupabaseClient(supabaseUrl, supabaseKey);

  final File imageFile = File(photo!.path);

  await client.storage
      .from('Files')
      .upload(photo.name, imageFile)
      .then((response) {
    filePath = response;
  });

  try {
    await supabase.from('messages').insert({
      'profile_id': myUserId,
      'content':
          'https://bdhwkukeejylmfoxyygb.supabase.co/storage/v1/object/public/$filePath',
      'file_path': '',
    });
    context.showSnackBar(
      message: "Foto subida correctamente 🖼",
      messageColor: pickerColor,
      title: '📷 Listo!!!',
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
