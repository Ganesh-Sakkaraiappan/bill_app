import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'products.db');
    return await openDatabase(
      path,
      version: 3, // Increment the version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add onUpgrade method
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create products table
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price REAL,
        stock INTEGER
      )
    ''');

    // Create customers table
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        address TEXT,
        mobilNo TEXT
      )
    ''');

    // Create bills table
    await db.execute('''
    CREATE TABLE bills(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      billNumber TEXT,
      date TEXT,
      customerId INTEGER,
      totalAmount REAL,
      tax REAL,
      discount REAL,
      finalAmount REAL,
      FOREIGN KEY (customerId) REFERENCES customers(id)
    )
  ''');

    // Create bill_items table
    await db.execute('''
      CREATE TABLE bill_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billId INTEGER,
        productId INTEGER,
        quantity INTEGER,
        price REAL,
        FOREIGN KEY (billId) REFERENCES bills(id),
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Add bills and bill_items tables if they don't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bills(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          billNumber TEXT,
          date TEXT,
          customerId INTEGER,
          totalAmount REAL,
          FOREIGN KEY (customerId) REFERENCES customers(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS bill_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          billId INTEGER,
          productId INTEGER,
          quantity INTEGER,
          price REAL,
          FOREIGN KEY (billId) REFERENCES bills(id),
          FOREIGN KEY (productId) REFERENCES products(id)
        )
      ''');
    }
  }

  // Product-related methods
  Future<int> insertProduct(Map<String, dynamic> product) async {
    Database db = await database;
    return await db.insert('products', product);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    Database db = await database;
    return await db.query('products');
  }

  Future<int> updateProduct(Map<String, dynamic> product) async {
    Database db = await database;
    return await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  Future<int> deleteProduct(int id) async {
    Database db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Customer-related methods
  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    Database db = await database;
    return await db.insert('customers', customer);
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    Database db = await database;
    return await db.query('customers');
  }

  Future<int> updateCustomer(Map<String, dynamic> customer) async {
    Database db = await database;
    return await db.update(
      'customers',
      customer,
      where: 'id = ?',
      whereArgs: [customer['id']],
    );
  }

  Future<int> deleteCustomer(int id) async {
    Database db = await database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Bill-related methods
  Future<int> insertBill(Map<String, dynamic> bill) async {
    Database db = await database;
    return await db.insert('bills', bill);
  }

  Future<int> insertBillItem(Map<String, dynamic> billItem) async {
    Database db = await database;
    return await db.insert('bill_items', billItem);
  }

  Future<List<Map<String, dynamic>>> getBills() async {
    Database db = await database;
    return await db.query('bills');
  }

  Future<List<Map<String, dynamic>>> getBillItems(int billId) async {
    Database db = await database;
    return await db.query(
      'bill_items',
      where: 'billId = ?',
      whereArgs: [billId],
    );
  }

  // Update product stock
  Future<void> updateProductStock(int productId, int newStock) async {
    Database db = await database;
    await db.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }
}
