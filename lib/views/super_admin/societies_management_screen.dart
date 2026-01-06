import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../models/society_model.dart';
import '../../models/building_model.dart';
import '../../widgets/input_field.dart';

class SocietiesManagementScreen extends StatefulWidget {
  const SocietiesManagementScreen({super.key});

  @override
  State<SocietiesManagementScreen> createState() => _SocietiesManagementScreenState();
}

class _SocietiesManagementScreenState extends State<SocietiesManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  
  List<BuildingModel> _buildings = [];
  List<SocietyModel> _societies = [];
  String? _selectedBuildingId;
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final buildings = await _firestoreService.getAllBuildings();
      List<SocietyModel> allSocieties = [];
      for (var building in buildings) {
        final societies = await _firestoreService.getSocietiesByBuilding(building.id);
        allSocieties.addAll(societies);
      }
      setState(() {
        _buildings = buildings;
        _societies = allSocieties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load data: ${e.toString()}');
    }
  }

  Future<void> _showAddSocietyDialog() async {
    if (_buildings.isEmpty) {
      Get.snackbar('Info', 'Please add a building first');
      return;
    }

    _nameController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _pinCodeController.clear();
    _selectedBuildingId = _buildings.first.id;

    await Get.dialog(
      Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(AppStyles.spacing24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Society',
                    style: AppStyles.heading4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing24),
                  DropdownButtonFormField<String>(
                    value: _selectedBuildingId,
                    decoration: const InputDecoration(
                      labelText: 'Building *',
                      border: OutlineInputBorder(),
                    ),
                    items: _buildings.map((building) {
                      return DropdownMenuItem(
                        value: building.id,
                        child: Text(building.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedBuildingId = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a building';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppStyles.spacing16),
                  CustomInputField(
                    label: 'Society Name',
                    controller: _nameController,
                    isRequired: true,
                  ),
                  const SizedBox(height: AppStyles.spacing16),
                  CustomInputField(
                    label: 'Address',
                    controller: _addressController,
                    isRequired: true,
                  ),
                  const SizedBox(height: AppStyles.spacing16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomInputField(
                          label: 'City',
                          controller: _cityController,
                          isRequired: true,
                        ),
                      ),
                      const SizedBox(width: AppStyles.spacing12),
                      Expanded(
                        child: CustomInputField(
                          label: 'State',
                          controller: _stateController,
                          isRequired: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.spacing16),
                  CustomInputField(
                    label: 'PIN Code',
                    controller: _pinCodeController,
                    keyboardType: TextInputType.number,
                    isRequired: true,
                  ),
                  const SizedBox(height: AppStyles.spacing24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppStyles.spacing12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isAdding ? null : _addSociety,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: _isAdding
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addSociety() async {
    if (!_formKey.currentState!.validate() || _selectedBuildingId == null) return;

    setState(() => _isAdding = true);
    try {
      final society = SocietyModel(
        id: '', // Will be generated by Firestore
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
        buildingId: _selectedBuildingId,
        enabledFeatures: {}, // Empty initially, can be configured later
        committeeMembers: {}, // Empty initially, can be assigned later
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createSociety(society);
      Get.back(); // Close dialog
      _loadData();
      Get.snackbar(
        'Success',
        'Society added successfully',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add society: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Societies Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _societies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_work_rounded,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppStyles.spacing16),
                      Text(
                        'No Societies',
                        style: AppStyles.heading5,
                      ),
                      const SizedBox(height: AppStyles.spacing8),
                      Text(
                        'Add your first society',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppStyles.spacing16),
                  itemCount: _societies.length,
                  itemBuilder: (context, index) {
                    final society = _societies[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.home_work_rounded,
                            color: AppColors.secondary,
                          ),
                        ),
                        title: Text(
                          society.name,
                          style: AppStyles.heading6.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(society.fullAddress),
                        trailing: society.isActive
                            ? Icon(Icons.check_circle, color: AppColors.success)
                            : Icon(Icons.cancel, color: AppColors.error),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSocietyDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Society'),
      ),
    );
  }
}

