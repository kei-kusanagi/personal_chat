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
    required String title,
    required String message,
    required Color messageColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      content: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 100,
          width: 400,
          decoration: BoxDecoration(
              color: messageColor,
              borderRadius: const BorderRadius.all(Radius.circular(20))),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 22, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Text(
                      message,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.topRight,
                child: const Icon(
                  Icons.swipe_down,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
    ));
  }

  /// Displays a red snackbar indicating error
  void showErrorSnackBar({context, required String message}) {
    showSnackBar(
      title: 'Ups🤔',
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
