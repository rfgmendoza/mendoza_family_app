import 'package:flutter/material.dart';
import 'package:mendoza_family_app/util/common_util.dart';

class PeoplePickerPage extends StatefulWidget {
  const PeoplePickerPage({Key? key}) : super(key: key);

  @override
  _PeoplePickerPageState createState() => _PeoplePickerPageState();
}

class _PeoplePickerPageState extends State<PeoplePickerPage> {
  List _items = [];
  List<FamilyPerson> _searchResult = [];

  Future<bool> confirmAlert(FamilyPerson person) async {
    Widget cancelButton = TextButton(
        onPressed: () {
          Navigator.pop(context, false);
        },
        child: const Text("Cancel"));
    Widget confirmButton = TextButton(
        onPressed: () async {
          Navigator.pop(context, true);
        },
        child: const Text("Confirm"));

    AlertDialog alert = AlertDialog(
        title: const Text("Confirm Selection"),
        content: const Text("Are you sure this you?"),
        actions: [cancelButton, confirmButton]);
    return await showDialog(
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
                    onPressed: () async {
                      final result = await confirmAlert(_searchResult[i]);
                      if (result) {
                        Navigator.pop(context, _searchResult[i]);
                      }
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

    return Scaffold(
      body: Center(
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
      ),
    );
  }
}
