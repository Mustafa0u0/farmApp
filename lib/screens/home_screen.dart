import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_app/screens/export_data_screen.dart';
import 'package:farm_app/screens/daily_screen.dart';
import 'package:farm_app/screens/inventory_screen.dart';
import 'package:farm_app/screens/profile_screen.dart';
import 'package:farm_app/screens/sales_screen.dart';
import 'package:farm_app/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart'; // For financial charting
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage for image upload
import 'package:image_picker/image_picker.dart'; // Image Picker
import 'dart:io'; // For File handling
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
  File? _selectedImage; // For storing the selected image
  final picker = ImagePicker(); // For image picking

  // Financial fields
  double totalIncome = 0.0; // From sales
  double totalExpenses = 0.0; // From inventory (totalPrice)
  double profit = 0.0; // Profit = Income - Expenses

  // Chart data for financial overview
  List<FinancialData> financialData = [];

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
        _prepareFinancialChartData(); // Prepare data for the financial chart
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
        _prepareFinancialChartData(); // Prepare data for the financial chart
      });
    }
  }

  // Prepare data for the financial chart
  void _prepareFinancialChartData() {
    setState(() {
      financialData = [
        FinancialData('Income', totalIncome),
        FinancialData('Expenses', totalExpenses),
        FinancialData('Profit', profit),
      ];
    });
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
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
              ),
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshPage,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.mainColor),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 120,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sell),
              title: const Text('Sales'),
              onTap: () {
                Get.to(() => SalesScreen()); // Navigate to Sales Page
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Daily Updates'),
              onTap: () {
                Get.to(() =>
                    DailyUpdatesPage()); // Navigate to Monthly Updates Page
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Inventory'),
              onTap: () {
                Get.to(() => InventoryScreen()); // Navigate to Inventory Page
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              onTap: () {
                Get.to(() => ExportDataScreen()); // Navigate to Export Page
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Get.to(() => ProfileScreen()); // Navigate to Profile Page
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Get.offAllNamed('/welcome'); // Redirect to the welcome page
              },
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            width: double.infinity,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_pin,
                        color: Colors.white, size: 20),
                    Text("Malaysia, $userLocation",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                      "Today, ${DateTime.now().day} ${DateFormat.MMMM().format(DateTime.now())}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 700,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("Monthly Activity Monitor",
                      style: TextStyle(color: Colors.black, fontSize: 20)),
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
                          Text("Month: ${_getCurrentMonth()}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
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
                              "Total Price (RM): ${monthlyUsage['inventory']?['totalPrice']?.toString() ?? 'N/A'} RM"),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showEditMonthlyDataDialog(
                                    context); // Open monthly data edit dialog
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ), // Daily Activity Monitor with Edit Button
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
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
                                    if (update.containsKey('imageUrl'))
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Image.network(
                                          update['imageUrl'],
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
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

                  const Text("Financial Overview",
                      style: TextStyle(color: Colors.black, fontSize: 20)),
                  _buildFinancialChart(), // Display the financial chart
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
                          const Text("Total Income",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("RM ${totalIncome.toStringAsFixed(2)}"),
                          const Text("Total Expenses",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("RM ${totalExpenses.toStringAsFixed(2)}"),
                          const Text("Profit",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("RM ${profit.toStringAsFixed(2)}"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 100)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showDailyUsageForm(context);
        },
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: AppColors.mainColor,
      ),
    );
  }

  Widget _buildFinancialChart() {
    return Container(
      height: 400,
      width: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        title: ChartTitle(text: 'Financial Overview'),
        legend: Legend(isVisible: true),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries>[
          ColumnSeries<FinancialData, String>(
            dataSource: financialData,
            xValueMapper: (FinancialData data, _) => data.category,
            yValueMapper: (FinancialData data, _) => data.amount,
            name: 'Amount (RM)',
            dataLabelSettings: DataLabelSettings(isVisible: true),
          )
        ],
      ),
    );
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
          title: const Text('Edit Monthly Data'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: landSizeController,
                  decoration:
                      const InputDecoration(labelText: 'Land Size (hectares)'),
                ),
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
                TextField(
                  controller: electricityController,
                  decoration:
                      const InputDecoration(labelText: 'Electricity (kWh)'),
                ),
                TextField(
                  controller: totalPriceController,
                  decoration:
                      const InputDecoration(labelText: 'Total Price (RM)'),
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
    final List<String?> selectedPlugList = [];
    final List<TextEditingController> seedControllers = [];
    final List<TextEditingController> waterControllers = [];
    final List<TextEditingController> fertilizerControllers = [];
    final List<TextEditingController> pesticideControllers = [];
    final List<File?> updatedImages = [];
    final picker = ImagePicker(); // For picking the image

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
      updatedImages.add(null); // Placeholder for updated images
    }

    // Function to pick and update images
    Future<void> _pickUpdatedImage(int index) async {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          updatedImages[index] = File(pickedFile.path);
        });
      }
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
                    // Display existing image if available
                    if (updates[index].containsKey('imageUrl'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.network(
                          updates[index]['imageUrl'],
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    // Button to select a new image
                    ElevatedButton(
                      onPressed: () {
                        _pickUpdatedImage(index);
                      },
                      child: const Text("Change Image"),
                    ),
                    if (updatedImages[index] != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(updatedImages[index]!, height: 200),
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
                List<Map<String, dynamic>> updatedDailyData = [];
                for (int i = 0; i < updates.length; i++) {
                  String? imageUrl = updates[i]['imageUrl'];

                  // If a new image is selected, upload and get the new URL
                  if (updatedImages[i] != null) {
                    imageUrl = await _uploadImage(updatedImages[i]!);
                  }

                  updatedDailyData.add({
                    'plug': selectedPlugList[i],
                    'vegFruit': vegFruitControllers[i].text,
                    'seeds': seedControllers[i].text,
                    'water': waterControllers[i].text,
                    'fertilizers': fertilizerControllers[i].text,
                    'pesticides': pesticideControllers[i].text,
                    if (imageUrl != null)
                      'imageUrl': imageUrl, // Update the image
                  });
                }

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
    String? imageUrl;

    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!); // Upload the image
    }

    try {
      DocumentSnapshot farmDoc = await FirebaseFirestore.instance
          .collection('farms')
          .doc(userId)
          .get();
      List<dynamic> existingUpdates = [];

      if (farmDoc.exists &&
          (farmDoc.data() as Map<String, dynamic>).containsKey('daily_usage')) {
        var dailyUsageData = (farmDoc['daily_usage'] as Map<String, dynamic>);
        if (dailyUsageData.containsKey(today)) {
          existingUpdates =
              dailyUsageData[today]['updates'] as List<dynamic>? ?? [];
        }
      }

      existingUpdates.add({
        'plug': plug,
        'vegFruit': vegFruit,
        'seeds': seeds,
        'water': water,
        'fertilizers': fertilizers,
        'pesticides': pesticides,
        if (imageUrl != null) 'imageUrl': imageUrl, // Add image URL if present
      });

      await FirebaseFirestore.instance.collection('farms').doc(userId).set(
        {
          'daily_usage': {
            today: {
              'updates': existingUpdates,
            }
          }
        },
        SetOptions(merge: true),
      );

      Get.snackbar('Success', 'Daily usage saved successfully',
          backgroundColor: Colors.green, colorText: Colors.white);

      _loadDailyUsageData(); // Reload the data
    } catch (e) {
      Get.snackbar('Error', 'Failed to save daily usage',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _showDailyUsageForm(BuildContext context) async {
    DocumentSnapshot farmDoc =
        await FirebaseFirestore.instance.collection('farms').doc(userId).get();
    List<String> plugs = (farmDoc['plugs'] as List<dynamic>).cast<String>();

    final TextEditingController seedsController = TextEditingController();
    final TextEditingController waterController = TextEditingController();
    final TextEditingController fertilizersController = TextEditingController();
    final TextEditingController pesticidesController = TextEditingController();
    final TextEditingController vegFruitController = TextEditingController();
    String? selectedPlug;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Daily Usage'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  decoration:
                      InputDecoration(labelText: 'Vegetable/Fruit Name'),
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
                  decoration:
                      InputDecoration(labelText: 'Fertilizers (liters)'),
                ),
                TextField(
                  controller: pesticidesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Pesticides (liters)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text("Upload Image"),
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.file(_selectedImage!, height: 200),
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

  // Image picker function
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = pickedFile != null ? File(pickedFile.path) : null;
    });
  }

  // Upload image to Firebase Storage and get the URL
  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef =
          FirebaseStorage.instance.ref().child("daily_images/$fileName");
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}

class FinancialData {
  final String category;
  final double amount;

  FinancialData(this.category, this.amount);
}
