import 'package:flutter/material.dart';
import 'package:mendoza_family_app/util/common_util.dart';
import 'package:mendoza_family_app/util/common_widgets.dart';
import 'package:mendoza_family_app/util/translation.dart';
import 'package:scan/scan.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  TextEditingController controller = TextEditingController();
  bool _qrMode = false;
  ScanController scanController = ScanController();
  final Translation _trans = Translation();

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

  Future confirmAlert(FamilyPerson person) async {
    Widget cancelButton = TextButton(
        onPressed: () {
          FocusScopeNode currentFocus = FocusScope.of(context);

          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
          if (_qrMode) {
            Navigator.of(context)
              ..pop()
              ..pop(false);
          } else {
            Navigator.pop(context, false);
          }
        },
        child: Text(_trans.getString("cancel")));
    Widget confirmButton = TextButton(
        onPressed: () async {
          Navigator.pop(context, true);
        },
        child: Text(_trans.getString("confirm")));

    AlertDialog alert = AlertDialog(
        title: Text(_trans.getString("confirm_selection")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_trans.getString("you_sure")),
            const Divider(),
            personTile(person)
          ],
        ),
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(_trans.getString("filter_by_group")),
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
                    child: ListTile(
                        trailing: ElevatedButton(
                          child: Text(_trans.getString("select")),
                          onPressed: () async {
                            final result = await confirmAlert(_searchResult[i]);
                            if (result) {
                              Navigator.pop(context, _searchResult[i]);
                            }
                          },
                        ),
                        leading: Text((_searchResult[i].deceased ? "† " : "") +
                            _searchResult[i].id),
                        title: Text(
                          _searchResult[i].name,
                        ),
                        subtitle: Text(
                            (_searchResult[i].spouseDeceased ? "† " : "") +
                                _searchResult[i].spouse)),
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

  Future<void> submitSearch(String searchText, List<bool> filterGroup) async {
    List<bool> fg = _qrMode ? List.generate(7, (index) => false) : filterGroup;
    List<dynamic> filteredItems =
        getFilterGroupInt(fg) != -1 ? [_items[getFilterGroupInt(fg)]] : _items;
    if (_qrMode) {
      FamilyPerson? person = searchExactId(searchText, filteredItems);
      if (person != null) {
        final result = await confirmAlert(person);
        if (result) {
          Navigator.pop(context, person);
        }
      }
    }
    // fall through to return search results
    List<FamilyPerson> searchResults = search(searchText, filteredItems);
    setState(() {
      _filterGroup = fg;
      _searchResult = searchResults;
      _qrMode = false;
    });
  }

  void _getQrCode(String qrcode) {
    controller.text = qrcode;

    List<bool> filterGroup = List.generate(7, (index) => false);
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
      floatingActionButton: !kIsWeb && widget.familyGroup != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _qrMode = !_qrMode;
                });
              },
              child: _qrMode
                  ? const Icon(Icons.cancel_sharp)
                  : const Icon(Icons.qr_code_scanner))
          : null,
      appBar: AppBar(
        title: Text(_trans.getString("people_picker_title")),
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
            _getQrCode(data);
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
            Text(
              _trans.getString("people_picker_instruction"),
              style: const TextStyle(fontWeight: FontWeight.bold),
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
