import 'package:flutter/material.dart';
import 'package:mendoza_family_app/pages/home_page.dart';
import 'package:mendoza_family_app/pages/login_page.dart';
import 'package:mendoza_family_app/util/common_util.dart';
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
        initialRoute: 'home',
        routes: {
          'home': (context) => tryLogin(),
          'search': (context) => trySearchPage(),
        },
        home: tryLogin());
  }

  Widget tryLogin() {
    return FutureBuilder(
      future: getCachedUser(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const CircularProgressIndicator();
          default:
            if (snapshot.hasData) {
              if (snapshot.data != null) {
                return const CommonScaffold(
                    title: "Mendoza Family Book", child: HomePage());
              }
            }
            return const CommonScaffold(
                title: "Which Mendoza Are You?", child: LoginPage());
        }
      },
    );
  }

  Widget trySearchPage() {
    return FutureBuilder(
      future: getCachedUser(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const CircularProgressIndicator();
          default:
            return snapshot.hasData && snapshot.data != null
                ? SearchPage(user: snapshot.data!)
                : const CommonScaffold(
                    title: "Which Mendoza Are You?", child: LoginPage());
        }
      },
    );
  }
}
