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

