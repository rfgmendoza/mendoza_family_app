import 'package:flutter/material.dart';
import 'package:mendoza_family_app/util/common_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<User?> _user;
  final Future<SharedPreferences> _savedata = SharedPreferences.getInstance();
  Widget? searchButton;

  @override
  void initState() {
    super.initState();
    _user = getCachedUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _user,
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const CircularProgressIndicator();
          default:
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              if (snapshot.hasData) {
                return Text(
                    'user: ${snapshot.data!.id} ${snapshot.data!.name}');
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("No User set"),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, "login");
                          },
                          child: const Text("Set Your Identity"))
                    ],
                  ),
                );
              }
            }
        }
      },
    );
  }
}
