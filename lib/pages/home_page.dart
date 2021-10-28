import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);
  final String userName = "Test User";

  @override
  Widget build(BuildContext context) => Center(
        child: Text(userName),
      );
}
