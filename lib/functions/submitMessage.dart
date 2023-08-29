import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';

void submitMessage(
    BuildContext context, TextEditingController textController) async {
  Color pickerColor = Theme.of(context).colorScheme.onPrimary;
  final text = textController.text;
  final myUserId = supabase.auth.currentUser!.id;
  if (text.isEmpty) {
    context.showSnackBar(
      title: 'No tan rapido 📣',
      message: 'Escribe un mensaje',
      messageColor: pickerColor,
    );
    return;
  }
  textController.clear();
  try {
    await supabase.from('messages').insert({
      'profile_id': myUserId,
      'content': text,
      'file_path': '',
    });
  } on PostgrestException catch (e) {
    context.showErrorSnackBar(message: e.message);
  } catch (_) {
    context.showErrorSnackBar(message: unexpectedErrorMessage);
  }
}
