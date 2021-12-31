import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:mendoza_family_app/util/common_util.dart';
import 'package:mendoza_family_app/widgets/graph_renderer.dart';

class SearchPage extends StatefulWidget {
  final User user;
  const SearchPage({Key? key, required this.user}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  int _orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
  bool graphMode = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        persistentFooterButtons: graphMode
            ? [
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
              ]
            : null,
        body: graphMode
            ? GraphRenderer(orientation: _orientation, user: widget.user)
            : Container());
  }
}
