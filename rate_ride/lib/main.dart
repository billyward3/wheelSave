import 'package:flutter/material.dart';
import 'pages/registerPage.dart';
import 'pages/loginPage.dart';
import 'pages/tripHistory.dart';
import 'pages/homePage.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "TripDatabase.db";
  static const _databaseVersion = 1;
  static const tableTrips = 'trips';
  static const columnId = '_id';
  static const columnSafetyScore = 'safetyScore';
  static const columnSpeed = 'speed';
  static const columnAvgSpeed = 'avgSpeed';
  static const columnDistance = 'distance';
  static const columnMaxGs = 'maxGs';
  static const columnMinGs = 'minGs';

  // singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // single database instance
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Open the database or create one if it doesn't exist
  _initDatabase() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableTrips (
            $columnId INTEGER PRIMARY KEY,
            $columnSafetyScore REAL,
            $columnSpeed REAL,
            $columnAvgSpeed REAL,
            $columnDistance REAL,
            $columnMaxGs REAL,
            $columnMinGs REAL
          )
          ''');
  }

  // Database insert operation
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableTrips, row);
  }

  // Database retrieve all operation
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(tableTrips);
  }

  // Database get number of records operation
  Future<int> queryRowCount() async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableTrips')) as int;
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(
            title:
                'Safety Score Tracker'), // Provide the required 'title' parameter
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/tripHistory': (context) => TripHistoryPage(),
      },
    );
  }
}