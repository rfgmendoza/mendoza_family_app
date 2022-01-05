import 'package:flutter/material.dart';
import 'package:mendoza_family_app/util/common_util.dart';
import 'package:mendoza_family_app/util/common_widgets.dart';
import 'package:mendoza_family_app/widgets/graph_renderer.dart';
import 'package:mendoza_family_app/widgets/people_picker_page.dart';

class SearchPage extends StatefulWidget {
  final FamilyPerson user;
  const SearchPage({Key? key, required this.user}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late bool graphMode;
  FamilyPerson? targetPerson;

  @override
  void initState() {
    super.initState();
    graphMode = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: graphMode ? GraphRenderer(user: widget.user) : searchOptions());
  }

  Widget personCard(FamilyPerson? person) {
    return Card(
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            personTile(widget.user),
            const Divider(),
            person != null
                ? Column(
                    children: [
                      Text(getRelationshipDescription(
                          widget.user.id, person.id)),
                      const Divider(),
                      personTile(person),
                    ],
                  )
                : Container(),
          ],
        ),
        ButtonBar(
          children: [
            ElevatedButton(
              child: const Text("Find Relative"),
              onPressed: () {
                _openPeoplePicker();
              },
            ),
          ],
        )
      ]),
    );
  }

  Widget searchOptions() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        personCard(targetPerson),
        ElevatedButton(
            onPressed: () {
              setState(() {
                graphMode = true;
              });
            },
            child: const Text("See Full Family Tree")),
      ]),
    );
  }

  Future<void> _openPeoplePicker() async {
    final peoplePickerResult = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const PeoplePickerPage(),
            fullscreenDialog: true));
    setState(() {
      targetPerson = peoplePickerResult as FamilyPerson?;
    });
  }
}
