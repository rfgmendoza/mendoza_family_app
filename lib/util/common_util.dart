import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String name;
  const User(this.id, this.name);
}

class FamilyPerson {
  final String id, name, spouse;
  final bool deceased, spouseDeceased;

  FamilyPerson(
      {required this.id,
      required this.name,
      required this.spouse,
      required this.deceased,
      required this.spouseDeceased});

  factory FamilyPerson.fromJson(Map<String, dynamic> json) {
    return FamilyPerson(
        id: json["id"],
        name: json["name"],
        spouse: json["spouse"],
        deceased: json["deceased"],
        spouseDeceased: json["spouseDeceased"]);
  }
}

Future<User?> getCachedUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? username = prefs.getString('userName');
  String? userid = prefs.getString('userId');
  if (userid != null && username != null) {
    return User(userid, username);
  } else {
    return null;
  }
}

// Future<List<FamilyPerson>> generateFamilyList(List<dynamic> items) async {
  // SharedPreferences _savedata = await SharedPreferences.getInstance();
//   List<FamilyPerson> outfamily;

//   return [];
// }
