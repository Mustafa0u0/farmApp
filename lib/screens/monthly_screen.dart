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
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic> dailyUsageData = {};

  @override
  void initState() {
    super.initState();
    _loadDailyUsageData(); // Load daily usage data
  }

  // Load daily usage data from Firestore
  Future<void> _loadDailyUsageData() async {
    DocumentSnapshot farmDoc =
        await FirebaseFirestore.instance.collection('farms').doc(userId).get();

    if (farmDoc.exists &&
        (farmDoc.data() as Map<String, dynamic>).containsKey('daily_usage')) {
      var dailyUsage = farmDoc['daily_usage'] as Map<String, dynamic>;

      setState(() {
        dailyUsageData = dailyUsage
            .map((date, data) => MapEntry(date, data as Map<String, dynamic>));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Report'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _loadDailyUsageData(); // Refresh the data
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Daily Activity Report",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
          const SizedBox(height: 16),
          ...dailyUsageData.entries.map((entry) {
            String date = entry.key; // Date of the entry
            var updates = (entry.value['updates'] as List<dynamic>? ??
                []); // List of updates for the day

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
                    Text("Date: $date",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // Loop through and display each update for this day
                    ...updates.map((update) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Plug: ${update['plug'] ?? 'N/A'}"),
                            Text(
                                "Vegetable/Fruit: ${update['vegFruit'] ?? 'N/A'}"),
                            Text(
                                "Seeds: ${update['seeds']?.toString() ?? 'N/A'} grams"),
                            Text(
                                "Fertilizers: ${update['fertilizers']?.toString() ?? 'N/A'} liters"),
                            Text(
                                "Pesticides: ${update['pesticides']?.toString() ?? 'N/A'} liters"),
                            Text(
                                "Water: ${update['water']?.toString() ?? 'N/A'} liters"),
                          ],
                        ),
                      );
                    }).toList(),
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
