import 'package:flutter/material.dart';

import 'pages/auth_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lang Words',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0x009688),
        errorColor: const Color(0xe54b40),
        backgroundColor: const Color(0x090e11),
        
      ),
      home: AuthPage(),
    );
  }
}
