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
    // required context,
    required String message,
    required Color messageColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      duration: const Duration(seconds: 1),
      content: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            height: 90,
            decoration: BoxDecoration(
                color: messageColor,
                borderRadius: const BorderRadius.all(Radius.circular(20))),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '😁 Listo...!',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.swipe_down,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
    ));
  }

  /// Displays a red snackbar indicating error
  void showErrorSnackBar({context, required String message}) {
    showSnackBar(
      // context: context,
      message: message,
      messageColor: Colors.red,
    );
  }
}

logout(BuildContext context) async {
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
