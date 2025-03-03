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
