import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_app/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage for image upload
import 'package:image_picker/image_picker.dart'; // Image Picker
import 'dart:io'; // For File handling

class DailyUpdatesPage extends StatefulWidget {
  @override
  _DailyUpdatesPageState createState() => _DailyUpdatesPageState();
}

class _DailyUpdatesPageState extends State<DailyUpdatesPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic> dailyUsageData = {};
  File? _selectedImage; // For storing the selected image
  final picker = ImagePicker(); // For image picking

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
        title: Text(
          'Daily Report',
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
              _loadDailyUsageData(); // Refresh the data
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showDailyUsageForm(context);
        },
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: AppColors.mainColor,
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
                                padding: const EdgeInsets.only(top: 8.0),
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
        ],
      ),
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
}
