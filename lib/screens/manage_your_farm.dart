import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_app/utils/colors.dart';
import 'package:farm_app/widgets/CustomButton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManageYourFarm extends StatefulWidget {
  const ManageYourFarm({super.key});

  @override
  State<ManageYourFarm> createState() => _ManageYourFarmState();
}

class _ManageYourFarmState extends State<ManageYourFarm> {
  final TextEditingController landSizeController = TextEditingController();
  final TextEditingController plugsController = TextEditingController();
  final TextEditingController seedsController = TextEditingController();
  final TextEditingController fertilizersController = TextEditingController();
  final TextEditingController pesticidesController = TextEditingController();
  final TextEditingController waterController = TextEditingController();
  final TextEditingController electricityController = TextEditingController();

  String? selectedPlantType;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadFarmData();
  }

  Future<void> _loadFarmData() async {
    DocumentSnapshot farmDoc =
        await FirebaseFirestore.instance.collection('farms').doc(userId).get();

    if (farmDoc.exists) {
      var farmData = farmDoc.data() as Map<String, dynamic>;

      setState(() {
        landSizeController.text = farmData['landSize'] ?? '';
        plugsController.text = farmData['plugs']?.toString() ?? '';
        selectedPlantType = farmData['plantType'] ?? 'Aquaponic';
        seedsController.text = farmData['inventory']['seeds'] ?? '';
        fertilizersController.text = farmData['inventory']['fertilizers'] ?? '';
        pesticidesController.text = farmData['inventory']['pesticides'] ?? '';
        waterController.text = farmData['inventory']['water'] ?? '';
        electricityController.text = farmData['inventory']['electricity'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                height: 12,
                width: 40,
                margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
                color: AppColors.mainColor,
              ),
              Text(
                "Manage your farm",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 40),
          TextField(
            controller: landSizeController,
            cursorColor: AppColors.mainColor,
            decoration: InputDecoration(
              labelText: 'Land Size (Hectares)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: plugsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Number of Plugs',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedPlantType,
            items: [
              DropdownMenuItem(value: 'Aquaponic', child: Text('Aquaponic')),
              DropdownMenuItem(value: 'Hydroponic', child: Text('Hydroponic')),
              DropdownMenuItem(
                  value: 'Soiled Polybag', child: Text('Soiled Polybag')),
              DropdownMenuItem(
                  value: 'Conventional', child: Text('Conventional')),
            ],
            onChanged: (String? newValue) {
              setState(() {
                selectedPlantType = newValue;
              });
            },
            decoration: InputDecoration(
              labelText: 'Plant Type',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          SizedBox(height: 10),
          Text("Inventory",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          TextField(
            controller: seedsController,
            decoration: InputDecoration(
              labelText: 'Seeds (kg)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: fertilizersController,
            decoration: InputDecoration(
              labelText: 'Fertilizers (Liters)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: pesticidesController,
            decoration: InputDecoration(
              labelText: 'Pesticides (Liters)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: waterController,
            decoration: InputDecoration(
              labelText: 'Water (Liters)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: electricityController,
            decoration: InputDecoration(
              labelText: 'Electricity (kWh)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          SizedBox(height: 20),
          CustomButton(
            buttonText: 'Save Farm Data',
            textColor: Colors.white,
            backgroundColor: AppColors.mainColor,
            onPressed: () {
              saveFarmData();
            },
          ),
        ],
      ),
    );
  }

  Future<void> saveFarmData() async {
    try {
      // Save the farm data in Firestore
      await FirebaseFirestore.instance.collection('farms').doc(userId).set(
        {
          'landSize': landSizeController.text,
          'plugs': List.generate(
              int.parse(plugsController.text), (index) => 'Plug ${index + 1}'),
          'plantType': selectedPlantType,
          'inventory': {
            'seeds': seedsController.text,
            'fertilizers': fertilizersController.text,
            'pesticides': pesticidesController.text,
            'water': waterController.text,
            'electricity': electricityController.text,
          },
        },
        SetOptions(merge: true),
      );

      // Show success message
      Get.snackbar('Success', 'Farm data updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
      Get.offAllNamed('/home');
    } catch (e) {
      // Show error message
      Get.snackbar('Error', 'Failed to update farm data',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }
}
