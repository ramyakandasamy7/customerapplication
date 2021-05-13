import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_builder.dart';
import 'package:my_app/home.dart';
import 'package:splashscreen/splashscreen.dart';
import './register_page.dart';
import './signin_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

/// The entry point of the application.
///
/// Returns a [MaterialApp].
///
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meet Up',
      theme: ThemeData(
        // Define the default brightness and colors.
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        accentColor: Colors.cyan[600],

        // Define the default font family.s

        // Define the default TextTheme. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: TextTheme(
          headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
          headline6: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
          bodyText2: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
        ),
      ),
      home: IntroScreen(),
    );
  }
}

class IntroScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User result = FirebaseAuth.instance.currentUser;
    return new SplashScreen(
        navigateAfterSeconds: result != null ? Home() : AuthTypeSelector(),
        seconds: 3,
        title: new Text(
          'Welcome to Basket!',
          style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
        ),
        loaderColor: Colors.blue);
  }
}

/// Provides a UI to select a authentication type page
class AuthTypeSelector extends StatelessWidget {
  // Navigates to a new page
  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginButton = Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(30.0),
      color: Color(0xFFAFB42B),
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        onPressed: () {
          _pushPage(context, SignInPage());
        },
        child: Text(
          "Login",
          textAlign: TextAlign.center,
        ),
      ),
    );
    final registrationButton = Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(30.0),
        color: Color(0xFFAFB42B),
        child: MaterialButton(
          minWidth: MediaQuery.of(context).size.width,
          padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          onPressed: () => _pushPage(context, RegisterPage()),
          child: Text(
            "Registration",
            textAlign: TextAlign.center,
          ),
        ));
    return Scaffold(
      appBar: AppBar(
        title: Text("Basket"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: 500.0,
            child: Image.asset(
              "assets/basket.jpg",
              fit: BoxFit.contain,
            ),
          ),
          loginButton,
          SizedBox(height: 20.0),
          registrationButton,
          SizedBox(height: 15.0),
        ],
      ),
    );
  }
}
