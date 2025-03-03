import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  //sqfliteFfiInit();
  //databaseFactory = databaseFactoryFfi;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    MenuScreen(),
    ProductScreen(),
    CustomerScreen(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Product',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Customer',
            ),
          ]),
    );
  }
}

class MenuItem {
  final String name;
  final double price;
  int quantity;
  int stock;

  MenuItem({
    required this.name,
    required this.price,
    this.quantity = 0,
    this.stock = 0,
  });
}

class MenuScreen extends StatefulWidget {
  @override
  State<MenuScreen> createState() => _MenuScreen();
}

class _MenuScreen extends State<MenuScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> menuItems = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Fetch products from the database
  void _loadProducts() async {
    List<Map<String, dynamic>> productList = await _dbHelper.getProducts();
    setState(() {
      menuItems = productList.map((product) {
        return {
          ...product,
          'quantity': 0, // Initialize quantity to 0
        };
      }).toList();
    });
  }

  // Generate bill and show dialog
  void _generateBill() async {
    double totalAmount = 0;
    List<Map<String, dynamic>> billedItems = [];

    for (var item in menuItems) {
      if (item['quantity'] > 0) {
        // Calculate total amount for the item
        double itemTotal = item['price'] * item['quantity'];
        totalAmount += itemTotal;

        // Add item to billed items list
        billedItems.add({
          'id': item['id'], // Ensure 'id' is included
          'name': item['name'],
          'price': item['price'],
          'stock': item['stock'], // Ensure 'stock' is included
          'quantity': item['quantity'], // Ensure 'quantity' is included
          'total': itemTotal,
        });
      }
    }

    if (billedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No items selected for billing'),
        ),
      );
      return;
    }

    // Show bill dialog
    _showBillDialog(billedItems, totalAmount);
  }

  // Show bill dialog
  void _showBillDialog(List<Map<String, dynamic>> billedItems, double totalAmount) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Bill Summary'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var item in billedItems)
                  ListTile(
                    title: Text(item['name']),
                    subtitle: Text(
                        'Quantity: ${item['quantity']} | Price: Rs.${item['price']}'),
                    trailing: Text('Rs.${item['total'].toStringAsFixed(2)}'),
                  ),
                Divider(),
                Text(
                  'Total Amount: Rs.${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            // Done button
            TextButton(
              onPressed: () async {
                // Close the bill dialog
                Navigator.pop(context);

                // Show customer details dialog
                _showCustomerDetailsDialog(billedItems, totalAmount);
              },
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // Show customer details dialog
  void _showCustomerDetailsDialog(
      List<Map<String, dynamic>> billedItems, double totalAmount) {
    TextEditingController nameController = TextEditingController();
    TextEditingController addressController = TextEditingController();
    TextEditingController mobileController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Customer Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: mobileController,
                decoration: InputDecoration(labelText: 'Mobile Number'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            // Save button
            TextButton(
              onPressed: () async {
                // Validate inputs
                String name = nameController.text.trim();
                String address = addressController.text.trim();
                String mobile = mobileController.text.trim();

                if (name.isNotEmpty && address.isNotEmpty && mobile.isNotEmpty) {
                  try {
                    // Save customer details to the database
                    int customerId = await _dbHelper.insertCustomer({
                      'name': name,
                      'address': address,
                      'mobilNo': mobile,
                    });

                    // Generate a bill number (e.g., using timestamp)
                    String billNumber = DateTime.now().millisecondsSinceEpoch.toString();

                    // Save bill details to the database
                    int billId = await _dbHelper.insertBill({
                      'billNumber': billNumber,
                      'date': DateTime.now().toIso8601String(),
                      'customerId': customerId,
                      'totalAmount': totalAmount,
                    });

                    // Save bill items to the database
                    for (var item in billedItems) {
                      if (item['quantity'] > 0) {
                        await _dbHelper.insertBillItem({
                          'billId': billId,
                          'productId': item['id'],
                          'quantity': item['quantity'],
                          'price': item['price'],
                        });

                        // Update product stock
                        int newStock = item['stock'] - item['quantity'];
                        await _dbHelper.updateProductStock(item['id'], newStock);
                      }
                    }

                    // Refresh the product list
                    _loadProducts();

                    // Close the dialog
                    Navigator.pop(context);

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bill and customer details saved successfully!'),
                      ),
                    );
                  } catch (e) {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to save bill details. Please try again.'),
                      ),
                    );
                  }
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill all customer details'),
                    ),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Menu List',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          // Header Row
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Item", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Price", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Stock", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // List of Items
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Item Name
                        Text(
                          item['name'],
                          style: TextStyle(fontSize: 18),
                        ),
                        // Item Price
                        Text(
                          'Rs.${item['price']}',
                          style: TextStyle(fontSize: 18),
                        ),
                        // Item Stock
                        Text(
                          'Stock: ${item['stock']}',
                          style: TextStyle(fontSize: 18),
                        ),
                        // Quantity Controls
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  if (item['quantity'] > 0) {
                                    item['quantity']--;
                                  }
                                });
                              },
                              icon: Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              item['quantity'].toString(),
                              style: TextStyle(fontSize: 18),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  if (item['quantity'] < item['stock']) {
                                    item['quantity']++;
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Cannot exceed stock limit'),
                                      ),
                                    );
                                  }
                                });
                              },
                              icon: Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateBill,
        child: Icon(Icons.receipt),
      ),
    );
  }
}


