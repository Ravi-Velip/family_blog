import 'package:flutter/material.dart';

//pages
import 'homepage.dart';
import 'loginpage.dart';
import 'signuppage.dart';
import 'settings.dart';
import 'profile.dart';
import 'familypage.dart';
import 'createpost.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {



  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'PTSans',
      ),
      home: LoginPage(),
      routes: <String, WidgetBuilder>{
        '/landingpage': (BuildContext context) => new MyApp(),
        '/signup': (BuildContext context) => new SignupPage(),
        '/login': (BuildContext context) => new LoginPage(),
        '/profilepage': (BuildContext context) => new Profile(),
        '/settingspage': (BuildContext context) => new Settings(),
        '/homepage': (BuildContext context) => new HomePage(),
        '/familypage': (BuildContext context) => new Family(),
        '/selectpostimages': (BuildContext context) => new CreatePost(),
      },
    );
  }
}
