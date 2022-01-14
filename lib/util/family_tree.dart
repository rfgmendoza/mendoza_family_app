import 'package:graphview/GraphView.dart';

import 'common_util.dart';

class FamilyTree {
  static final FamilyTree _instance = FamilyTree._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  List<dynamic>? familyJson;
  Map<int, Map<String, FamilyPerson>> nodeMap = {};

  Map<int, List<Edge>> graphEdgesMap = {};
  Map<int, List<Node>> graphNodesMap = {};

  FamilyTree._();

  factory FamilyTree() {
    return _instance;
  }

  void initFamily() async {
    familyJson = await readFamilyJson();
    _isInitialized = true;
  }

  bool hasFamilyGraphData(int familyGroup) {
    return _isInitialized &&
        nodeMap.containsKey(familyGroup) &&
        graphEdgesMap.containsKey(familyGroup) &&
        graphNodesMap.containsKey(familyGroup);
  }
}
