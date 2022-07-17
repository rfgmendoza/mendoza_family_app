import 'package:flutter/material.dart';

import 'common_util.dart';

Widget personTile(FamilyPerson person, {Widget? trailing}) {
  return ListTile(
      dense: true,
      title: Text(
        person.name.toUpperCase(),
        textAlign: TextAlign.start,
        style: TextStyle(
            fontWeight: person.deceased ? FontWeight.bold : FontWeight.normal),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          (person.spouseDeceased ? "† " : "") + person.spouse,
          textAlign: TextAlign.end,
        ),
      ),
      leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text((person.deceased ? "† " : "") + person.id,
                style: TextStyle(
                    fontWeight:
                        person.deceased ? FontWeight.bold : FontWeight.normal))
          ]),
      trailing: trailing);
}
