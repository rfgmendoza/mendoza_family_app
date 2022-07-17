import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:mendoza_family_app/util/common_util.dart';
import 'package:mendoza_family_app/util/translation.dart';
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
  Translation trans = Translation();

  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  final TransformationController _controller = TransformationController();
  bool _firstRender = true;
  bool _smallNodes = false;
  final double _nodeWidth = 200.0;

  @override
  void initState() {
    super.initState();
    _orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
    _firstRender = true;
    _smallNodes = !(widget.targetUser != null);
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
        title: Text(trans.getString('family_tree')),
        actions: buttonRow(),
      ),
      bottomNavigationBar: widget.targetUser != null
          ? Container(
              height: 20,
              color: Theme.of(context).primaryColor,
              child: Center(
                child: Text(getRelationshipDescription(
                    widget.user.id, widget.targetUser!.id)),
              ),
            )
          : null,
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
                  return loadingLogo();
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

                    return _firstRender ? loadingLogo() : renderGraph(snapshot);
                  }
                }
              }),
        ],
      ),
    );
  }

  Widget loadingLogo() {
    return Expanded(
        child: Center(
            child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text('Loading...'),
        Image(image: AssetImage('assets/MendozaLogo.png')),
      ],
    )));
  }

  Matrix4 resetView() {
    return focusView(graph.getNodeAtPosition(0).key!.value.toString());
  }

  Matrix4 resetViewToUser() {
    return focusView(
        graph.getNodeUsingId(widget.user.id).key!.value.toString());
  }

  Matrix4 focusView(String id) {
    final startNode = graph.nodes.firstWhere(
      (node) => node.key!.value == id,
    );
    double scale = 1.0;
    Vector3 scalev = Vector3(scale, scale, scale);
    Vector3 transV = Vector3(
        -(startNode.x -
            startNode.width +
            _nodeWidth /
                (_orientation ==
                        BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT
                    ? 4
                    : 4)),
        -(startNode.y -
            (startNode.height) *
                (_orientation ==
                        BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT
                    ? 2
                    : id.length)),
        0.0);
    // Vector3 transV = Vector3(-(startNode.x - startNode.width + _nodeWidth / 2),
    //     -(startNode.y - (startNode.height) * id.length), 0.0);
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
          _firstRender = true;
        });
        break;
      case "reset_view":
        setState(() {
          _controller.value = resetViewToUser();
        });
        break;
      default:
        return;
    }
  }

  List<Widget> buttonRow() {
    return [
      IconButton(
          onPressed: () {
            setState(() {
              _controller.value = resetViewToUser();
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
          PopupMenuItem(
            value: "orient_horizontal",
            child: ListTile(
              leading: const Icon(Icons.text_rotation_none),
              title: Text(trans.getString("horizontal")),
            ),
          ),
          PopupMenuItem(
            value: "orient_vertical",
            child: ListTile(
              leading: const Icon(Icons.text_rotate_vertical),
              title: Text(trans.getString("vertical")),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
              value: "small_nodes",
              child: _smallNodes
                  ? Text(trans.getString('toggle_node_sizeA'))
                  : Text(trans.getString('toggle_node_sizeB'))),
          // PopupMenuItem(
          //     value: "reset_view", child: Text(trans.getString('reset_view'))),
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
    bool isDeceased = a.deceased;
    return Container(
      decoration: const BoxDecoration(
          // color: Colors.greenAccent,
          borderRadius: BorderRadius.all(Radius.circular(20))),
      width: isSmall ? _nodeWidth / 2 : _nodeWidth,
      child: Card(
          color: calcNodeColor(isUser, isTarget, isDeceased),
          child: ListTile(
              onTap: () {
                if (!isUser) setCachedUser(a, target: true);
                Navigator.of(context).pushReplacementNamed("home");
              },
              title: isSmall ? Text(idCreator(a)) : largeTitle(a),
              subtitle: isSmall
                  ? null
                  : Text(
                      a.spouse,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ))),
    );
  }

  String idCreator(FamilyPerson a) {
    return (a.deceased ? "† " : "") + a.id;
  }

  Widget largeTitle(FamilyPerson a) {
    return Text.rich(TextSpan(
        // style: const TextStyle(
        //     fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
        children: [
          TextSpan(
              text: idCreator(a) + "\n",
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
