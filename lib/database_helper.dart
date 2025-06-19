import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'product.dart';
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('products.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL'; // Correct type for double
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE products (
      id $idType,
      name $textType,
      description $textType,
      price $realType,
      quantity $integerType,
      image $textType,
      code $textType,
      color $textType
    )
    ''');
  }

  Future<void> insertProduct(Product product) async {
    final db = await instance.database;
    await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getProducts() async {
    final db = await instance.database;
    final result = await db.query('products');

    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<void> deleteProduct(int id) async {
    final db = await instance.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }


  Future<int> updateProduct(Product product) async {
    final db = await instance.database;

    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

}

