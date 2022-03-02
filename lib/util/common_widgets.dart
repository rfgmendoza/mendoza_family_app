import 'package:flutter/material.dart';

import 'common_util.dart';

Widget personTile(FamilyPerson person, {Widget? trailing}) {
  // return Padding(
  //   padding: const EdgeInsets.all(8.0),
  //   child: Column(
  //     children: [
  //       Text(
  //         person.name.toUpperCase(),
  //         textAlign: TextAlign.start,
  //       ),
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //         child: Text(
  //           person.spouse,
  //           textAlign: TextAlign.end,
  //         ),
  //       ),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [Text(person.id), trailing ?? Container()],
  //       )
  //     ],
  //   ),
  // );
  return ListTile(
      dense: true,
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
