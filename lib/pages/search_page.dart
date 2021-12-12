import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);
  final String userName = "Test User";

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Go Home")),
        ],
      );
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
