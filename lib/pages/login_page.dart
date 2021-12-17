import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List _items = [];
  List _searchResult = [];
  TextEditingController controller = TextEditingController();

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
        itemCount: _searchResult.length, itemBuilder: (context, i) {
          return Card(child: ListTile(leading: Text(_searchResult[i].)))
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      readJson();
    }
    int itemCount = _items.length;
    return Center(
      child: Form(
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
                      return;
                    },
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
