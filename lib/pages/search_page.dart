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

  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  @override
  Widget build(BuildContext context) {
    builder
      ..siblingSeparation = (10)
      ..levelSeparation = (10)
      ..subtreeSeparation = (10)
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
            child: const Text("Horizontal")),
        ElevatedButton(
            onPressed: () {
              setState(() {
                _orientation =
                    BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
              });
            },
            child: const Text("Vertical"))
      ],
      body: FutureBuilder(
          future: generateFamilyTreeData(graph),
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
              minScale: 0.4,
              maxScale: 2,
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

  // Widget nodeContents(FamilyPerson a) {
  //   return a != null
  //       ? SizedBox(
  //           width: 300,
  //           child: Column(
  //             children: [
  //               Text(a.id),
  //               Text(
  //                 a.name,
  //                 maxLines: 2,
  //                 softWrap: true,
  //                 textAlign: TextAlign.start,
  //               ),
  //               if (a.spouse != "")
  //                 Text(
  //                   a.spouse,
  //                   textAlign: TextAlign.start,
  //                 ),
  //             ],
  //           ),
  //         )
  //       : const Text("?");
  // }

  Widget nodeContents(FamilyPerson a) {
    return SizedBox(
      width: _orientation == BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT
          ? 300
          : 200,
      child: Card(
          color: Colors.white54,
          child: ListTile(
              leading: Text(a.id),
              title: Text(
                a.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                a.spouse,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ))),
    );
  }

  Widget rectangleWidget(FamilyPerson? a) {
    return InkWell(
      onTap: () {
        print('clicked');
      },
      child: Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: a != null ? nodeContents(a) : const Text("?")),
    );
  }
}
