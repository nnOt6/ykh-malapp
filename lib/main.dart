import 'package:flutter/material.dart';
import 'package:sth_malapp2/page/home.dart';

void main() {
  runApp(MaterialApp(
    title: "My Title",
    home: Scaffold(
      appBar: AppBar(
        title: const Text("MalApp"),
        backgroundColor: Colors.green,
      ),
      body: const Home(),
    ),
  ));
}

