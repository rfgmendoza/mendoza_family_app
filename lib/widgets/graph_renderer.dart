import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:mendoza_family_app/util/common_util.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors, Matrix4;

class GraphRenderer extends StatefulWidget {
  final FamilyPerson user;
  const GraphRenderer({Key? key, required this.user}) : super(key: key);

  @override
  _GraphRendererState createState() => _GraphRendererState();
}

class _GraphRendererState extends State<GraphRenderer> {
  final Graph graph = Graph()..isTree = true;
  int _orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
  Map<String, FamilyPerson> graphDataMemo = <String, FamilyPerson>{};

  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  final TransformationController _controller = TransformationController();

  @override
  Widget build(BuildContext context) {
    builder
      ..siblingSeparation = (10)
      ..levelSeparation = (10)
      ..subtreeSeparation = (10)
      ..orientation = (_orientation);

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        FutureBuilder(
            future: generateFamilyTreeData(graph, widget.user, graphDataMemo),
            builder:
                (context, AsyncSnapshot<Map<String, FamilyPerson>> snapshot) {
              if (snapshot.connectionState != ConnectionState.done ||
                  !snapshot.hasData) {
                return const Expanded(
                    child: Center(child: CircularProgressIndicator()));
              } else {
                if (snapshot.hasError) {
                  return Expanded(child: Text('Error: ${snapshot.error}'));
                } else {
                  graphDataMemo = snapshot.data!;
                  return renderGraph(snapshot);
                }
              }
            }),
        Row(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: () {
                      Node node = graph.getNodeUsingId(widget.user.id);
                      // final position = Offset(-(node.x), -(node.y));
                      Matrix4 newValue = _controller.value.clone()
                        ..setTranslationRaw(node.x, node.y, 0.0)
                        ..setDiagonal(Vector4(1.0, 1.0, 1.0, 1.0));
                      setState(() {
                        _controller.value = newValue;
                      });
                    },
                    child: const Text("Center on user")),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _controller.value = Matrix4.identity();
                      });
                    },
                    child: const Text("Reset")),
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
            ),
          ],
        )
      ],
    );
  }

  Widget nodeContents(FamilyPerson a) {
    bool isUser = a.id == widget.user.id;

    return SizedBox(
      width: _orientation == BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT
          ? 300
          : 200,
      child: Card(
          color: !isUser ? Colors.white54 : Colors.blueAccent,
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

  Widget renderGraph(AsyncSnapshot<Map<String, FamilyPerson>> snapshot) {
    return Expanded(
      child: InteractiveViewer(
          minScale: 0.1,
          maxScale: 2,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          transformationController: _controller,
          child: OverflowBox(
              alignment: Alignment.center,
              minWidth: 0.0,
              minHeight: 0.0,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: renderInnerGraph(snapshot))),
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
}
