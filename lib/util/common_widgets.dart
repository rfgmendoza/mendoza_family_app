import 'package:flutter/material.dart';

import 'common_util.dart';

Widget personTile(FamilyPerson person, {Widget? trailing}) {
  return ListTile(
      title: Text(
        person.name.toUpperCase(),
        textAlign: TextAlign.start,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          person.spouse,
          textAlign: TextAlign.end,
        ),
      ),
      leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[Text(person.id)]),
      trailing: trailing);
}
