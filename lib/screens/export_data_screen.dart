import 'dart:io';
import 'package:csv/csv.dart';
import 'package:farm_app/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // For requesting permissions
import 'package:open_file/open_file.dart'; // For opening the file

class ExportDataScreen extends StatefulWidget {
  @override
  _ExportDataScreenState createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoading = false;
  String? csvFilePath; // To store the path of the saved CSV file

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        centerTitle: true,
        backgroundColor: AppColors.mainColor,
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _requestPermissionAndExport,
                    child: const Text('Export All Data to CSV'),
                  ),
                  if (csvFilePath != null) ...[
                    const SizedBox(height: 20),
                    Text('File saved at:'),
                    Text(csvFilePath ?? ''),
                  ],
                ],
              ),
      ),
    );
  }

  // Request storage permission and export data
  Future<void> _requestPermissionAndExport() async {
    // Check storage permissions
    if (await _requestStoragePermission()) {
      // If permission granted, proceed to export data
      _exportDataToCSV();
    } else {
      // Show a message if permission is denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Storage permission is required to save the file.')),
      );
    }
  }

  // Function to request storage permission
  Future<bool> _requestStoragePermission() async {
    // Request storage permission
    PermissionStatus status = await Permission.storage.request();

    // Return true if permission is granted, otherwise false
    return status.isGranted;
  }

  // Fetch all necessary data, convert to CSV, and save locally
  Future<void> _exportDataToCSV() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch data from Firestore
      DocumentSnapshot farmDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(userId)
          .get();
      DocumentSnapshot salesDoc = await FirebaseFirestore.instance
          .collection('sales')
          .doc(userId)
          .get();

      if (!farmDoc.exists || !salesDoc.exists) {
        throw Exception('No data found to export');
      }

      // Prepare farm data
      Map<String, dynamic> farmData = farmDoc.data() as Map<String, dynamic>;
      List<dynamic> salesData = salesDoc['sales'] as List<dynamic>;

      // Convert farm and sales data to CSV format
      List<List<dynamic>> csvData = [
        // Headers
        ['Category', 'Field', 'Value'],

        // Farm data
        ['Farm', 'Location', farmData['location']],
        ['Farm', 'Land Size', farmData['landSize']],
        ['Farm', 'Inventory Seeds', farmData['inventory']['seeds']],
        ['Farm', 'Inventory Water', farmData['inventory']['water']],
        ['Farm', 'Inventory Fertilizers', farmData['inventory']['fertilizers']],
        ['Farm', 'Total Expenses (RM)', farmData['inventory']['totalPrice']],

        // Sales data
        ...salesData.map((sale) => [
              'Sales',
              sale['productName'],
              'Grams: ${sale['grams']}g, Price: RM${sale['price']}'
            ]),
      ];

      // Generate CSV
      String csv = const ListToCsvConverter().convert(csvData);

      // Save CSV file locally in the Downloads directory
      final directory = Directory('/storage/emulated/0/Download');
      final path = '${directory.path}/farm_data.csv';
      final file = File(path);
      await file.writeAsString(csv);

      setState(() {
        csvFilePath = path; // Store the file path to display it
        isLoading = false;
      });

      // Show a message when the file is saved and open it automatically
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File saved at $path')),
      );

      // Open the saved file
      await OpenFile.open(path);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error exporting data: $e');
    }
  }
}
