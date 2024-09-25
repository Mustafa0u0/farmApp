import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_app/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:fl_chart/fl_chart.dart'; // For graphs

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid; // Get user ID
  Map<String, dynamic> monthlyUsage =
      {}; // Store the farm data as monthly usage
  Map<String, dynamic> remainingInventory = {}; // Store the remaining inventory
  Map<String, dynamic> dailyUsageData = {}; // Daily usage data for each day
  double totalWaterUsed = 0.0; // Total water used, for example

  @override
  void initState() {
    super.initState();
    _loadFarmData(); // Load the farm data from Firestore for the monthly monitor
    _loadDailyUsageData(); // Load daily usage data
  }

  // Load farm data from Firestore (ManageYourFarm data)
  Future<void> _loadFarmData() async {
    DocumentSnapshot farmDoc =
        await FirebaseFirestore.instance.collection('farms').doc(userId).get();

    if (farmDoc.exists) {
      setState(() {
        monthlyUsage = farmDoc.data() as Map<String, dynamic>;
        _calculateRemainingInventory();
      });
    }
  }

  // Load daily usage data
  Future<void> _loadDailyUsageData() async {
    DocumentSnapshot farmDoc =
        await FirebaseFirestore.instance.collection('farms').doc(userId).get();

    if (farmDoc.exists &&
        (farmDoc.data() as Map<String, dynamic>).containsKey('daily_usage')) {
      var dailyUsage = farmDoc['daily_usage'] as Map<String, dynamic>;

      setState(() {
        dailyUsageData = dailyUsage
            .map((date, data) => MapEntry(date, data as Map<String, dynamic>));
        _calculateTotalUsage();
        _calculateRemainingInventory();
      });
    }
  }

  // Calculate total usage and update remaining inventory
  void _calculateTotalUsage() {
    totalWaterUsed = 0.0;

    dailyUsageData.forEach((date, data) {
      totalWaterUsed +=
          double.tryParse(data['water']?.toString() ?? '0') ?? 0.0;
    });
  }

  // Calculate remaining inventory by subtracting daily usage from monthly inventory
  void _calculateRemainingInventory() {
    if (monthlyUsage.isNotEmpty) {
      setState(() {
        // Ensure seeds are handled safely
        double seedsInventory = double.tryParse(
                monthlyUsage['inventory']?['seeds']?.toString() ?? '0') ??
            0.0;
        double seedsUsed = dailyUsageData.values
            .map((day) =>
                double.tryParse(day['seeds']?.toString() ?? '0') ?? 0.0)
            .fold(0.0, (prev, curr) => prev + curr);
        remainingInventory['seeds'] = seedsInventory - seedsUsed;

        // Ensure fertilizers are handled safely
        double fertilizersInventory = double.tryParse(
                monthlyUsage['inventory']?['fertilizers']?.toString() ?? '0') ??
            0.0;
        double fertilizersUsed = dailyUsageData.values
            .map((day) =>
                double.tryParse(day['fertilizers']?.toString() ?? '0') ?? 0.0)
            .fold(0.0, (prev, curr) => prev + curr);
        remainingInventory['fertilizers'] =
            fertilizersInventory - fertilizersUsed;

        // Ensure pesticides are handled safely
        double pesticidesInventory = double.tryParse(
                monthlyUsage['inventory']?['pesticides']?.toString() ?? '0') ??
            0.0;
        double pesticidesUsed = dailyUsageData.values
            .map((day) =>
                double.tryParse(day['pesticides']?.toString() ?? '0') ?? 0.0)
            .fold(0.0, (prev, curr) => prev + curr);
        remainingInventory['pesticides'] = pesticidesInventory - pesticidesUsed;

        // Ensure water is handled safely
        double waterInventory = double.tryParse(
                monthlyUsage['inventory']?['water']?.toString() ?? '0') ??
            0.0;
        double waterUsed = dailyUsageData.values
            .map((day) =>
                double.tryParse(day['water']?.toString() ?? '0') ?? 0.0)
            .fold(0.0, (prev, curr) => prev + curr);
        remainingInventory['water'] = waterInventory - waterUsed;
      });
    }
  }

  // Get the current month and year for display
  String _getCurrentMonth() {
    final DateTime now = DateTime.now();
    return DateFormat.yMMMM().format(now); // Format as "September 2024"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,

      appBar: AppBar(
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Open the Drawer
              },
            );
          },
        ),
        title: const Text(
          'Farm Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.mainColor,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.mainColor,
              ),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                FirebaseAuth.instance.signOut(); // Log out user
                Get.offAllNamed('/welcome');
              },
            ),
          ],
        ),
      ),

      body: ListView(
        children: [
          Container(
            height: 250,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            width: double.infinity,
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.location_pin,
                      color: Colors.white,
                      size: 20,
                    ),
                    Text(
                      "Malaysia, Kelantan",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Today, ${DateTime.now().day} ${DateFormat.MMMM().format(DateTime.now())}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400),
                      ),
                      const Text(
                        "29°",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 80,
                            fontWeight: FontWeight.w400),
                      ),
                      const Text(
                        "Cloudy",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wind_power,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Wind",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "10 km/h",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(width: 15),
                          Text(
                            "|",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(width: 15),
                          Icon(
                            Icons.water_outlined,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Hum",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "54 %",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 500,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40))),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Monthly Activity Monitor",
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
                          "Month: ${_getCurrentMonth()}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            "Land Size: ${monthlyUsage['landSize'] ?? 'N/A'} hectares"),
                        Text("Plugs: ${monthlyUsage['plugs'] ?? 'N/A'}"),
                        Text(
                            "Plant Type: ${monthlyUsage['plantType'] ?? 'N/A'}"),
                        const SizedBox(height: 10),
                        const Text("Inventory:"),
                        Text(
                            "Seeds: ${remainingInventory['seeds']?.toString() ?? 'N/A'} kg left"),
                        Text(
                            "Fertilizers: ${remainingInventory['fertilizers']?.toString() ?? 'N/A'} liters left"),
                        Text(
                            "Pesticides: ${remainingInventory['pesticides']?.toString() ?? 'N/A'} liters left"),
                        Text(
                            "Water: ${remainingInventory['water']?.toString() ?? 'N/A'} liters left"),
                        Text(
                            "Electricity: ${monthlyUsage['inventory']?['electricity']?.toString() ?? 'N/A'} kWh"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Daily Activity Monitor",
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
                // Display daily usage summary in cards with dates
                ...dailyUsageData.entries.map((entry) {
                  String date = entry.key; // Date of the entry
                  var usage = entry.value;

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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                              "Seeds: ${usage['seeds']?.toString() ?? 'N/A'} grams"),
                          Text(
                              "Fertilizers: ${usage['fertilizers']?.toString() ?? 'N/A'} liters"),
                          Text(
                              "Pesticides: ${usage['pesticides']?.toString() ?? 'N/A'} liters"),
                          Text(
                              "Water: ${usage['water']?.toString() ?? 'N/A'} liters"),
                        ],
                      ),
                    ),
                  );
                }).toList(),

