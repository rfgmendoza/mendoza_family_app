import 'package:flutter/material.dart';
import 'package:mendoza_family_app/pages/login_page.dart';
import 'package:mendoza_family_app/util/common_util.dart';
import 'package:mendoza_family_app/util/common_widgets.dart';
import 'package:mendoza_family_app/util/translation.dart';
import 'package:mendoza_family_app/widgets/graph_renderer.dart';
import 'package:mendoza_family_app/widgets/people_picker_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final Translation _trans = Translation();
  bool _isEnglish = true;

  @override
  void initState() {
    super.initState();
    _isEnglish = _trans.isEnglish;
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style =
        TextButton.styleFrom(primary: Theme.of(context).colorScheme.onPrimary);
    _trans.setLanguage(_isEnglish);
    return Scaffold(
        appBar: AppBar(
          title: Text(_trans.getString("mendoza_family_book")),
          centerTitle: true,
          leading: Image.asset('assets/MendozaLogo.png'),
          actions: [
            TextButton(
                style: style,
                onPressed: () => {
                      setState(
                        () {
                          _isEnglish = !_isEnglish;
                        },
                      )
                    },
                child: Text(_trans.getString("language")))
          ],
        ),
        body: Builder(builder: (context) {
          return FutureBuilder(
            future: getCachedUser(),
            builder: (BuildContext context,
                AsyncSnapshot<Map<String, FamilyPerson>> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const CircularProgressIndicator();
                default:
                  if (snapshot.hasData) {
                    if (snapshot.data != null &&
                        snapshot.data!.containsKey("user")) {
                      return searchOptions(context, snapshot.data!);
                    } else {
                      return const LoginPage();
                    }
                  } else {
                    return const LoginPage();
                  }
              }
            },
          );
        }));
  }

  Widget personCards(FamilyPerson sourcePerson, FamilyPerson? person) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 0, 64.0, 0),
          child: Card(
            color: Colors.lightBlue[200],
            child: personTile(sourcePerson,
                trailing: IconButton(
                    onPressed: () {
                      _openPeoplePicker(person?.id[0])
                          .then((value) => {
                                if (value != null)
                                  {setCachedUser(value as FamilyPerson)}
                              })
                          .whenComplete(() => setState(
                                () {},
                              ));
                    },
                    icon: const Icon(Icons.person_search_rounded))),
          ),
        ),
        const Divider(),
        person != null
            ? Column(
                children: [
                  Text(getRelationshipDescription(sourcePerson.id, person.id)),
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
                                  clearCachedUser(target: true)
                                      .whenComplete(() => setState(() {}));
                                },
                                icon: const Icon(Icons.person_remove)),
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
                        .then((value) =>
                            setCachedUser(value as FamilyPerson, target: true))
                        .whenComplete(() => setState(
                              () {},
                            ));
                  },
                ),
              )
      ],
    );
  }

  Widget searchOptions(
      BuildContext context, Map<String, FamilyPerson> peopleMap) {
    FamilyPerson user = peopleMap["user"]!;
    FamilyPerson? targetPerson = peopleMap["target"];
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Card(
          child: QrImage(
            data: user.id,
            version: QrVersions.auto,
            size: 200.0,
          ),
        ),
        personCards(user, targetPerson),
        ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          GraphRenderer(user: user, targetUser: targetPerson)));
            },
            child: Text(targetPerson != null
                ? _trans.getString("see_relationship_tree")
                : _trans.getString("see_full_tree"))),
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
