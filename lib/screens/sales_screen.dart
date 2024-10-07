import 'package:farm_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SalesScreen extends StatefulWidget {
  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // Controllers for input fields
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController gramsController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  List<Map<String, dynamic>> sales = []; // List to store sales data
  double totalSales = 0.0; // Total of all sales

  @override
  void initState() {
    super.initState();
    _loadSalesData(); // Load the sales data when the page loads
  }

  // Load sales data from Firestore
  Future<void> _loadSalesData() async {
    DocumentSnapshot salesDoc =
        await FirebaseFirestore.instance.collection('sales').doc(userId).get();

    if (salesDoc.exists &&
        (salesDoc.data() as Map<String, dynamic>).containsKey('sales')) {
      setState(() {
        sales = (salesDoc['sales'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _calculateTotalSales();
      });
    }
  }

  // Save a new sale
  Future<void> _saveSale(String productName, String grams, String price) async {
    // Create a new sale entry
    Map<String, dynamic> newSale = {
      'productName': productName,
      'grams': grams,
      'price': price,
    };

    // Add the new sale to the list of sales
    sales.add(newSale);

    // Save the updated sales list to Firestore
    await FirebaseFirestore.instance.collection('sales').doc(userId).set(
      {
        'sales': sales,
      },
      SetOptions(merge: true),
    );

    // Recalculate total sales and update UI
    setState(() {
      _calculateTotalSales();
    });

    Get.snackbar('Success', 'Sale added successfully',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  // Edit an existing sale
  Future<void> _editSale(
      int index, String productName, String grams, String price) async {
    // Update the sale at the given index
    sales[index] = {
      'productName': productName,
      'grams': grams,
      'price': price,
    };

    // Save the updated sales list to Firestore
    await FirebaseFirestore.instance.collection('sales').doc(userId).set(
      {
        'sales': sales,
      },
      SetOptions(merge: true),
    );

    // Recalculate total sales and update UI
    setState(() {
      _calculateTotalSales();
    });

    Get.snackbar('Success', 'Sale edited successfully',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  // Delete an existing sale
  Future<void> _deleteSale(int index) async {
    // Remove the sale at the given index
    sales.removeAt(index);

    // Save the updated sales list to Firestore
    await FirebaseFirestore.instance.collection('sales').doc(userId).set(
      {
        'sales': sales,
      },
      SetOptions(merge: true),
    );

    // Recalculate total sales and update UI
    setState(() {
      _calculateTotalSales();
    });

    Get.snackbar('Success', 'Sale deleted successfully',
        backgroundColor: Colors.red, colorText: Colors.white);
  }

  // Calculate total sales
  void _calculateTotalSales() {
    totalSales = 0.0;
    for (var sale in sales) {
      totalSales += double.tryParse(sale['price']?.toString() ?? '0') ?? 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales'),
        backgroundColor: AppColors.mainColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Add a Sale',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: productNameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: gramsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Grams',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (Ringgit)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (productNameController.text.isNotEmpty &&
                      gramsController.text.isNotEmpty &&
                      priceController.text.isNotEmpty) {
                    await _saveSale(
                      productNameController.text,
                      gramsController.text,
                      priceController.text,
                    );

                    // Clear the fields after saving
                    productNameController.clear();
                    gramsController.clear();
                    priceController.clear();
                  } else {
                    Get.snackbar('Error', 'Please fill in all fields',
                        backgroundColor: Colors.red, colorText: Colors.white);
                  }
                },
                child: Text('Add Sale'),
              ),
              SizedBox(height: 32),
              Text(
                'Total Sales: RM $totalSales',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    var sale = sales[index];
                    return ListTile(
                      title: Text('${sale['productName']}'),
                      subtitle: Text(
                          'Grams: ${sale['grams']}g, Price: RM${sale['price']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showEditSaleDialog(
                                  context, index, sale); // Show edit dialog
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteSale(index); // Delete the sale
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show a dialog to edit the selected sale
  void _showEditSaleDialog(
      BuildContext context, int index, Map<String, dynamic> sale) {
    // Pre-fill the controllers with existing data
    productNameController.text = sale['productName'];
    gramsController.text = sale['grams'];
    priceController.text = sale['price'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Sale'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productNameController,
                decoration: InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: gramsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Grams'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price (Ringgit)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                // Save the edited sale
                await _editSale(
                  index,
                  productNameController.text,
                  gramsController.text,
                  priceController.text,
                );
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}
