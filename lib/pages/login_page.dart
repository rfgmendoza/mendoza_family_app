import 'package:flutter/material.dart';
import 'package:mendoza_family_app/util/translation.dart';
import 'package:mendoza_family_app/widgets/people_picker_page.dart';

import '../util/common_util.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: ElevatedButton(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Translation().getString("Who are you?")),
            const Icon(Icons.person_search_rounded)
          ],
        ),
      ),
      onPressed: () {
        _navigateToPeoplePicker(context);
      },
    ));
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
}
