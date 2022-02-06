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
  late FamilyPerson sourcePerson;
  FamilyPerson? targetPerson;

  @override
  void initState() {
    super.initState();
    sourcePerson = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Mendoza Family Book"),
          centerTitle: true,
          leading: Image.asset('assets/MendozaLogo.png'),
        ),
        body: Builder(builder: (context) {
          return searchOptions(context);
        }));
  }

  Widget personCard(FamilyPerson? person) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 64.0, 0),
            child: Card(
              color: Colors.lightBlue[200],
              child: personTile(sourcePerson,
                  trailing: sourcePerson.id != widget.user.id
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    sourcePerson = widget.user;
                                  });
                                },
                                icon: const Icon(Icons.person_off_rounded)),
                          ],
                        )
                      : IconButton(
                          onPressed: () {
                            _openPeoplePicker(targetPerson?.id[0])
                                .then((value) => {
                                      if (value != null)
                                        {
                                          setState(() {
                                            targetPerson =
                                                value as FamilyPerson;
                                          })
                                        }
                                    });
                          },
                          icon: const Icon(Icons.person_search_rounded))),
            ),
          ),
          const Divider(),
          person != null
              ? Column(
                  children: [
                    Text(
                        getRelationshipDescription(sourcePerson.id, person.id)),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(64.0, 0, 8.0, 0),
                      child: Card(
                        color: Colors.lightGreen[200],
                        child: personTile(
                          person,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
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
                                  icon:
                                      const Icon(Icons.person_search_rounded)),
                            ],
                          ),
                        ),
                      ),
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
    ]);
  }

  Widget searchOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        personCard(targetPerson),
        ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GraphRenderer(
                          user: widget.user, targetUser: targetPerson)));
            },
            child: Text(targetPerson != null
                ? "See Relationship Tree"
                : "See Full Family Tree")),
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
