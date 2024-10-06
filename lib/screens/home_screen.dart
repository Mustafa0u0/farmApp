import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_app/screens/export_data_screen.dart';
import 'package:farm_app/screens/monthly_screen.dart';
import 'package:farm_app/screens/sales_screen.dart';
import 'package:farm_app/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  String userLocation = "Malaysia"; // Default location (will be updated)

  // Financial fields
  double totalIncome = 0.0; // From sales
  double totalExpenses = 0.0; // From inventory (totalPrice)
  double profit = 0.0; // Profit = Income - Expenses

  @override
  void initState() {
    super.initState();
    _loadFarmData(); // Load the farm data from Firestore for the monthly monitor
    _loadDailyUsageData(); // Load daily usage data
    _loadSalesData(); // Load sales data for income
  }

  // Load farm data from Firestore (ManageYourFarm data)
  Future<void> _loadFarmData() async {
    DocumentSnapshot farmDoc =
        await FirebaseFirestore.instance.collection('farms').doc(userId).get();

    if (farmDoc.exists) {
      setState(() {
        monthlyUsage = farmDoc.data() as Map<String, dynamic>;
        userLocation = farmDoc['location'] ??
            'Malaysia'; // Get user's location from Firestore

        // Calculate total expenses from the inventory (totalPrice)
        totalExpenses = double.tryParse(
                monthlyUsage['inventory']?['totalPrice']?.toString() ?? '0') ??
            0.0;

        _calculateRemainingInventory();
        _calculateProfit(); // Calculate the profit after loading farm data
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

  // Load sales data from Firestore to calculate total income
  Future<void> _loadSalesData() async {
    DocumentSnapshot salesDoc =
        await FirebaseFirestore.instance.collection('sales').doc(userId).get();

    if (salesDoc.exists &&
        (salesDoc.data() as Map<String, dynamic>).containsKey('sales')) {
      List<dynamic> sales = salesDoc['sales'] as List<dynamic>;

      setState(() {
        totalIncome = 0.0;
        for (var sale in sales) {
          totalIncome +=
              double.tryParse(sale['price']?.toString() ?? '0') ?? 0.0;
        }

        _calculateProfit(); // Calculate the profit after loading sales data
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

  // Calculate profit = income - expenses
  void _calculateProfit() {
    setState(() {
      profit = totalIncome - totalExpenses;
    });
  }

  // Get the current month and year for display
  String _getCurrentMonth() {
    final DateTime now = DateTime.now();
    return DateFormat.yMMMM().format(now); // Format as "September 2024"
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Logout"),
          content: Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Logout"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                FirebaseAuth.instance.signOut(); // Log out user
                Get.offAllNamed('/welcome'); // Redirect to the welcome page
              },
            ),
          ],
        );
      },
    );
  }

  // Refresh the home page
  void _refreshPage() {
    setState(() {
      _loadFarmData();
      _loadDailyUsageData();
      _loadSalesData();
    });
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () {
              _refreshPage(); // Refresh the page when button is pressed
            },
          ),
        ],
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
              leading: Icon(Icons.sell),
              title: Text('Sales'),
              onTap: () {
                Get.to(() => SalesScreen()); // Navigate to Sales Page
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Monthly Updates'),
              onTap: () {
                Get.to(() =>
                    MonthlyUpdatesPage()); // Navigate to Monthly Updates Page
              },
            ),
            ListTile(
              leading: Icon(Icons.download),
              title: Text('Export Data'),
              onTap: () {
                Get.to(() => ExportDataScreen()); // Navigate to Export Page
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                // Show confirmation dialog
                _showLogoutConfirmationDialog(context);
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
                Row(
                  children: [
                    Icon(
                      Icons.location_pin,
                      color: Colors.white,
                      size: 20,
                    ),
                    // Display user's city and keep "Malaysia"
                    Text(
                      "Malaysia, $userLocation", // Updated to show user's location
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
                // Monthly Activity Monitor with Edit Button
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
                        Text(
                            "Plugs: ${(monthlyUsage['plugs'] as List<dynamic>?)?.length ?? 'N/A'}"),
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
                        Text(
                            "Total Price (RM): ${monthlyUsage['inventory']?['totalPrice']?.toString() ?? 'N/A'} kWh"),

                        // Edit button for monthly data
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showEditMonthlyDataDialog(
                                  context); // Open monthly data edit dialog
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Daily Activity Monitor with Edit Button
                const Text(
                  "Daily Activity Monitor",
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
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

                          // Edit button for daily data
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _showEditDailyDataDialog(context, date,
                                    updates); // Open daily data edit dialog
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

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
                            "Financial Overview",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              "Total Income: ${totalIncome.toStringAsFixed(2)} RM "),
                          Text(
                              "Total Expenses: ${totalExpenses.toStringAsFixed(2)} RM "),
                          Text("Profit: ${profit.toStringAsFixed(2)} RM "),
                        ],
                      ),
                    )),
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

  void _showDailyUsageForm(BuildContext context) async {
    // Fetch plugs from Firestore
    DocumentSnapshot farmDoc =
        await FirebaseFirestore.instance.collection('farms').doc(userId).get();
    List<String> plugs = (farmDoc['plugs'] as List<dynamic>).cast<String>();

    // Controllers for text fields
    final TextEditingController seedsController = TextEditingController();
    final TextEditingController waterController = TextEditingController();
    final TextEditingController fertilizersController = TextEditingController();
    final TextEditingController pesticidesController = TextEditingController();
    final TextEditingController vegFruitController =
        TextEditingController(); // For vegetable/fruit name
    String? selectedPlug;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Daily Usage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dropdown for selecting the plug
              DropdownButtonFormField<String>(
                value: selectedPlug,
                items: plugs.map((String plug) {
                  return DropdownMenuItem(value: plug, child: Text(plug));
                }).toList(),
                onChanged: (String? newValue) {
                  selectedPlug = newValue;
                },
                decoration: InputDecoration(labelText: 'Select Plug'),
              ),
              TextField(
                controller: vegFruitController,
                decoration: InputDecoration(labelText: 'Vegetable/Fruit Name'),
              ),
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
                  selectedPlug!,
                  vegFruitController.text,
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
    String plug,
    String vegFruit,
    String seeds,
    String water,
    String fertilizers,
    String pesticides,
  ) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // Retrieve existing daily usage data for today, if any
      DocumentSnapshot farmDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(userId)
          .get();
      List<dynamic> existingUpdates =
          []; // Default to empty list if no data exists

      if (farmDoc.exists &&
          (farmDoc.data() as Map<String, dynamic>).containsKey('daily_usage')) {
        var dailyUsageData = (farmDoc['daily_usage'] as Map<String, dynamic>);
        if (dailyUsageData.containsKey(today)) {
          existingUpdates =
              dailyUsageData[today]['updates'] as List<dynamic>? ??
                  []; // Ensure it's a list or empty
        }
      }

      // Add the new daily update to the existing updates
      existingUpdates.add({
        'plug': plug,
        'vegFruit': vegFruit,
        'seeds': seeds,
        'water': water,
        'fertilizers': fertilizers,
        'pesticides': pesticides,
      });

      // Save the updated daily usage data back to Firestore
      await FirebaseFirestore.instance.collection('farms').doc(userId).set(
        {
          'daily_usage': {
            today: {
              'updates': existingUpdates, // Store the array of updates
            }
          }
        },
        SetOptions(
            merge:
                true), // Merge the data instead of overwriting the entire document
      );

      Get.snackbar('Success', 'Daily usage saved successfully',
          backgroundColor: Colors.green, colorText: Colors.white);

      // Reload data to refresh the UI
      _loadDailyUsageData();
    } catch (e) {
      Get.snackbar('Error', 'Failed to save daily usage',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _showEditMonthlyDataDialog(BuildContext context) {
    // Controllers to edit monthly data
    final TextEditingController landSizeController =
        TextEditingController(text: monthlyUsage['landSize']?.toString() ?? '');
    final TextEditingController seedsController = TextEditingController(
        text: remainingInventory['seeds']?.toString() ?? '');
    final TextEditingController fertilizersController = TextEditingController(
        text: remainingInventory['fertilizers']?.toString() ?? '');
    final TextEditingController pesticidesController = TextEditingController(
        text: remainingInventory['pesticides']?.toString() ?? '');
    final TextEditingController waterController = TextEditingController(
        text: remainingInventory['water']?.toString() ?? '');
    final TextEditingController electricityController = TextEditingController(
        text: monthlyUsage['inventory']?['electricity']?.toString() ?? '');
    final TextEditingController totalPriceController = TextEditingController(
        text: monthlyUsage['inventory']?['totalPrice']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Monthly Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: landSizeController,
                decoration: InputDecoration(labelText: 'Land Size (hectares)'),
              ),
              TextField(
                controller: seedsController,
                decoration: InputDecoration(labelText: 'Seeds (kg)'),
              ),
              TextField(
                controller: fertilizersController,
                decoration: InputDecoration(labelText: 'Fertilizers (liters)'),
              ),
              TextField(
                controller: pesticidesController,
                decoration: InputDecoration(labelText: 'Pesticides (liters)'),
              ),
              TextField(
                controller: waterController,
                decoration: InputDecoration(labelText: 'Water (liters)'),
              ),
              TextField(
                controller: electricityController,
                decoration: InputDecoration(labelText: 'Electricity (kWh)'),
              ),
              TextField(
                controller: totalPriceController,
                decoration: InputDecoration(labelText: 'Total Price (RM)'),
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
                // Save the edited data to Firestore
                await FirebaseFirestore.instance
                    .collection('farms')
                    .doc(userId)
                    .update({
                  'landSize': landSizeController.text,
                  'inventory.seeds': seedsController.text,
                  'inventory.fertilizers': fertilizersController.text,
                  'inventory.pesticides': pesticidesController.text,
                  'inventory.water': waterController.text,
                  'inventory.electricity': electricityController.text,
                  'inventory.totalPrice': totalPriceController.text,
                });

                Navigator.of(context).pop(); // Close the dialog
                _loadFarmData(); // Reload data to refresh the UI
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditDailyDataDialog(
      BuildContext context, String date, List<dynamic> updates) async {
    // Fetch the list of available plugs from Firestore
    DocumentSnapshot farmDoc =
        await FirebaseFirestore.instance.collection('farms').doc(userId).get();
    List<String> plugs = (farmDoc['plugs'] as List<dynamic>).cast<String>();

    // Create controllers for each field and populate with existing data
    final List<TextEditingController> vegFruitControllers = [];
    final List<String?> selectedPlugList = []; // List for selected plugs
    final List<TextEditingController> seedControllers = [];
    final List<TextEditingController> waterControllers = [];
    final List<TextEditingController> fertilizerControllers = [];
    final List<TextEditingController> pesticideControllers = [];

    for (var update in updates) {
      vegFruitControllers.add(
          TextEditingController(text: update['vegFruit']?.toString() ?? ''));
      selectedPlugList.add(update['plug']?.toString() ?? null);
      seedControllers
          .add(TextEditingController(text: update['seeds']?.toString() ?? ''));
      waterControllers
          .add(TextEditingController(text: update['water']?.toString() ?? ''));
      fertilizerControllers.add(
          TextEditingController(text: update['fertilizers']?.toString() ?? ''));
      pesticideControllers.add(
          TextEditingController(text: update['pesticides']?.toString() ?? ''));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Daily Data for $date'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(updates.length, (index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Update ${index + 1}"),

                    // Dropdown to select a plug
                    DropdownButtonFormField<String>(
                      value: selectedPlugList[index],
                      items: plugs.map((String plug) {
                        return DropdownMenuItem(value: plug, child: Text(plug));
                      }).toList(),
                      onChanged: (String? newValue) {
                        selectedPlugList[index] = newValue;
                      },
                      decoration: InputDecoration(labelText: 'Select Plug'),
                    ),

                    // Text field to edit vegetable/fruit name
                    TextField(
                      controller: vegFruitControllers[index],
                      decoration:
                          InputDecoration(labelText: 'Vegetable/Fruit Name'),
                    ),

                    TextField(
                      controller: seedControllers[index],
                      decoration: InputDecoration(labelText: 'Seeds (grams)'),
                    ),
                    TextField(
                      controller: waterControllers[index],
                      decoration: InputDecoration(labelText: 'Water (liters)'),
                    ),
                    TextField(
                      controller: fertilizerControllers[index],
                      decoration:
                          InputDecoration(labelText: 'Fertilizers (liters)'),
                    ),
                    TextField(
                      controller: pesticideControllers[index],
                      decoration:
                          InputDecoration(labelText: 'Pesticides (liters)'),
                    ),
                    const Divider(),
                  ],
                );
              }),
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
                // Build the updated list of updates
                List<Map<String, dynamic>> updatedDailyData = [];
                for (int i = 0; i < updates.length; i++) {
                  updatedDailyData.add({
                    'plug': selectedPlugList[i], // Store the selected plug
                    'vegFruit': vegFruitControllers[i]
                        .text, // Store the edited vegetable/fruit name
                    'seeds': seedControllers[i].text,
                    'water': waterControllers[i].text,
                    'fertilizers': fertilizerControllers[i].text,
                    'pesticides': pesticideControllers[i].text,
                  });
                }

                // Update Firestore with the new daily data
                await FirebaseFirestore.instance
                    .collection('farms')
                    .doc(userId)
                    .update({
                  'daily_usage.$date.updates': updatedDailyData,
                });

                Navigator.of(context).pop(); // Close the dialog
                _loadDailyUsageData(); // Reload data to refresh the UI
              },
            ),
          ],
        );
      },
    );
  }
}
