import 'package:graphview/GraphView.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:collection';
import 'package:flutter/services.dart';
import 'dart:convert';

class User {
  final String id;
  final String name;
  const User(this.id, this.name);
}

class FamilyTreeData {
  final Map<String, FamilyPerson> familyMap;
  final Graph graph;
  const FamilyTreeData(this.familyMap, this.graph);
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

Future<List<dynamic>> readFamilyJson() async {
  final String response = await rootBundle.loadString('data/family_book.json');
  final data = await json.decode(response);
  return data["families"];
}

Future<bool> setCachedUser(FamilyPerson person) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool success = true;
  success = success && await prefs.setString('userName', person.name);
  success = success && await prefs.setString('userId', person.id);
  return success;
}

Future<bool> clearCachedUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool success = true;
  success = success && await prefs.remove('userName');
  success = success && await prefs.remove('userId');
  return success;
}

List<FamilyPerson> search(String searchText, List items) {
  if (searchText.isEmpty) {
    return [];
  }
  Queue searchNodes = Queue.from(items);
  List<FamilyPerson> foundPeople = [];
  List<String> searchFields = ["id", "name", "spouse"];
  while (searchNodes.isNotEmpty) {
    var node = searchNodes.removeFirst();
    bool found = false;
    for (var field in searchFields) {
      if (node[field]
          .toString()
          .toUpperCase()
          .contains(searchText.toUpperCase())) {
        found = true;
      }
    }
    if (found) {
      foundPeople.add(FamilyPerson.fromJson(node));
    }
    if (node["children"] != null && node["children"] != []) {
      searchNodes.addAll(node["children"]);
    }
  }
  return foundPeople;
}

Future<Map<String, FamilyPerson>> generateFamilyTreeData(
    Graph graph, User user) async {
  List<dynamic> items = await readFamilyJson();
  int familyGroup = int.parse(user.id[0]) - 1;
  List<dynamic> templist = [items[familyGroup]];
  Queue itemQueue = Queue.from(templist);
  // Queue itemQueue = Queue.from(items);
  Map<String, FamilyPerson> nodes = {};
  while (itemQueue.isNotEmpty) {
    var rawData = itemQueue.removeFirst();
    String id = rawData["id"];
    Node node = Node.Id(id);
    nodes.putIfAbsent(id, () => FamilyPerson.fromJson(rawData));
    List<dynamic> children = rawData["children"] ?? [];
    int noIdChildCount = 0;
    for (var element in children) {
      String cId = element["id"];
      if (cId == "") {
        cId = id + String.fromCharCode(noIdChildCount + 65);
        noIdChildCount++;
        element["id"] = cId;
      }
      Node cNode = Node.Id(cId);
      nodes.putIfAbsent(id, () => FamilyPerson.fromJson(rawData));
      itemQueue.add(element);
      graph.addEdge(node, cNode);
    }
  }
  return nodes;
}
