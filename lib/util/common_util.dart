import 'package:flutter/material.dart';
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'deceased': deceased,
        'spouse': spouse,
        'spouseDeceased': spouseDeceased,
      };
}

Future<FamilyPerson?> getCachedUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? user = prefs.getString('user');
  if (user != null) {
    return FamilyPerson.fromJson(json.decode(user));
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
  success = await prefs.setString("user", jsonEncode(person));

  return success;
}

Future<bool> clearCachedUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool success = true;
  success = success && await prefs.remove('user');
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
    Graph graph, FamilyPerson user, Map<String, FamilyPerson> memoData) async {
  if (memoData.isNotEmpty) {
    return memoData;
  }
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
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("nodeMap", nodes.toString());
  return nodes;
}

String getRelationshipDescription(
    FamilyPerson user, FamilyPerson targetPerson) {
  List<String> userId = user.id.split("");
  List<String> targetId = targetPerson.id.split("");
  int generationDiff = userId.length - targetId.length;

  int i = 0;
  List<int> outList = [];
  while (i < userId.length && i < targetId.length) {
    outList.add(userId[i].compareTo(targetId[i]));
    i++;
  }
  if (generationDiff <= 0) {
    //cousins / siblings / children / niece / nephew
    if (generationDiff == 0) {}
  } else if (generationDiff >= 0) {
    if (outList.every((element) => element == 0)) {
      if (generationDiff == 1) {
        return "Parent";
      } else if (generationDiff == 2) {
        return "GrandParent";
      } else {
        generationDiff = generationDiff - 2;
      }
    }
  } //parents / aunts & uncles / grandparents

  return "unknown";
}
