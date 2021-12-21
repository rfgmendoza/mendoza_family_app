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

  void confirmAlert(String userName, String userId) {
    Widget cancelButton = TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text("Cancel"));
    Widget confirmButton = TextButton(
        onPressed: () async {
          bool result = await setCachedUser(userName, userId);
          if (result == true) {
            Toast.show("Set your User details, Welcome!", context,
                duration: Toast.lengthShort);
            Navigator.pushNamedAndRemoveUntil(
                context, "home", (route) => false);
          } else {
            Toast.show("Failed to set user details, try again", context,
                duration: Toast.lengthShort);
            Navigator.of(context).pop();
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
      readFamilyJson().then((value) => {
            setState(() {
              _items = value;
            })
          });
    }
    TextEditingController controller = TextEditingController();
    void submitSearch(String searchText) {
      List<FamilyPerson> searchResults = search(searchText, _items);
      setState(() {
        _searchResult = searchResults;
      });
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Enter Name or Family Id",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4.0, 0, 0, 0),
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        submitSearch(value);
                      },
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    String searchtext = controller.text;
                    submitSearch(searchtext);
                  },
                  child: const Icon(
                    Icons.search,
                    size: 40.0,
                  ),
                ),
              ],
            ),
            _searchResult.isNotEmpty
                ? Expanded(
                    child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 0),
                    child:
                        SizedBox(height: 200.0, child: _buildSearchResults()),
                  ))
                : Container()
          ],
        ),
      ),
    );
  }
}
