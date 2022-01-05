import 'package:flutter/material.dart';

class CommonScaffold extends StatelessWidget {
  const CommonScaffold({
    Key? key,
    required String title,
    required Widget child,
  })  : child = child,
        title = title,
        super(key: key);

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(title),
        // actions: [IconButton(onPressed: _searchMode, icon: customIcon)],
        centerTitle: true,
      ),
      body: Center(child: child),
    );
  }
}