class ProductScreen extends StatefulWidget {
  @override
  _ProductsScreen createState() => _ProductsScreen();
}

class _ProductsScreen extends State<ProductScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    List<Map<String, dynamic>> productList = await _dbHelper.getProducts();
    print('Loaded products: $productList'); // Debugging
    setState(() {
      products = productList;
    });
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    TextEditingController stockController = TextEditingController();

    if (product != null) {
      nameController.text = product['name'];
      priceController.text = product['price'].toString();
      stockController.text = product['stock'].toString();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            MaterialButton(
              onPressed: () async {
                String name = nameController.text.trim();
                double? price = double.tryParse(priceController.text.trim());
                int? stock = int.tryParse(stockController.text.trim());

                if (name.isNotEmpty &&
                    price != null &&
                    price > 0 &&
                    stock != null &&
                    stock >= 0) {
                  Map<String, dynamic> newProduct = {
                    'name': name,
                    'price': price,
                    'stock': stock,
                  };

                  try {
                    if (product == null) {
                      print('Inserting new product: $newProduct'); // Debugging
                      await _dbHelper.insertProduct(newProduct);
                    } else {
                      newProduct['id'] = product['id'];
                      print('Updating product: $newProduct'); // Debugging
                      await _dbHelper.updateProduct(newProduct);
                    }

                    _loadProducts();
                    Navigator.pop(context);
                  } catch (e) {
                    print('Database Error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Database error: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Please enter valid data (price > 0, stock >= 0)'),
                    ),
                  );
                }
              },
              child: Text(product == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Product List',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Expanded(
            child: products.isEmpty
                ? Center(child: Text('No products added'))
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      // Calculate sNo dynamically based on the index
                      int sNo = index + 1;
                      return ListTile(
                        leading: Text(
                          sNo.toString(), // Display sNo instead of id
                          style: TextStyle(fontSize: 18),
                        ),
                        title: Text(
                          product['name'],
                          style: TextStyle(fontSize: 20),
                        ),
                        subtitle: Text(
                          'Price: Rs.${product['price']} | Stock: ${product['stock']}',
                          style: TextStyle(fontSize: 18),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                _showProductDialog(product: product);
                              },
                              icon: Icon(Icons.edit, color: Colors.blue),
                            ),
                            IconButton(
                              onPressed: () async {
                                await _dbHelper.deleteProduct(product['id']);
                                _loadProducts();
                              },
                              icon: Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("FloatingActionButton clicked"); // Debugging
          _showProductDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}


class CustomerScreen extends StatefulWidget {
  @override
  State<CustomerScreen> createState() => _CustomerScreen();
}

class _CustomerScreen extends State<CustomerScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  // Fetch customers from the database
  void _loadCustomers() async {
    List<Map<String, dynamic>> customerList = await _dbHelper.getCustomers();
    setState(() {
      customers = customerList;
    });
  }

  // Show bill details for a customer
  void _showBillDetails(int customerId) async {
    List<Map<String, dynamic>> bills = await _dbHelper.getBills();
    List<Map<String, dynamic>> customerBills = bills.where((bill) => bill['customerId'] == customerId).toList();

    if (customerBills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No bills found for this customer.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Bill Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var bill in customerBills)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill Number: ${bill['billNumber']}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Date: ${bill['date']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Total Amount: Rs.${bill['totalAmount']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Divider(),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer List',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Expanded(
            child: customers.isEmpty
                ? Center(
                    child: Text('No customers added'),
                  )
                : ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return ListTile(
                        leading: Text(
                          customer['id'].toString(),
                          style: TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          customer['name'],
                          style: TextStyle(fontSize: 20),
                        ),
                        subtitle: Text(
                          'Address: ${customer['address']}  |  Mobile: ${customer['mobilNo']}',
                          style: TextStyle(fontSize: 20),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                _showBillDetails(customer['id']);
                              },
                              icon: Icon(
                                Icons.receipt,
                                color: Colors.blue,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await _dbHelper.deleteCustomer(customer['id']);
                                _loadCustomers();
                              },
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add customer functionality
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

