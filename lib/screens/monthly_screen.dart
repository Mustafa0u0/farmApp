import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_app/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MonthlyUpdatesPage extends StatefulWidget {
  @override
  _MonthlyUpdatesPageState createState() => _MonthlyUpdatesPageState();
}

class _MonthlyUpdatesPageState extends State<MonthlyUpdatesPage> {
  Map<String, dynamic> monthlyUpdates = {}; // Store monthly updates

  @override
  void initState() {
    super.initState();
    _loadMonthlyUpdates();
  }

  // Load the monthly updates from Firestore
  Future<void> _loadMonthlyUpdates() async {
    DocumentSnapshot farmDoc = await FirebaseFirestore.instance
        .collection('farms')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (farmDoc.exists) {
      setState(() {
        monthlyUpdates = farmDoc['monthly_usage'] ?? {};
      });
    }
  }

  // Save monthly usage data to Firestore
  Future<void> _saveMonthlyUsage(
    String landSize,
    String plugs,
    String plantType,
    String seeds,
    String water,
    String fertilizers,
    String pesticides,
    String electricity,
  ) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final String month =
        DateFormat('yyyy-MM').format(DateTime.now()); // Use current month

    try {
      // Save the monthly usage data in a similar structure as the farm data
      await FirebaseFirestore.instance.collection('farms').doc(userId).set({
        'monthly_usage': {
          month: {
            'landSize': landSize,
            'plugs': plugs,
            'plantType': plantType,
            'inventory': {
              'seeds': seeds,
              'water': water,
              'fertilizers': fertilizers,
              'pesticides': pesticides,
              'electricity': electricity,
            }
          }
        }
      }, SetOptions(merge: true)); // Use merge to avoid overwriting other data

      Get.snackbar('Success', 'Monthly usage saved successfully',
          backgroundColor: Colors.green, colorText: Colors.white);

      // Reload the monthly updates to reflect the new data
      _loadMonthlyUpdates();
    } catch (e) {
      Get.snackbar('Error', 'Failed to save monthly usage',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // Show a form to add monthly data
  void _showMonthlyUsageForm(BuildContext context) {
    final TextEditingController landSizeController = TextEditingController();
    final TextEditingController plugsController = TextEditingController();
    final TextEditingController plantTypeController = TextEditingController();
    final TextEditingController seedsController = TextEditingController();
    final TextEditingController waterController = TextEditingController();
    final TextEditingController fertilizersController = TextEditingController();
    final TextEditingController pesticidesController = TextEditingController();
    final TextEditingController electricityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Monthly Update'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: landSizeController,
                  decoration:
                      InputDecoration(labelText: 'Land Size (Hectares)'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: plugsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Number of Plugs'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: plantTypeController,
                  decoration: InputDecoration(labelText: 'Plant Type'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: seedsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Seeds (kg)'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: waterController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Water (Liters)'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: fertilizersController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: 'Fertilizers (Liters)'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: pesticidesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Pesticides (Liters)'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: electricityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Electricity (kWh)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                // Validate and save monthly usage data
                await _saveMonthlyUsage(
                  landSizeController.text,
                  plugsController.text,
                  plantTypeController.text,
                  seedsController.text,
                  waterController.text,
                  fertilizersController.text,
                  pesticidesController.text,
                  electricityController.text,
                );
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
        title: Text('Monthly Updates'),
      ),
      body: ListView(
        children: monthlyUpdates.entries.map((entry) {
          String month = entry.key;
          Map<String, dynamic> monthData = entry.value;

          // Extract inventory data
          Map<String, dynamic> inventory = monthData['inventory'] ?? {};

          return ListTile(
            title: Text('Month: $month'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Land Size: ${monthData['landSize']} Hectares'),
                Text('Plugs: ${monthData['plugs']}'),
                Text('Plant Type: ${monthData['plantType']}'),
                Text('Seeds: ${inventory['seeds']} kg'),
                Text('Water: ${inventory['water']} L'),
                Text('Fertilizers: ${inventory['fertilizers']} L'),
                Text('Pesticides: ${inventory['pesticides']} L'),
                Text('Electricity: ${inventory['electricity']} kWh'),
              ],
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showMonthlyUsageForm(context);
        },
        child: Icon(Icons.add),
        backgroundColor: AppColors.mainColor,
      ),
    );
  }
}
