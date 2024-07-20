import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'my_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      "CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT, email TEXT, userType TEXT)",
    );
    await db.execute(
      "CREATE TABLE posts(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, imageName TEXT, userId INTEGER, companyName TEXT, lowestSalary REAL, highestSalary REAL, description TEXT, area TEXT, longitude REAL, latitude REAL, status TEXT, registration_no TEXT, FOREIGN KEY (userId) REFERENCES users (id))",
    );

    await db.insert(
      'users',
      {
        'username': 'admin',
        'password': 'adminpassword',
        'email': 'admin@gmail.com',
        'userType': 'admin',
      },
      
    );
    await db.insert(
      'posts',
      {
        'title': 'Junior Developer',
        'imageName': 'junior_dev.png',
        'userId': 1, // assuming the dummy user has id 1
        'companyName': 'Tech Corp',
        'lowestSalary': 3000.00,
        'highestSalary': 5000.00,
        'description': 'A great opportunity for junior developers.',
        'longitude': 101.6869,
        'latitude': 3.1390,
        'status': 'pending',
        'registration_no': 'JUN123',
        'area': 'Kuala Lumpur',
      },
    );

    await db.insert(
      'posts',
      {
        'title': 'Senior Developer',
        'imageName': 'senior_dev.png',
        'userId': 1, // assuming the dummy user has id 1
        'companyName': 'Innovate Ltd',
        'lowestSalary': 6000.00,
        'highestSalary': 9000.00,
        'description': 'Looking for experienced senior developers.',
        'longitude': 100.5018,
        'latitude': 13.7563,
        'status': 'pending',
        'registration_no': 'SEN456',
        'area': 'Johor',
      },
    );
  }

  // Create User
  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read Users
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final db = await database;
    return await db.query('users');
  }

  // Update User
  Future<void> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete User
  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Create Post
  Future<void> insertPost(Map<String, dynamic> post) async {
    final db = await database;
    await db.insert(
      'posts',
      post,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read Posts
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final db = await database;
    return await db.query('posts');
  }

  // Update Post
  Future<void> updatePost(int id, Map<String, dynamic> post) async {
    final db = await database;
    await db.update(
      'posts',
      post,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete Post
  Future<void> deletePost(int id) async {
    final db = await database;
    await db.delete(
      'posts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
