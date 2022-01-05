import 'package:flutter/material.dart';
import 'package:mendoza_family_app/pages/search_page.dart';
import 'package:mendoza_family_app/util/common_util.dart';
import 'package:mendoza_family_app/pages/login_page.dart';
import 'package:mendoza_family_app/util/common_widgets.dart';
import 'package:mendoza_family_app/widgets/people_picker_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<FamilyPerson?> _user;
  Widget? searchButton;

  @override
  void initState() {
    super.initState();
    _user = getCachedUser();
  }

  void _navigateToPeoplePicker(BuildContext context) async {
    final peoplePickerResult = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const PeoplePickerPage(),
            fullscreenDialog: true));
    bool result = await setCachedUser(peoplePickerResult as FamilyPerson);
    if (result == true) {
      Navigator.of(context).pushReplacementNamed("home");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FamilyPerson?>(
      future: _user,
      builder: (BuildContext context, AsyncSnapshot<FamilyPerson?> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const CircularProgressIndicator();
          default:
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              if (snapshot.hasData) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: personTile(snapshot.data!,
                            trailing: ElevatedButton(
                                onPressed: () {
                                  _navigateToPeoplePicker(context);
                                },
                                child: const Text("Change"))),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SearchPage(user: snapshot.data!)));
                          },
                          child: const Text("Find Relative"))
                    ],
                  ),
                );
              } else {
                return const LoginPage();
              }
            }
        }
      },
    );
  }
}
