import 'dart:collection';
import 'dart:math';

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
  int _orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;

  // @override
  // void initState() {
  //   super.initState();
  //   orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
  // }

  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  Future<Map<String, FamilyPerson>> _buildTree() async {
    List<dynamic> items = await readFamilyJson();
    List<dynamic> templist = []..add(items[2]);
    Queue itemQueue = Queue.from(templist);
    // Queue itemQueue = Queue.from(items);
    Map<String, FamilyPerson> nodes = {};
    while (itemQueue.isNotEmpty) {
      var rawData = itemQueue.removeFirst();
      String id = rawData["id"];
      if (id != "") {
        Node node = Node.Id(id);
        nodes.putIfAbsent(id, () => FamilyPerson.fromJson(rawData));
        List<dynamic> children = rawData["children"] ?? [];
        itemQueue.addAll(children);
        for (var element in children) {
          String cId = element["id"];
          if (cId != "") {
            Node cNode = Node.Id(cId);
            nodes.putIfAbsent(id, () => FamilyPerson.fromJson(rawData));
            graph.addEdge(node, cNode);
          }
        }
      }
    }
    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    builder
      ..siblingSeparation = (30)
      ..levelSeparation = (15)
      ..subtreeSeparation = (15)
      ..orientation = (_orientation);
    return Scaffold(
      appBar: AppBar(),
      persistentFooterButtons: [
        ElevatedButton(
            onPressed: () {
              setState(() {
                _orientation =
                    BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
              });
            },
            child: Text("Horizontal")),
        ElevatedButton(
            onPressed: () {
              setState(() {
                _orientation =
                    BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
              });
            },
            child: Text("Vertical"))
      ],
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
              minScale: 0.1,
              maxScale: 1,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: OverflowBox(
                  alignment: Alignment.center,
                  minWidth: 0.0,
                  minHeight: 0.0,
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: renderInnerGraph(snapshot))),
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
