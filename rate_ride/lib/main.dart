import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'pages/registerPage.dart';
import 'pages/loginPage.dart';
import 'pages/tripHistory.dart';
import 'pages/homePage.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "TripDatabase.db";
  static const _databaseVersion = 1;

  // Trip table
  static const tableTrips = 'trips';

  // User table
  static const tableUsers = 'users';

  static const columnId = '_id';
  static const columnEmail = 'email';
  static const columnHashedPassword = 'hashedPassword';
  static const columnSafetyScore = 'safetyScore';
  static const columnSpeed = 'speed';
  static const columnAvgSpeed = 'avgSpeed';
  static const columnDistance = 'distance';
  static const columnMaxGs = 'maxGs';
  static const columnMinGs = 'minGs';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

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
    await db.execute('''
      CREATE TABLE $tableUsers (
        $columnId INTEGER PRIMARY KEY,
        $columnEmail TEXT,
        $columnHashedPassword TEXT
      )
    ''');
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<int> registerUser(String email, String password) async {
    Database db = await instance.database;
    String hashedPassword = hashPassword(password);
    return await db.insert(
        tableUsers, {columnEmail: email, columnHashedPassword: hashedPassword});
  }

  Future<bool> verifyUser(String email, String password) async {
    Database db = await instance.database;
    String hashedPassword = hashPassword(password);
    List<Map> res = await db.rawQuery(
        'SELECT * FROM $tableUsers WHERE $columnEmail = ? AND $columnHashedPassword = ?',
        [email, hashedPassword]);
    return res.isNotEmpty;
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableTrips, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(tableTrips);
  }

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
        '/': (context) => const MyHomePage(title: 'Safety Score Tracker'),
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/tripHistory': (context) => TripHistoryPage(),
      },
    );
  }
}
