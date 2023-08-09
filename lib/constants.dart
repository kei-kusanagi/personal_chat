import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';

/// Supabase client
final supabase = Supabase.instance.client;

/// Simple preloader inside a Center widget
const preloader = Center(child: CircularProgressIndicator(color: Colors.green));

/// Simple sized box to space out form elements
const formSpacer = SizedBox(width: 16, height: 16);

/// Some padding for all the forms to use
const formPadding = EdgeInsets.symmetric(vertical: 20, horizontal: 16);

/// Error message to display the user when unexpected error occurs.
const unexpectedErrorMessage = 'Unexpected error occurred.';

/// Set of extension methods to easily display a snackbar
extension ShowSnackBar on BuildContext {
  /// Displays a basic snackbar

  void showSnackBar({
    required BuildContext context,
    required String message,
    required Color messageColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: messageColor,
    ));
  }

  /// Displays a red snackbar indicating error
  void showErrorSnackBar({context, required String message}) {
    showSnackBar(
      context: context,
      message: message,
      messageColor: Colors.red,
    );
  }
}

Logout(BuildContext context) {
  supabase.auth.signOut();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Logout realizado con éxito'),
      duration: Duration(seconds: 3),
    ),
  );
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => home_screen(title: 'Bienvenido')),
    (route) => false,
  );
}
