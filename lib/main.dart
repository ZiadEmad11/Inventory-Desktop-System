import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'home.dart';
import 'login.dart';

void main() async  {
  sqfliteFfiInit(); // Initialize FFI
  databaseFactory = databaseFactoryFfi; // Set the database factory to use FF
  try {
    runApp(MyApp());
  } catch (e, stackTrace) {
    final logFile = File('error_log.txt');
    await logFile.writeAsString('Error: $e\nStack Trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharoan Alur',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Login(),
    );
  }
}
