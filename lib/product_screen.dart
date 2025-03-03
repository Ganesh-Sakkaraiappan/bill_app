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

