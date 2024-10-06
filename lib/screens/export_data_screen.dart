import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:csv/csv.dart';
//import 'dart:html' as html;

import '../utils/colors.dart'; // Import html package for web downloads

class ExportDataScreen extends StatefulWidget {
  @override
  _ExportDataScreenState createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic> salesData = {};
  Map<String, dynamic> dailyUsageData = {};
  Map<String, dynamic> monthlyUsageData = {};

  @override
  void initState() {
    super.initState();
    _loadAllData(); // Load all data when the page loads
  }

  // Load sales, daily, and monthly data from Firestore
  Future<void> _loadAllData() async {
    // Fetch Sales Data
    DocumentSnapshot salesDoc =
        await FirebaseFirestore.instance.collection('sales').doc(userId).get();
    if (salesDoc.exists) {
      salesData = salesDoc.data() as Map<String, dynamic>;
    }

    // Fetch Daily Usage Data
    DocumentSnapshot dailyDoc =
        await FirebaseFirestore.instance.collection('farms').doc(userId).get();
    if (dailyDoc.exists &&
        (dailyDoc.data() as Map<String, dynamic>).containsKey('daily_usage')) {
      dailyUsageData = (dailyDoc.data() as Map<String, dynamic>)['daily_usage'];
    }

    // Fetch Monthly Usage Data
    if (dailyDoc.exists) {
      monthlyUsageData = dailyDoc.data() as Map<String, dynamic>;
    }

    setState(() {});
  }

  // Convert data to CSV for Web
  Future<void> _exportToCSV() async {
    List<List<dynamic>> rows = [];

    // Add headers for each section
    rows.add(["Sales Data"]);
    rows.add(["Product Name", "Grams", "Price"]);
    for (var sale in salesData['sales']) {
      rows.add([sale['productName'], sale['grams'], sale['price']]);
    }

    rows.add([]); // Add empty row for spacing
    rows.add(["Daily Usage Data"]);
    rows.add([
      "Date",
      "Plug",
      "Vegetable/Fruit",
      "Seeds",
      "Water",
      "Fertilizers",
      "Pesticides"
    ]);
    dailyUsageData.forEach((date, usageData) {
      for (var update in usageData['updates']) {
        rows.add([
          date,
          update['plug'],
          update['vegFruit'],
          update['seeds'],
          update['water'],
          update['fertilizers'],
          update['pesticides']
        ]);
      }
    });

    rows.add([]); // Add empty row for spacing
    rows.add(["Monthly Usage Data"]);
    rows.add([
      "Land Size",
      "Plugs",
      "Plant Type",
      "Seeds",
      "Fertilizers",
      "Pesticides",
      "Water",
      "Electricity"
    ]);
    rows.add([
      monthlyUsageData['landSize'],
      (monthlyUsageData['plugs'] as List<dynamic>).length,
      monthlyUsageData['plantType'],
      monthlyUsageData['inventory']['seeds'],
      monthlyUsageData['inventory']['fertilizers'],
      monthlyUsageData['inventory']['pesticides'],
      monthlyUsageData['inventory']['water'],
      monthlyUsageData['inventory']['electricity']
    ]);

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Create a blob for web download
    final bytes = utf8.encode(csv);
    // final blob = html.Blob([bytes]);
    // final url = html.Url.createObjectUrlFromBlob(blob);
    // final anchor = html.AnchorElement(href: url)
    //   ..setAttribute("download", "exported_data.csv")
    //   ..click();
    // html.Url.revokeObjectUrl(url); // Revoke the URL to release resources
  }

  // Convert data to JSON for Web
  Future<void> _exportToJSON() async {
    Map<String, dynamic> allData = {
      'sales': salesData['sales'],
      'daily_usage': dailyUsageData,
      'monthly_usage': monthlyUsageData,
    };

    // Convert to JSON string
    String json = jsonEncode(allData);

    // Create a blob for web download
    final bytes = utf8.encode(json);
    // final blob = html.Blob([bytes]);
    // final url = html.Url.createObjectUrlFromBlob(blob);
    // final anchor = html.AnchorElement(href: url)
    //   ..setAttribute("download", "exported_data.json")
    //   ..click();
    // html.Url.revokeObjectUrl(url); // Revoke the URL to release resources
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Export Data'),
        backgroundColor: AppColors.mainColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Your Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _exportToCSV,
              child: Text('Export to CSV'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _exportToJSON,
              child: Text('Export to JSON'),
            ),
            SizedBox(height: 32),
            Text(
              'Your data will be saved as a downloadable file.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
