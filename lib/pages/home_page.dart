import 'package:flutter/material.dart';
import 'package:mendoza_family_app/util/user_class.dart';
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
    _user = _savedata.then((SharedPreferences prefs) {
      String? username = prefs.getString('userName');
      String? userid = prefs.getString('userId');
      if (userid != null && username != null) {
        return User(userid, username);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('Mendoza Family Book - Home'),
        // actions: [IconButton(onPressed: _searchMode, icon: customIcon)],
        centerTitle: true,
      ),
      body: Center(
        child: FutureBuilder<User?>(
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
                    return const Center(
                      child: Text("No User"),
                    );
                  }
                }
            }
          },
        ),
      ),
    );
  }
}
