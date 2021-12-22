import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:mendoza_family_app/util/common_util.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  Future<Map<String, FamilyPerson>> _buildTree() async {
    List<dynamic> items = await readFamilyJson();
    Queue itemQueue = Queue.from(items[6]["children"][4]["children"]);
    Map<String, FamilyPerson> nodes = {};
    while (itemQueue.isNotEmpty) {
      var rawData = itemQueue.removeFirst();
      String id = rawData["id"];
      Node node = Node.Id(id);
      nodes.putIfAbsent(id, () => FamilyPerson.fromJson(rawData));
      List<dynamic> children = rawData["children"] ?? [];
      itemQueue.addAll(children);
      for (var element in children) {
        Node cNode = Node.Id(element["id"]);
        nodes.putIfAbsent(id, () => FamilyPerson.fromJson(rawData));
        graph.addEdge(node, cNode);
      }
    }
    return nodes;
  }

  @override
  void initState() {
    super.initState();
    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
          future: _buildTree(),
          builder:
              (context, AsyncSnapshot<Map<String, FamilyPerson>> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return const CircularProgressIndicator();
              default:
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return renderGraph(snapshot);
                }
            }
          }),
    );
  }

  Widget renderGraph(AsyncSnapshot<Map<String, FamilyPerson>> snapshot) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: InteractiveViewer(
              constrained: false,
              scaleEnabled: true,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.01,
              maxScale: 5.6,
              child: renderInnerGraph(snapshot)),
        ),
      ],
    );
  }

  GraphView renderInnerGraph(
      AsyncSnapshot<Map<String, FamilyPerson>> snapshot) {
    return GraphView(
      graph: graph,
      algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
      paint: Paint()
        ..color = Colors.green
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
      builder: (Node node) {
        FamilyPerson? a = snapshot.data![node.key?.value];
        return rectangleWidget(a);
      },
    );
  }

  Widget rectangleWidget(FamilyPerson? a) {
    var name = a != null ? a.name : "?";
    return InkWell(
      onTap: () {
        print('clicked');
      },
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Colors.blue, spreadRadius: 1),
            ],
          ),
          child: Text(name)),
    );
  }
}

// void _searchMode() {
//     setState(() {
//       if (customIcon.icon == Icons.search) {
//         customIcon = const Icon(Icons.cancel);
//         customSearchBar = const ListTile(
//           leading: Icon(
//             Icons.search,
//             color: Colors.white,
//             size: 28,
//           ),
//           title: TextField(
//             textInputAction: TextInputAction.search,
//             add submit
//             decoration: InputDecoration(
//               hintText: 'Enter a Name...',
//               hintStyle: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontStyle: FontStyle.italic,
//               ),
//               border: InputBorder.none,
//             ),
//             style: TextStyle(
//               color: Colors.white,
//             ),
//           ),
//         );
//       } else {
//         customIcon = const Icon(Icons.search);
//         customSearchBar = const Text('Mendoza Family Book');
//       }
//     });
//   }
