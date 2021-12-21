import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mendoza_family_app/util/common_util.dart';

class SearchPage extends StatefulWidget {
  SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  Future<List<Node>> buildTree() async {
    List<dynamic> items = await readFamilyJson();
    Queue itemQueue = Queue.from(items);
    List<Node> nodes = [];
    while (itemQueue.isNotEmpty) {
      var rawData = itemQueue.removeFirst();
      // TODO: figure out how to add and work with nodes
      // Node.id(rawData["id"])
      // create child nodes, add children as edges on graph
      if (rawData["children"] != null && rawData["children"] != []) {
        itemQueue.addAll(rawData["children"]);
      }
    }
  }

  @override
  Future<void> initState() async {}

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
        child: GraphView(
            graph: graph,
            algorithm:
                BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
            builder: (Node node) {
              var a = node.key.value as int;
              return rectangleWidget(a);
            }));
  }

  Widget rectangleWidget(int a) {
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
          child: Text('Node ${a}')),
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
