import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../models/building_model.dart';
import '../../widgets/input_field.dart';

class BuildingsManagementScreen extends StatefulWidget {
  const BuildingsManagementScreen({super.key});

  @override
  State<BuildingsManagementScreen> createState() => _BuildingsManagementScreenState();
}

class _BuildingsManagementScreenState extends State<BuildingsManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  
  final TextEditingController _searchController = TextEditingController();
  List<BuildingModel> _buildings = [];
  List<BuildingModel> _filteredBuildings = [];
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadBuildings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredBuildings = _buildings);
      return;
    }

    setState(() {
      _filteredBuildings = _buildings.where((building) {
        return building.name.toLowerCase().contains(query) ||
               building.city.toLowerCase().contains(query) ||
               building.pinCode.contains(query) ||
               building.address.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadBuildings() async {
    setState(() => _isLoading = true);
    try {
      final buildings = await _firestoreService.getAllBuildings();
      setState(() {
        _buildings = buildings;
        _filteredBuildings = buildings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load buildings: ${e.toString()}');
    }
  }

  Future<void> _showAddBuildingDialog() async {
    _nameController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _pinCodeController.clear();
    _contactController.clear();
    _emailController.clear();

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
                    'Add Building',
                    style: AppStyles.heading4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing24),
                  CustomInputField(
                    label: 'Building Name',
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
                  const SizedBox(height: AppStyles.spacing16),
                  CustomInputField(
                    label: 'Contact Number (Optional)',
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppStyles.spacing16),
                  CustomInputField(
                    label: 'Email (Optional)',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
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
                          onPressed: _isAdding ? null : _addBuilding,
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

  Future<void> _addBuilding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAdding = true);
    try {
      final building = BuildingModel(
        id: '', // Will be generated by Firestore
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
        contactNumber: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createBuilding(building);
      Get.back(); // Close dialog
      _loadBuildings();
      Get.snackbar(
        'Success',
        'Building added successfully',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add building: ${e.toString()}',
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
        title: const Text('Buildings Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppStyles.spacing16),
            color: AppColors.surface,
            child: CustomInputField(
              label: 'Search Buildings',
              hint: 'Search by name, city, PIN code, or address',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          // Buildings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBuildings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_rounded,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppStyles.spacing16),
                      Text(
                        'No Buildings',
                        style: AppStyles.heading5,
                      ),
                      const SizedBox(height: AppStyles.spacing8),
                      Text(
                        'Add your first building',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppStyles.spacing16),
                  itemCount: _filteredBuildings.length,
                  itemBuilder: (context, index) {
                    final building = _filteredBuildings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.business_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          building.name,
                          style: AppStyles.heading6.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(building.fullAddress),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_city_rounded, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  building.city,
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.pin_rounded, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  building.pinCode,
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            building.isActive
                                ? Icon(Icons.check_circle, color: AppColors.success)
                                : Icon(Icons.cancel, color: AppColors.error),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded),
                              onPressed: () {
                                // TODO: Implement edit functionality
                                Get.snackbar('Info', 'Edit functionality coming soon');
                              },
                              tooltip: 'Edit Building',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBuildingDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Building'),
      ),
    );
  }
}

