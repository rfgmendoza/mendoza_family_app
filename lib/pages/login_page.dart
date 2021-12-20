import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mendoza_family_app/util/common_util.dart';
import 'package:toast/toast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List _items = [];
  List<FamilyPerson> _searchResult = [];

  Future<void> readJson() async {
    final String response =
        await rootBundle.loadString('data/family_book.json');
    final data = await json.decode(response);
    setState(() {
      _items = data["families"];
    });
  }

  void confirmAlert(String userName, String userId) {
    Widget cancelButton =
        TextButton(onPressed: () {}, child: const Text("Cancel"));
    Widget confirmButton = TextButton(
        onPressed: () async {
          bool result = await setCachedUser(userName, userId);
          if (result) {
            Toast.show("Set your User details, Welcome!", context,
                duration: Toast.lengthShort);
            Navigator.of(context).pop();
          } else {
            Toast.show("Failed to set user details, try again", context,
                duration: Toast.lengthShort);
            Navigator.pushReplacementNamed(context, "home");
          }
        },
        child: const Text("Confirm"));

    AlertDialog alert = AlertDialog(
        title: const Text("Confirm Selection"),
        content: const Text("Are you sure this you?"),
        actions: [cancelButton, confirmButton]);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        });
  }

  Widget _buildSearchResults() {
    return ListView.builder(
        itemCount: _searchResult.length,
        itemBuilder: (context, i) {
          return Card(
              child: ListTile(
                  trailing: ElevatedButton(
                    child: const Text("Select"),
                    onPressed: () {
                      confirmAlert(_searchResult[i].name, _searchResult[i].id);
                    },
                  ),
                  leading: Text(_searchResult[i].id),
                  title: Text(
                    _searchResult[i].name,
                  ),
                  subtitle: Text(_searchResult[i].spouse)));
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      readJson();
    }
    // TODO: remove and replace with better initial state?
    if (_items.isNotEmpty && _searchResult.isEmpty) {
      List<FamilyPerson> searchResults = search("rafael", _items);
      setState(() {
        _searchResult = searchResults;
      });
    }
    TextEditingController controller = TextEditingController();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("Enter Name or Family Id"),
            TextField(controller: controller),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    String searchtext = controller.text;
                    List<FamilyPerson> searchResults =
                        search(searchtext, _items);
                    setState(() {
                      _searchResult = searchResults;
                    });
                  },
                  child: const Icon(Icons.search),
                ),
              ],
            ),
            Expanded(
                child: SizedBox(
              height: 200.0,
              child: _searchResult.isNotEmpty
                  ? _buildSearchResults()
                  : Container(),
            ))
          ],
        ),
      ),
    );
  }
}
