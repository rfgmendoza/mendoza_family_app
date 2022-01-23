import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:mendoza_family_app/util/common_util.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors, Matrix4;

class GraphRenderer extends StatefulWidget {
  final FamilyPerson user;
  final FamilyPerson? targetUser;
  const GraphRenderer({Key? key, required this.user, this.targetUser})
      : super(key: key);

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
  void initState() {
    super.initState();
    _orientation = widget.targetUser != null
        ? BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM
        : BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
  }

  @override
  Widget build(BuildContext context) {
    builder
      ..siblingSeparation = (10)
      ..levelSeparation = (10)
      ..subtreeSeparation = (10)
      ..orientation = (_orientation);

    return Scaffold(
      appBar: AppBar(
        actions: buttonRow(),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          FutureBuilder(
              future:
                  generateFamilyTreeData(graph, widget.user, widget.targetUser),
              builder:
                  (context, AsyncSnapshot<Map<String, FamilyPerson>> snapshot) {
                if (snapshot.connectionState != ConnectionState.done ||
                    !snapshot.hasData) {
                  return Expanded(
                      child: Center(
                          child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Loading...'),
                      Image(image: AssetImage('assets/MendozaLogo.png')),
                    ],
                  )));
                } else {
                  if (snapshot.hasError) {
                    return Expanded(child: Text('Error: ${snapshot.error}'));
                  } else {
                    graphDataMemo = snapshot.data!;
                    return renderGraph(snapshot);
                  }
                }
              }),
        ],
      ),
    );
  }

  void handleMenuSelect(Object? value) {
    switch (value) {
      case "orient_vertical":
        setState(() {
          _orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
        });
        break;
      case "orient_horizontal":
        setState(() {
          _orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
        });
        break;
      case "setting_full_tree":
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => GraphRenderer(user: widget.user)));
        break;
      default:
        print(value);
    }
  }

  List<Widget> buttonRow() {
    return [
      IconButton(
          onPressed: () {
            setState(() {
              _controller.value = Matrix4.identity();
            });
          },
          icon: const Icon(Icons.control_camera)),
      widget.targetUser != null
          ? IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            GraphRenderer(user: widget.user)));
              },
              icon: const Icon(Icons.zoom_out_map))
          : Container(),
      PopupMenuButton(
        onSelected: (value) => handleMenuSelect(value),
        icon: const Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) => <PopupMenuEntry>[
          const PopupMenuItem(
            value: "orient_horizontal",
            child: ListTile(
              leading: Icon(Icons.text_rotation_none),
              title: Text('Horizontal'),
            ),
          ),
          const PopupMenuItem(
            value: "orient_vertical",
            child: ListTile(
              leading: Icon(Icons.text_rotate_vertical),
              title: Text('Vertical'),
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(value: "setting_A", child: Text('setting_B')),
        ],
      ),
    ];
  }

  Widget nodeContents(FamilyPerson a) {
    bool isUser = a.id == widget.user.id;
    bool isTarget = a.id == widget.targetUser?.id;
    return SizedBox(
      width: _orientation == BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT
          ? 400
          : 250,
      child: Card(
          color: isUser
              ? Colors.blueAccent
              : isTarget
                  ? Colors.greenAccent
                  : Colors.white54,
          child: ListTile(
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            GraphRenderer(user: widget.user, targetUser: a)));
              },
              leading: Text(a.id),
              title: Text(
                a.name,
                maxLines: 3,
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
    return Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: a != null ? nodeContents(a) : const Text("?"));
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
    // TODO only show graph between two family members
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