// Inside your widget:

                const Text(
                  "Resource Usage Over Time",
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
                // SizedBox(
                //   height: 250,
                //   child: LineChart(
                //     LineChartData(
                //       titlesData: FlTitlesData(
                //         bottomTitles: AxisTitles(
                //           sideTitles: SideTitles(
                //             showTitles: true,
                //             interval: 1,
                //             getTitlesWidget: (value, meta) {
                //               return Text(
                //                 DateFormat('dd').format(DateTime.now().subtract(
                //                     Duration(days: (30 - value.toInt())))),
                //                 style: TextStyle(
                //                     color: Colors.black, fontSize: 10),
                //               );
                //             },
                //           ),
                //         ),
                //         leftTitles: AxisTitles(
                //           sideTitles: SideTitles(
                //             showTitles: true,
                //             interval: 10, // Adjust based on your Y-axis range
                //             getTitlesWidget: (value, meta) {
                //               return Text(
                //                 value.toString(),
                //                 style: TextStyle(
                //                     color: Colors.black, fontSize: 10),
                //               );
                //             },
                //           ),
                //         ),
                //       ),
                //       gridData: FlGridData(
                //           show: true), // Show grid for better readability
                //       lineBarsData: [
                //         // Water Line
                //         LineChartBarData(
                //           spots: dailyUsageData.entries.map((entry) {
                //             String date = entry.key;
                //             double water = double.tryParse(
                //                     entry.value['water']?.toString() ?? '0') ??
                //                 0.0;
                //             DateTime parsedDate = DateTime.parse(date);
                //             return FlSpot(parsedDate.day.toDouble(), water);
                //           }).toList(),
                //           isCurved: false, // Straight lines (not curved)
                //           color:
                //               Colors.blueAccent, // Adjust the color as desired
                //           barWidth: 2,
                //           belowBarData: BarAreaData(
                //               show: true,
                //               color: Colors.blueAccent.withOpacity(0.2)),
                //           dotData: FlDotData(
                //               show: true), // Show dots for data points
                //         ),
                //         // Seeds Line
                //         LineChartBarData(
                //           spots: dailyUsageData.entries.map((entry) {
                //             String date = entry.key;
                //             double seeds = double.tryParse(
                //                     entry.value['seeds']?.toString() ?? '0') ??
                //                 0.0;
                //             DateTime parsedDate = DateTime.parse(date);
                //             return FlSpot(parsedDate.day.toDouble(), seeds);
                //           }).toList(),
                //           isCurved: false, // Straight lines (not curved)
                //           color: Colors.greenAccent,
                //           barWidth: 2,
                //           belowBarData: BarAreaData(
                //               show: true,
                //               color: Colors.greenAccent.withOpacity(0.2)),
                //           dotData: FlDotData(show: true),
                //         ),
                //         // Fertilizers Line
                //         LineChartBarData(
                //           spots: dailyUsageData.entries.map((entry) {
                //             String date = entry.key;
                //             double fertilizers = double.tryParse(
                //                     entry.value['fertilizers']?.toString() ??
                //                         '0') ??
                //                 0.0;
                //             DateTime parsedDate = DateTime.parse(date);
                //             return FlSpot(
                //                 parsedDate.day.toDouble(), fertilizers);
                //           }).toList(),
                //           isCurved: false,
                //           color: Colors.orangeAccent,
                //           barWidth: 2,
                //           belowBarData: BarAreaData(
                //               show: true,
                //               color: Colors.orangeAccent.withOpacity(0.2)),
                //           dotData: FlDotData(show: true),
                //         ),
                //         // Pesticides Line
                //         LineChartBarData(
                //           spots: dailyUsageData.entries.map((entry) {
                //             String date = entry.key;
                //             double pesticides = double.tryParse(
                //                     entry.value['pesticides']?.toString() ??
                //                         '0') ??
                //                 0.0;
                //             DateTime parsedDate = DateTime.parse(date);
                //             return FlSpot(
                //                 parsedDate.day.toDouble(), pesticides);
                //           }).toList(),
                //           isCurved: false,
                //           color: Colors.redAccent,
                //           barWidth: 2,
                //           belowBarData: BarAreaData(
                //               show: true,
                //               color: Colors.redAccent.withOpacity(0.2)),
                //           dotData: FlDotData(show: true),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),

// Show remaining inventory below the chart
                SvgPicture.asset("assets/images/1.svg"),
                SizedBox(height: 10),
                SvgPicture.asset("assets/images/3.svg"),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Remaining Resources:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                          "Seeds Left: ${remainingInventory['seeds']?.toString() ?? 'N/A'} kg"),
                      Text(
                          "Fertilizers Left: ${remainingInventory['fertilizers']?.toString() ?? 'N/A'} liters"),
                      Text(
                          "Pesticides Left: ${remainingInventory['pesticides']?.toString() ?? 'N/A'} liters"),
                      Text(
                          "Water Left: ${remainingInventory['water']?.toString() ?? 'N/A'} liters"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Floating Action Button to add daily farm usage
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show a form to enter daily farm usage
          _showDailyUsageForm(context);
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: AppColors.mainColor,
      ),
    );
  }

  void _showDailyUsageForm(BuildContext context) {
    // Controllers for text fields
    final TextEditingController seedsController = TextEditingController();
    final TextEditingController waterController = TextEditingController();
    final TextEditingController fertilizersController = TextEditingController();
    final TextEditingController pesticidesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Daily Usage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: seedsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Seeds (grams)'),
              ),
              TextField(
                controller: waterController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Water (liters)'),
              ),
              TextField(
                controller: fertilizersController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Fertilizers (liters)'),
              ),
              TextField(
                controller: pesticidesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Pesticides (liters)'),
              ),
            ],
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
                // Validate input and save to Firestore
                await _saveDailyUsage(
                  seedsController.text,
                  waterController.text,
                  fertilizersController.text,
                  pesticidesController.text,
                );
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveDailyUsage(
    String seeds,
    String water,
    String fertilizers,
    String pesticides,
  ) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // Save the daily usage under the 'daily_usage' field in the user's document
      await FirebaseFirestore.instance.collection('farms').doc(userId).set(
          {
            'daily_usage': {
              today: {
                'seeds': seeds,
                'water': water,
                'fertilizers': fertilizers,
                'pesticides': pesticides,
              },
            }
          },
          SetOptions(
              merge:
                  true)); // Merge the data instead of overwriting the entire document

      Get.snackbar('Success', 'Daily usage saved successfully',
          backgroundColor: Colors.green, colorText: Colors.white);

      // Reload data to refresh the UI
      _loadDailyUsageData();
    } catch (e) {
      Get.snackbar('Error', 'Failed to save daily usage',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
