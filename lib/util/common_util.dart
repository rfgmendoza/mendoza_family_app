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

  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<dynamic> items = await readFamilyJson();
  int familyGroup = int.parse(user.id[0]) - 1;
  List<dynamic> templist = [items[familyGroup]];
  Queue itemQueue = Queue.from(templist);
  // Queue itemQueue = Queue.from(items);
  Map<String, FamilyPerson> nodes = await fetchNodeMap(prefs, familyGroup);
  if (nodes.isNotEmpty) {
    Map<String, List<Object>> graphCache = await fetchGraph(prefs, familyGroup);
    graph.addNodes(graphCache["nodes"] as List<Node>);
    graph.addEdges(graphCache["edges"] as List<Edge>);
    //TODO read graph data
    // decode
    // add to graph
    // return nodes;
  }
  while (itemQueue.isNotEmpty) {
    // TODO: do not parse if cache values exist
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

  prefs.setString("nodeMap" + familyGroup.toString(), json.encode(nodes));
  prefs.setString("graphCache" + familyGroup.toString(), graph.toJson());

  // TODO: store graph nodes
  // TODO: store graph edge
  // TODO: store entire graph object instead?
  // await prefs.setString("graphEdges", json.encode(graph.));
  // graph.toJson()

  return nodes;
}

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
