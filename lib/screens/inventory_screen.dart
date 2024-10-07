import 'package:farm_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For date formatting

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid; // Get user ID
  Map<String, dynamic> currentInventory =
      {}; // Store the current inventory data
  List<Map<String, dynamic>> inventoryHistory = []; // Store inventory history

  @override
  void initState() {
    super.initState();
    _loadCurrentInventory(); // Load current inventory data from Firestore
    _loadInventoryHistory(); // Load inventory history data
  }

  // Load current inventory data from Firestore
  Future<void> _loadCurrentInventory() async {
    DocumentSnapshot farmDoc =
        await FirebaseFirestore.instance.collection('farms').doc(userId).get();

    if (farmDoc.exists) {
      setState(() {
        currentInventory = farmDoc['inventory'] as Map<String, dynamic>;
      });
    }
  }

  // Load inventory history data from Firestore
  Future<void> _loadInventoryHistory() async {
    QuerySnapshot historySnapshot = await FirebaseFirestore.instance
        .collection('farms')
        .doc(userId)
        .collection('inventory_history')
        .orderBy('date', descending: true)
        .get();

    setState(() {
      inventoryHistory = historySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  // Function to edit current inventory
  Future<void> _editInventory(Map<String, dynamic> updatedInventory) async {
    await FirebaseFirestore.instance
        .collection('farms')
        .doc(userId)
        .update({'inventory': updatedInventory});

    // Save history of the change
    await FirebaseFirestore.instance
        .collection('farms')
        .doc(userId)
        .collection('inventory_history')
        .add({
      'updated_inventory': updatedInventory,
      'date': DateTime.now(),
    });

    Get.snackbar('Success', 'Inventory updated successfully',
        backgroundColor: Colors.green, colorText: Colors.white);

    // Refresh the data
    _loadCurrentInventory();
    _loadInventoryHistory();
  }

  // Show a dialog for adding/editing inventory data
  void _showEditInventoryDialog(BuildContext context) {
    final TextEditingController seedsController = TextEditingController(
        text: currentInventory['seeds']?.toString() ?? '');
    final TextEditingController fertilizersController = TextEditingController(
        text: currentInventory['fertilizers']?.toString() ?? '');
    final TextEditingController pesticidesController = TextEditingController(
        text: currentInventory['pesticides']?.toString() ?? '');
    final TextEditingController waterController = TextEditingController(
        text: currentInventory['water']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Inventory Data'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: seedsController,
                  decoration: const InputDecoration(labelText: 'Seeds (kg)'),
                ),
                TextField(
                  controller: fertilizersController,
                  decoration:
                      const InputDecoration(labelText: 'Fertilizers (liters)'),
                ),
                TextField(
                  controller: pesticidesController,
                  decoration:
                      const InputDecoration(labelText: 'Pesticides (liters)'),
                ),
                TextField(
                  controller: waterController,
                  decoration:
                      const InputDecoration(labelText: 'Water (liters)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                // Update the inventory data
                Map<String, dynamic> updatedInventory = {
                  'seeds': seedsController.text,
                  'fertilizers': fertilizersController.text,
                  'pesticides': pesticidesController.text,
                  'water': waterController.text,
                };
                _editInventory(updatedInventory);
                Navigator.of(context).pop(); // Close the dialog
              },
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
        title: const Text('Inventory'),
        backgroundColor: AppColors.mainColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Display current inventory
          const Text(
            "Current Inventory",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Seeds: ${currentInventory['seeds']?.toString() ?? 'N/A'} kg",
                  ),
                  Text(
                    "Fertilizers: ${currentInventory['fertilizers']?.toString() ?? 'N/A'} liters",
                  ),
                  Text(
                    "Pesticides: ${currentInventory['pesticides']?.toString() ?? 'N/A'} liters",
                  ),
                  Text(
                    "Water: ${currentInventory['water']?.toString() ?? 'N/A'} liters",
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showEditInventoryDialog(context); // Edit inventory
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Display inventory history
          const SizedBox(height: 20),
          const Text(
            "Inventory History",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
          ...inventoryHistory.map((historyItem) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Date: ${DateFormat('yyyy-MM-dd').format(historyItem['date'].toDate())}"),
                    Text(
                      "Updated Inventory: ${historyItem['updated_inventory'].toString()}",
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
