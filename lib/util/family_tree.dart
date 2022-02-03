import 'dart:collection';

import 'package:graphview/GraphView.dart';

import 'common_util.dart';

class FamilyTree {
  static final FamilyTree _instance = FamilyTree._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  List<dynamic>? familyJson;
  Map<int, Map<String, FamilyPerson>> nodeMap = {};

  Map<int, List<Edge>> graphEdgesMap = {};

  FamilyTree._();

  factory FamilyTree() {
    return _instance;
  }

  Future initFamily() async {
    if (!_isInitialized) {
      familyJson = await readFamilyJson();
      _isInitialized = true;
    }
  }

  bool hasFamilyGraphData(int familyGroup) {
    return _isInitialized &&
        nodeMap.containsKey(familyGroup) &&
        graphEdgesMap.containsKey(familyGroup);
  }

  Future buildAllFamilyGraphData() async {
    if (!_isInitialized) {
      await initFamily();
    }
    List.generate(7, (index) => index).forEach((element) {
      print(element.toString() + 'begin');
      buildFamilyGraph(element);
    });
  }

  Future buildFamilyGraph(int familyId) async {
    if (!_isInitialized) {
      await initFamily();
    }
    if (!hasFamilyGraphData(familyId)) {
      Map<String, FamilyPerson> nodes = {};
      List<Edge> edges = [];
      Queue itemQueue = Queue.from([familyJson![familyId]]);
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
          edges.add(Edge(node, cNode));
        }
      }
      graphEdgesMap[familyId] = edges;
      nodeMap[familyId] = nodes;
    }
    // ignore: avoid_print

    print(familyId.toString() + 'done');
  }
}
