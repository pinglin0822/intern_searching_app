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
      await db.execute(
        "CREATE TABLE applicants(id INTEGER PRIMARY KEY AUTOINCREMENT, postId INTEGER, userId INTEGER, name TEXT, resume TEXT, contactNo TEXT, email TEXT, description TEXT, FOREIGN KEY (postId) REFERENCES posts (id), FOREIGN KEY (userId) REFERENCES users (id))",
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

  Future<void> updatePostStatus(int postId, String newStatus) async {
    final db = await database;
    await db.update(
      'posts',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [postId],
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

  Future<void> insertApplicant(Map<String, dynamic> applicant) async {
    final db = await database;
    await db.insert(
      'applicants',
      applicant,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getApplicantsForPost(int postId) async {
  final db = await database;
  return await db.query(
    'applicants',
    where: 'postId = ?',
    whereArgs: [postId],
  );
}


}
