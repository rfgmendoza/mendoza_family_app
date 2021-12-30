import 'package:flutter/material.dart';
import 'package:mendoza_family_app/pages/home_page.dart';
import 'package:mendoza_family_app/pages/login_page.dart';
import 'package:mendoza_family_app/widgets/people_picker_page.dart';
import 'package:mendoza_family_app/pages/search_page.dart';
import 'package:mendoza_family_app/widgets/common_scaffold.dart';

void main() {
  runApp(const MendozaFamilyApp());
}

class MendozaFamilyApp extends StatelessWidget {
  const MendozaFamilyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        initialRoute: 'login',
        routes: {
          'home': (context) => const CommonScaffold(
              title: "Mendoza Family Book", child: HomePage()),
          'search': (context) => const SearchPage(),
          'login': (context) => const CommonScaffold(
              title: "Which Mendoza are you?", child: LoginPage())
        },
        home: const HomePage());
  }
}
