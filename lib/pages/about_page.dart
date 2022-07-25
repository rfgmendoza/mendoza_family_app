import 'package:flutter/material.dart';
import 'package:mendoza_family_app/util/translation.dart';
import 'package:contactus/contactus.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translation().getString("mendoza_family_book")),
      ),
      body: Center(
        child: ContactUs(
            cardColor: Colors.blueGrey,
            taglineColor: Colors.black,
            textColor: Colors.black,
            companyColor: Colors.lightBlue,
            emailText: "rfgmendoza@gmail.com",
            email: "rfgmendoza@gmail.com",
            githubUserName: "rfgmendoza",
            companyName: "Rafael Mendoza",
            tagLine: "31461"),
      ),
    );
  }
}
