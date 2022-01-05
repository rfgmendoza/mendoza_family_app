import 'package:flutter/material.dart';

import 'common_util.dart';

Widget personTile(FamilyPerson person, {Widget? trailing}) {
  return ListTile(
      title: Text(person.name),
      subtitle: Text(person.spouse),
      leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[Text(person.id)]),
      trailing: trailing);
}
