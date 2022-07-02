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
  bool _firstRender = true;
  bool _smallNodes = false;
  final double _nodeWidth = 200.0;

  @override
  void initState() {
    super.initState();
    _orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
    _firstRender = true;
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
        title: const Text("Family Tree"),
        actions: buttonRow(),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          FutureBuilder(
              future: generateFamilyTreeData(graph, widget.user,
                  targetUser: widget.targetUser),
              builder:
                  (context, AsyncSnapshot<Map<String, FamilyPerson>> snapshot) {
                if (snapshot.connectionState != ConnectionState.done ||
                    !snapshot.hasData) {
                  return Expanded(
                      child: Center(
                          child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Loading...'),
                      Image(image: AssetImage('assets/MendozaLogo.png')),
                    ],
                  )));
                } else {
                  if (snapshot.hasError) {
                    return Expanded(child: Text('Error: ${snapshot.error}'));
                  } else {
                    graphDataMemo = snapshot.data!;
                    Future.delayed(
                        Duration.zero,
                        () => {
                              if (_firstRender)
                                {
                                  setState(() {
                                    _firstRender = false;
                                    _controller.value = resetViewToUser();
                                  })
                                }
                            });
                    return renderGraph(snapshot);
                  }
                }
              }),
        ],
      ),
    );
  }

  Matrix4 resetView() {
    return focusView(graph.getNodeAtPosition(0).key!.value.toString());
  }

  Matrix4 resetViewToUser() {
    // TODO: check for user existance
    return focusView(
        graph.getNodeUsingId(widget.user.id).key!.value.toString());
  }

  Matrix4 focusView(String id) {
    final startNode = graph.nodes.firstWhere(
      (node) => node.key!.value == id,
    );
    double scale = 1.0;
    Vector3 scalev = Vector3(scale, scale, scale);
    Vector3 transV = Vector3(-(startNode.x - startNode.width + _nodeWidth / 2),
        -(startNode.y - (startNode.height) * id.length), 0.0);
    return _controller.value.clone()
      ..setFromTranslationRotationScale(transV, Quaternion.identity(), scalev);
  }

  void handleMenuSelect(Object? value) {
    switch (value) {
      case "orient_vertical":
        setState(
          () {
            _orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
            _firstRender = true;
          },
        );
        break;
      case "orient_horizontal":
        setState(() {
          _orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
          _firstRender = true;
        });
        break;
      case "setting_full_tree":
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => GraphRenderer(user: widget.user)));
        break;
      case "small_nodes":
        setState(() {
          _smallNodes = !_smallNodes;
        });
        break;
      case "reset_view":
        setState(() {
          _controller.value = resetViewToUser();
        });
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
              _controller.value = resetView();
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
              icon: const Icon(Icons.person_off))
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
          const PopupMenuItem(
              value: "small_nodes", child: Text('Toggle Node Size')),
          const PopupMenuItem(value: "reset_view", child: Text('Reset View')),
        ],
      ),
    ];
  }

  bool isSmallNode(FamilyPerson a) {
    bool isUser = a.id == widget.user.id;
    bool isTarget = a.id == widget.targetUser?.id;
    return !(isUser || isTarget) && _smallNodes;
  }

  Widget nodeContents(FamilyPerson a) {
    bool isUser = a.id == widget.user.id;
    bool isTarget = a.id == widget.targetUser?.id;
    bool isSmall = isSmallNode(a);
    return Container(
      decoration: const BoxDecoration(
          // color: Colors.greenAccent,
          borderRadius: BorderRadius.all(Radius.circular(20))),
      width: isSmall ? _nodeWidth / 2 : _nodeWidth,
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
                        builder: (context) => GraphRenderer(
                            user: widget.user,
                            targetUser: isTarget ? null : a)));
              },
              title: isSmall ? Text(a.id) : largeTitle(a),
              subtitle: isSmall
                  ? null
                  : Text(
                      a.spouse,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ))),
    );
  }

  Widget largeTitle(FamilyPerson a) {
    return Text.rich(TextSpan(
        // style: const TextStyle(
        //     fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
        children: [
          TextSpan(
              text: a.id + "\n",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: a.name.toUpperCase())
        ]));
  }

  // Widget smallTitle(FamilyPerson b) {}

  // Widget nodeContentsBeta(FamilyPerson a) {}

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
          constrained: false,
          minScale: 0.01,
          maxScale: 2,
          boundaryMargin: const EdgeInsets.all(200),
          transformationController: _controller,
          child: renderInnerGraph(snapshot)),
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
