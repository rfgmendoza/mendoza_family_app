import 'package:flutter/material.dart';
import 'package:mendoza_family_app/pages/login_page.dart';
import 'package:mendoza_family_app/util/common_util.dart';
import 'package:mendoza_family_app/util/common_widgets.dart';
import 'package:mendoza_family_app/util/translation.dart';
import 'package:mendoza_family_app/widgets/graph_renderer.dart';
import 'package:mendoza_family_app/widgets/people_picker_page.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scan/scan.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final Translation _trans = Translation();
  bool _isEnglish = true;
  bool _qrMode = false;
  ScanController scanController = ScanController();

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
        floatingActionButton: !kIsWeb && _qrMode
            ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _qrMode = !_qrMode;
                  });
                },
                child: const Icon(Icons.cancel_sharp))
            : null,
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
                      return _qrMode
                          ? qrCodeScanner()
                          : searchOptions(context, snapshot.data!);
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

  Widget qrCodeScanner() {
    return Center(
      child: ScanView(
          controller: scanController,
          scanAreaScale: 0.7,
          scanLineColor: Colors.red,
          onCapture: (data) {
            _getQrCode(data);
          }),
    );
  }

  void _getQrCode(String qrcode) {
    FamilyPerson? person;
    readFamilyJson()
        .then((value) => searchExactId(qrcode, value))
        .then((value) => {
              if (value != null) {setCachedUser(value, target: true)}
            })
        .whenComplete(() => setState(
              () {
                _qrMode = false;
              },
            ));
  }

  Widget personCards(FamilyPerson sourcePerson, FamilyPerson? person) {
    return Column(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Let others scan this QR code from within the app",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              color: calcNodeColor(true, false, sourcePerson.deceased),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 5.0,
                  child: QrImage(
                    data: sourcePerson.id,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 64.0, 0),
          child: Card(
              color: calcNodeColor(true, false, sourcePerson.deceased),
              child: personTile(sourcePerson,
                  trailing: Ink(
                      decoration: const ShapeDecoration(
                          shape: CircleBorder(), color: Colors.white60),
                      child: IconButton(
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
                          icon: const Icon(Icons.person_search_rounded))))),
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
                      color: calcNodeColor(false, true, person.deceased),
                      child: personTile(
                        person,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Ink(
                              decoration: const ShapeDecoration(
                                  shape: CircleBorder(), color: Colors.white60),
                              child: IconButton(
                                  onPressed: () {
                                    clearCachedUser(target: true)
                                        .whenComplete(() => setState(() {}));
                                  },
                                  icon: const Icon(Icons.person_remove)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              )
            : Center(
                child: ElevatedButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text("Click Here to Find Family Member"),
                      Icon(Icons.person_add_alt_outlined),
                    ],
                  ),
                  onPressed: () {
                    _openPeoplePicker(sourcePerson.id[0])
                        .then((value) =>
                            setCachedUser(value as FamilyPerson, target: true))
                        .whenComplete(() => setState(
                              () {},
                            ));
                  },
                ),
              ),
      ],
    );
  }

  Widget searchOptions(
      BuildContext context, Map<String, FamilyPerson> peopleMap) {
    FamilyPerson user = peopleMap["user"]!;
    FamilyPerson? targetPerson = peopleMap["target"];
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: [
            personCards(user, targetPerson),
            !kIsWeb
                ? ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _qrMode = !_qrMode;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: const [
                        Text("Click to scan a QR code "),
                        Icon(Icons.qr_code_scanner),
                      ],
                    ))
                : Container(),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GraphRenderer(
                              user: user, targetUser: targetPerson)));
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
