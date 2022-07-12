import 'package:graphview/GraphView.dart';
import 'package:mendoza_family_app/util/family_tree.dart';
import 'package:mendoza_family_app/util/translation.dart';
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

Future<bool> clearCachedUser({target = false}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool success = true;
  if (!target) {
    success = success && await prefs.remove('user');
  } else {
    success = success && await prefs.remove('target');
  }
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

bool isAncestorEdge(Edge edge, String user, String? target) {
  String edgeDest = edge.destination.key?.value;
  String edgeSource = edge.source.key?.value;

  /**
   * scratchpad:
   * 
   * edgeDest = 3a
   * edgeSource = 3
   * user = 31461
   * target = 3145
   * 
   * assumptions:
   * 3, 31, 314 should be true as all are common ancestors
   * 3146 should be included because thats the relation to user
   * 
   * 
   */
  bool isUserAncestor = user.contains(edgeDest) && user.contains(edgeSource);
  bool isTargetAncestor = target != null &&
      target.contains(edgeDest) &&
      target.contains(edgeSource);
  return isUserAncestor || isTargetAncestor;
}

filterGraph(Graph graph, List<Edge> edges, FamilyPerson user,
    {FamilyPerson? target}) {
  for (var element in edges) {
    isAncestorEdge(element, user.id, target?.id)
        ? graph.addEdgeS(element)
        : graph.removeEdge(element);
  }
}

Future<Map<String, FamilyPerson>> generateFamilyTreeData(
    Graph graph, FamilyPerson user,
    {FamilyPerson? targetUser}) async {
  int familyGroup = int.parse(user.id[0]) - 1;
  Map<String, FamilyPerson> nodes = {};

  FamilyTree familyTree = FamilyTree();
  await familyTree.initFamily();
  await familyTree.buildAllFamilyGraphData();

  //add filter modes here
  nodes = familyTree.nodeMap[familyGroup]!;
  if (targetUser != null) {
    filterGraph(graph, familyTree.graphEdgesMap[familyGroup]!, user,
        target: targetUser);
  } else {
    graph.addEdges(familyTree.graphEdgesMap[familyGroup]!);
  }
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
  final Translation _trans = Translation();

  int generationDiff = userId.length - targetId.length;

  int i = 0;
  List<int> outList = [];
  String returnString = Translation().getString("unknown");
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
      returnString = prependGrandAndGreatPrefix(
          _trans.getString("child"), generationDiff.abs());
    } else if (generationDiff >= 1) {
      returnString = prependGrandAndGreatPrefix(
          _trans.getString("parent"), generationDiff.abs());
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
    if (generationDiff == 0) {
      returnString = _trans.getString("sibling");
    } else {
      returnString = generationDiff.isNegative
          ? _trans.getString("nibling")
          : _trans.getString("titi");
    }
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
        _trans.getString("cousin");
    switch (generationDiff.abs()) {
      case 0:
        break;
      case 1:
        returnString += _trans.getString("once_removed");
        break;
      case 2:
        returnString += _trans.getString("twice_removed");
        break;
      case 3:
        returnString += _trans.getString("thrice_removed");
        break;
      default:
        var wordMap = <int, String>{
          4: _trans.getString("four"),
          5: _trans.getString("five"),
          6: _trans.getString("six"),
          7: _trans.getString("seven"),
          8: _trans.getString("eight"),
          9: _trans.getString("nine"),
          10: _trans.getString("ten"),
        };
        if (generationDiff.abs() <= 10) {
          returnString +=
              wordMap[generationDiff.abs()]! + _trans.getString("removed");
        }
        break;
    }
  }

  return returnString.toUpperCase();
}

String prependGrandAndGreatPrefix(String title, int generationDiff) {
  String out = "";

  final Translation _trans = Translation();
  if (_trans.isEnglish) {
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
  } else {
    //spanish
    String abuelo = title;
    if (generationDiff == 1) {
      return title;
    }
    int generationDiffMod = 0;
    if (title == _trans.getString("parent")) {
      abuelo = "Abuelo / Abuela";
      title = "";
    }
    if (title == _trans.getString("child")) {
      abuelo = "nieto / nieta";
      title = "";
    }
    if (title == _trans.getString("nibling")) {
      abuelo = "nieto / nieta";
    }
    if (title == _trans.getString("titi")) {
      abuelo = "Abuelo / Abuela";
      // generationDiffMod = 1;
    }
    generationDiff += generationDiffMod;
    if (generationDiff >= 2) {
      if (generationDiff == 2) {
        out = abuelo;
      }
      if (generationDiff == 3) {
        out = "bis" + abuelo;
      }
      while (generationDiff >= 4) {
        if (generationDiff == 4) {
          out = "tatara " + out + abuelo;
        }
        out = "tatara " + out;
        generationDiff--;
      }
    }
    return title + " " + out;
  }
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
  final Translation _trans = Translation();
  if (!_trans.isEnglish) {
    return "º";
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
