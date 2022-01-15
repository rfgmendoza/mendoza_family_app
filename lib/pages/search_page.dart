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
  late FamilyPerson sourcePerson;
  FamilyPerson? targetPerson;

  @override
  void initState() {
    super.initState();
    graphMode = false;
    sourcePerson = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: graphMode
            ? GraphRenderer(user: sourcePerson, targetUser: targetPerson)
            : searchOptions());
  }

  Widget personCard(FamilyPerson? person) {
    return Card(
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            personTile(sourcePerson,
                trailing: sourcePerson.id != widget.user.id
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            sourcePerson = widget.user;
                          });
                        },
                        icon: const Icon(Icons.person_off_rounded))
                    : IconButton(
                        onPressed: () {
                          _openPeoplePicker(targetPerson?.id[0])
                              .then((value) => {
                                    if (value != null)
                                      {
                                        setState(() {
                                          sourcePerson = value as FamilyPerson;
                                        })
                                      }
                                  });
                        },
                        icon: const Icon(Icons.person_search_rounded))),
            const Divider(),
            person != null
                ? Column(
                    children: [
                      Text(getRelationshipDescription(
                          sourcePerson.id, person.id)),
                      const Divider(),
                      personTile(
                        person,
                        trailing: IconButton(
                            onPressed: () {
                              _openPeoplePicker(sourcePerson.id[0])
                                  .then((value) => {
                                        if (value != null)
                                          {
                                            setState(() {
                                              sourcePerson =
                                                  value as FamilyPerson;
                                            })
                                          }
                                      });
                            },
                            icon: const Icon(Icons.person_search_rounded)),
                      )
                    ],
                  )
                : Center(
                    child: IconButton(
                      icon: const Icon(Icons.person_add_alt_outlined),
                      onPressed: () {
                        _openPeoplePicker(sourcePerson.id[0])
                            .then((value) => setState(() {
                                  targetPerson = value as FamilyPerson?;
                                }));
                      },
                    ),
                  )
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

  Future<Object?> _openPeoplePicker(String? familyGroup) async {
    return await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PeoplePickerPage(familyGroup: familyGroup),
            fullscreenDialog: true));
  }
}
