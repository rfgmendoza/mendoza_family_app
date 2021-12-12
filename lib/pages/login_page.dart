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

  Future<void> readJson() async {
    final String response =
        await rootBundle.loadString('data/family_book.json');
    final data = await json.decode(response);
    setState(() {
      _items = data["families"];
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
        child: Column(
          children: <Widget>[
            // _items.isNotEmpty ? Text(_items.length.toString()) : Container(),
            Text(itemCount.toString()),
            const TextField(),
            ElevatedButton(
              onPressed: () {
                return;
              },
              child: const Text("submit"),
            ),
          ],
        ),
      ),
    );
  }
}
