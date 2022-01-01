import 'package:flutter/material.dart';

import 'common_util.dart';

Widget personTile(FamilyPerson person) {
  return ListTile(
      title: Text(person.name),
      subtitle: Text(person.spouse),
      leading: Text(person.id));
}
