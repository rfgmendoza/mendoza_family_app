import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mendoza_family_app/util/common_util.dart';

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

  Widget _buildSearchResults() {
    return ListView.builder(
        itemCount: _searchResult.length,
        itemBuilder: (context, i) {
          return Card(
              child: ListTile(
                  leading: Text(_searchResult[i].id),
                  title: Text(
                    _searchResult[i].name,
                  ),
                  subtitle: Text(_searchResult[i].spouse)));
        });
  }

  List<FamilyPerson> search(String searchText, List items) {
    if (searchText.isEmpty) {
      return [];
    }
    Queue searchNodes = Queue.from(_items);
    List<FamilyPerson> foundPeople = [];
    List<String> searchFields = ["id", "name", "spouse"];
    while (searchNodes.isNotEmpty) {
      var node = searchNodes.removeFirst();
      bool found = false;
      for (var field in searchFields) {
        if (node[field]
            .toString()
            .toUpperCase()
            .contains(searchText.toUpperCase())) {
          found = true;
        }
      }
      if (found) {
        foundPeople.add(FamilyPerson(
            id: node["id"],
            name: node["name"],
            spouse: node["spouse"],
            deceased: node["deceased"],
            spouseDeceased: node["spouseDeceased"]));
      }
      if (node["children"] != null && node["children"] != []) {
        searchNodes.addAll(node["children"]);
      }
    }
    return foundPeople;
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      readJson();
    }
    // TODO: remove
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
