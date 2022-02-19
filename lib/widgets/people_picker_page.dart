import 'package:flutter/material.dart';
import 'package:mendoza_family_app/util/common_util.dart';
import 'package:scan/scan.dart';

class PeoplePickerPage extends StatefulWidget {
  final String? familyGroup;
  const PeoplePickerPage({Key? key, this.familyGroup}) : super(key: key);

  @override
  _PeoplePickerPageState createState() => _PeoplePickerPageState();
}

class _PeoplePickerPageState extends State<PeoplePickerPage> {
  List _items = [];
  List<FamilyPerson> _searchResult = [];
  List<bool> _filterGroup = [];
  String? _searchText;
  TextEditingController controller = TextEditingController();
  bool _qrMode = false;
  ScanController scanController = ScanController();

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      submitSearch(controller.text, _filterGroup);
    });
    int? fg = int.tryParse(widget.familyGroup ?? "");
    _filterGroup = List.generate(
        7, (index) => fg != null ? (index + 1 == fg ? true : false) : false);
  }

  Future<bool> confirmAlert(FamilyPerson person) async {
    Widget cancelButton = TextButton(
        onPressed: () {
          Navigator.pop(context, false);
        },
        child: const Text("Cancel"));
    Widget confirmButton = TextButton(
        onPressed: () async {
          Navigator.pop(context, true);
        },
        child: const Text("Confirm"));

    AlertDialog alert = AlertDialog(
        title: const Text("Confirm Selection"),
        content: const Text("Are you sure?"),
        actions: [cancelButton, confirmButton]);
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        });
  }

  List<Widget> _filterButtons() {
    return List<Widget>.generate(7, (index) => Text((index + 1).toString()));
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Filter by Family Group:"),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 2.0),
          child: ToggleButtons(
              children: _filterButtons(),
              isSelected: _filterGroup,
              onPressed: (int group) {
                List<bool> filter = _filterGroup;
                for (int buttonIndex = 0;
                    buttonIndex < filter.length;
                    buttonIndex++) {
                  if (buttonIndex == group) {
                    filter[buttonIndex] = !filter[buttonIndex];
                  } else {
                    filter[buttonIndex] = false;
                  }
                }
                submitSearch(controller.text, filter);
              }),
        ),
        Expanded(
          child: ListView.builder(
              itemCount: _searchResult.length,
              itemBuilder: (context, i) {
                return Card(
                  child: InkWell(
                    onTap: () async {
                      final result = await confirmAlert(_searchResult[i]);
                      if (result) {
                        Navigator.pop(context, _searchResult[i]);
                      }
                    },
                    child: ListTile(
                        trailing: ElevatedButton(
                          child: const Text("Select"),
                          onPressed: () async {
                            final result = await confirmAlert(_searchResult[i]);
                            if (result) {
                              Navigator.pop(context, _searchResult[i]);
                            }
                          },
                        ),
                        leading: Text(_searchResult[i].id),
                        title: Text(
                          _searchResult[i].name,
                        ),
                        subtitle: Text(_searchResult[i].spouse)),
                  ),
                );
              }),
        ),
      ],
    );
  }

  int getFilterGroupInt(List<bool> filterGroup) {
    return filterGroup.indexWhere((element) => element);
  }

  void submitSearch(String searchText, List<bool> filterGroup) {
    List<dynamic> filteredItems = getFilterGroupInt(filterGroup) != -1
        ? [_items[getFilterGroupInt(filterGroup)]]
        : _items;
    List<FamilyPerson> searchResults = search(searchText, filteredItems);
    setState(() {
      _searchText = searchText;
      _filterGroup = filterGroup;
      _searchResult = searchResults;
      _qrMode = false;
    });
  }

  void _getQrCode(String qrcode, List<bool> filterGroup) {
    controller.text = qrcode;
    submitSearch(qrcode, filterGroup);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      readFamilyJson().then((value) => {
            setState(() {
              _items = value;
            })
          });
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _qrMode = !_qrMode;
            });
          },
          child: _qrMode
              ? const Icon(Icons.cancel_sharp)
              : const Icon(Icons.qr_code_scanner)),
      appBar: AppBar(
        title: const Text("Find Person"),
        // actions: [IconButton(onPressed: _searchMode, icon: customIcon)],
        centerTitle: true,
      ),
      body: _qrMode ? qrCodeScanner() : searchForPerson(),
    );
  }

  Widget qrCodeScanner() {
    return Center(
      child: ScanView(
          controller: scanController,
          scanAreaScale: 0.7,
          scanLineColor: Colors.red,
          onCapture: (data) {
            _getQrCode(data, _filterGroup);
          }),
    );
  }

  Widget searchForPerson() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Enter Name or Family Id",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4.0, 0, 0, 0),
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        submitSearch(value, _filterGroup);
                      },
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    submitSearch(controller.text, _filterGroup);
                  },
                  child: const Icon(
                    Icons.search,
                    size: 40.0,
                  ),
                ),
              ],
            ),
            _searchResult.isNotEmpty
                ? Expanded(
                    child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 0),
                    child: _buildSearchResults(),
                  ))
                : Container()
          ],
        ),
      ),
    );
  }
}
