import 'package:graphview/GraphView.dart';
import 'package:mendoza_family_app/util/family_tree.dart';
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

enum FilterMode {
  standard,
  target,
  immediate,
  extended,
}

enum DisplayMode {
  standard,
  relation,
  compact,
}

class FilterSettings {
  final FamilyPerson? target;
  final FilterMode filterMode;
  const FilterSettings(this.filterMode, this.target);
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

Future<Map<String, FamilyPerson>> getCachedUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? user = prefs.getString('user');
  String? target = prefs.getString('target');
  Map<String, FamilyPerson> outMap = {};
  if (user != null) {
    outMap["user"] = FamilyPerson.fromJson(json.decode(user));
  }
  if (target != null) {
    outMap["target"] = FamilyPerson.fromJson(json.decode(target));
  }
  return outMap;
}

Future<List<dynamic>> readFamilyJson() async {
  final String response = await rootBundle.loadString('data/family_book.json');
  final data = await json.decode(response);
  return data["families"];
}

Future<bool> setCachedUser(FamilyPerson person, {bool target = false}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool success = true;
  success =
      await prefs.setString(target ? "target" : "user", jsonEncode(person));

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

bool isAncestorEdge(Edge edge, String id) {
  bool out = false;
  if (edge.destination.key?.value.contains(id) ||
      id.contains(edge.destination.key?.value)) {
    out = true;
  }
  // if (edge.source.key?.value.contains(id) ||
  //     id.contains(edge.source.key?.value)) {
  //   out = true;
  // }
  return out;
}

List<Edge> filterGraph(
    List<Edge> edges, FamilyPerson user, FilterSettings settings) {
  List<Edge> tempEdges = edges;
  // if (settings.filterMode == FilterMode.target && settings.target != null) {
  //   tempEdges.retainWhere((element) =>
  //       isAncestorEdge(element, user.id) &&
  //       isAncestorEdge(element, settings.target!.id));
  // } else {
  //   tempEdges.retainWhere((element) => isAncestorEdge(element, user.id));
  // }

  return tempEdges;
}

Future<Map<String, FamilyPerson>> generateFamilyTreeData(
    Graph graph, FamilyPerson user, FilterSettings filterSettings) async {
  int familyGroup = int.parse(user.id[0]) - 1;
  Map<String, FamilyPerson> nodes = {};

  /**begin scratch */
  FamilyTree familyTree = FamilyTree();
  await familyTree.initFamily();
  await familyTree.buildAllFamilyGraphData();

  //add filter modes here
  nodes = familyTree.nodeMap[familyGroup]!;
  List<Edge> edges = [];
  edges.addAll(filterGraph(
      familyTree.graphEdgesMap[familyGroup]!, user, filterSettings));

  String targetId = filterSettings.target?.id ?? "";

  graph.addEdges(edges);

  return nodes;
}

// create function to add children?

Future<Map<String, List<Object>>> fetchGraph(
    SharedPreferences prefs, int familyGroup) async {
  var response = prefs.getString("graphCache");
  if (response != null) {
    return json.decode(response) as Map<String, List<Object>>;
  }
  return {};
}

Future<Map<String, FamilyPerson>> fetchNodeMap(
    SharedPreferences prefs, int familyGroup) async {
  var response = prefs.getString("nodeMap" + familyGroup.toString());
  if (response != null) {
    return json.decode(response, reviver: (k, v) {
      if (v is Map) {
        return FamilyPerson.fromJson(v as Map<String, dynamic>);
      }
      return v;
    });
  }
  return {};
}

String getRelationshipDescription(String user, String targetPerson) {
  List<String> userId = user.split("");
  List<String> targetId = targetPerson.split("");

  int generationDiff = userId.length - targetId.length;

  int i = 0;
  List<int> outList = [];
  String returnString = "unknown";
  if (user == targetPerson) {
    returnString = "same person";
  }
  while (i < userId.length && i < targetId.length) {
    outList.add(userId[i].compareTo(targetId[i]));
    i++;
  }

  bool targetIsShorter = generationDiff >= 0;
  int commonAncestorDepth = outList.indexWhere((element) => element != 0);
  int shorterIdLength = targetIsShorter ? targetId.length : userId.length;
  int betweenCommonAncestors =
      getDistanceToCommonAncestor(shorterIdLength, commonAncestorDepth);

/* How many people are in between that person and your common ancestor?
    If it's ZERO, they are your AUNT (or uncle, niece, nephew).
    If it's 1 OR MORE, they are your COUSIN.
          1 BETWEEN = 1ST COUSIN
          2 BETWEEN = 2ND COUSIN
          3 BETWEEN = 3RD COUSIN, etc.
    If they ARE your common ancestor, they are your GRANDPARENT. 
    */

  if (commonAncestorDepth == -1) {
    //grandparent of some sort
    //parent?
//     For GRANDPARENTS, subtract 2 for the NUMBER OF GREATS.
// 2 generations difference – 2 = 0 greats   GRANDPARENT
// 3 generations difference – 2 = 1 great   GREAT GRANDPARENT
// 4 generations difference – 2 = 2 greats   GREAT x2 GRANDPARENT
    if (generationDiff < 0) {
      returnString = prependGrandAndGreatPrefix("child", generationDiff.abs());
    } else if (generationDiff >= 1) {
      returnString = prependGrandAndGreatPrefix("parent", generationDiff.abs());
    }
  } else if (betweenCommonAncestors == 0) {
    //Uncle/Aunt/ niece/nephew
    //     For AUNTS (or uncles/nieces/nephews), this will tell you the NUMBER OF WORDS IN YOUR RELATIONSHIP.
    // 1 word = AUNT (or uncle, niece, nephew)
    // 2 words = GRAND AUNT
    // 3 words = GREAT GRAND AUNT
    // 4 words = GREAT GREAT GRAND AUNT
    // gendiff < 0 = niece/nephew
    // gendiff > 0 = aunt/uncle
    returnString =
        generationDiff.isNegative ? "Niece / Nephew" : "aunt / uncle";
    returnString =
        prependGrandAndGreatPrefix(returnString, generationDiff.abs());
  } else if (betweenCommonAncestors >= 1) {
    // cousins
    //     For COUSINS, this will tell you the NUMBER OF TIMES REMOVED.
    // 0 = No "removed"
    // 1 = 1x removed
    // 2 = 2x removed
    // 3 = 3x removed, etc.

    returnString = betweenCommonAncestors.toString() +
        ordinal(betweenCommonAncestors) +
        " Cousin ";
    switch (generationDiff.abs()) {
      case 0:
        break;
      case 1:
        returnString += "once removed";
        break;
      case 2:
        returnString += "twice removed";
        break;
      case 3:
        returnString += "thrice removed";
        break;
      default:
        const wordMap = <int, String>{
          4: "four",
          5: "five",
          6: "six",
          7: "seven",
          8: "eight",
          9: "nine",
          10: "ten",
        };
        if (generationDiff.abs() <= 10) {
          returnString += wordMap[generationDiff.abs()]! + " removed";
        }
        break;
    }
  }

  return returnString.toUpperCase();
}

String prependGrandAndGreatPrefix(String title, int generationDiff) {
  String out = "";
  while (generationDiff >= 2) {
    if (generationDiff == 2) {
      out += "Grand";
    }
    if (generationDiff > 2) {
      out += "Great ";
    }
    generationDiff--;
  }
  out = out + title;
  return out;
}

int getDistanceToCommonAncestor(int shorterIdLength, int commonAncestorDepth) {
  return shorterIdLength - 1 - commonAncestorDepth;
}

String ordinal(int number) {
  if (!(number >= 1 && number <= 100)) {
    //here you change the range
    throw Exception('Invalid number');
  }

  if (number >= 11 && number <= 13) {
    return 'th';
  }

  switch (number % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}
