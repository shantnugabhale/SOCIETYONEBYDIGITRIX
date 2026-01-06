import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../services/feature_gating_service.dart';
import '../../models/society_model.dart';

class FeatureManagementScreen extends StatefulWidget {
  const FeatureManagementScreen({super.key});

  @override
  State<FeatureManagementScreen> createState() => _FeatureManagementScreenState();
}

class _FeatureManagementScreenState extends State<FeatureManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<SocietyModel> _societies = [];
  SocietyModel? _selectedSociety;
  Map<String, bool> _enabledFeatures = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSocieties();
  }

  Future<void> _loadSocieties() async {
    setState(() => _isLoading = true);
    try {
      final buildings = await _firestoreService.getAllBuildings();
      List<SocietyModel> allSocieties = [];
      for (var building in buildings) {
        final societies = await _firestoreService.getSocietiesByBuilding(building.id);
        allSocieties.addAll(societies);
      }
      setState(() {
        _societies = allSocieties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load societies: ${e.toString()}');
    }
  }

  Future<String?> _getBuildingName(String buildingId) async {
    try {
      final building = await _firestoreService.getBuildingById(buildingId);
      return building?.name;
    } catch (e) {
      return null;
    }
  }

  void _selectSociety(SocietyModel society) {
    setState(() {
      _selectedSociety = society;
      // Initialize enabled features from society or default to false
      _enabledFeatures = Map<String, bool>.from(society.enabledFeatures);
      // Ensure all master features are in the map
      final masterFeatures = FeatureGatingService.getAllFeatures();
      for (var featureKey in masterFeatures.keys) {
        _enabledFeatures.putIfAbsent(featureKey, () => false);
      }
    });
  }

  Future<void> _saveFeatures() async {
    if (_selectedSociety == null) return;

    setState(() => _isSaving = true);
    try {
      await _firestoreService.updateSocietyFeatures(
        _selectedSociety!.id,
        _enabledFeatures,
      );
      await _loadSocieties();
      if (_selectedSociety != null) {
        final updatedSociety = await _firestoreService.getSocietyById(_selectedSociety!.id);
        setState(() => _selectedSociety = updatedSociety);
      }
      Get.snackbar(
        'Success',
        'Features updated successfully',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update features: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Feature Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          if (_selectedSociety != null)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              onPressed: _isSaving ? null : _saveFeatures,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Society List
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      right: BorderSide(color: AppColors.grey300),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppStyles.spacing16),
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          'Select Society',
                          style: AppStyles.heading6.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _societies.length,
                          itemBuilder: (context, index) {
                            final society = _societies[index];
                            final isSelected = _selectedSociety?.id == society.id;
                            return ListTile(
                              selected: isSelected,
                              leading: Icon(
                                Icons.home_work_rounded,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                              title: Text(
                                society.name,
                                style: AppStyles.bodyMedium.copyWith(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    society.city,
                                    style: AppStyles.bodySmall,
                                  ),
                                  if (society.buildingId != null && society.buildingId!.isNotEmpty)
                                    FutureBuilder<String?>(
                                      future: _getBuildingName(society.buildingId!),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData && snapshot.data != null) {
                                          return Text(
                                            'Building: ${snapshot.data}',
                                            style: AppStyles.bodySmall.copyWith(
                                              color: AppColors.primary,
                                              fontSize: 11,
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                ],
                              ),
                              onTap: () => _selectSociety(society),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Feature List
                Expanded(
                  child: _selectedSociety == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.settings_rounded,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: AppStyles.spacing16),
                              Text(
                                'Select a Society',
                                style: AppStyles.heading5,
                              ),
                              const SizedBox(height: AppStyles.spacing8),
                              Text(
                                'Choose a society to manage features',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppStyles.spacing16),
                              color: AppColors.surface,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedSociety!.name,
                                    style: AppStyles.heading5.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _selectedSociety!.fullAddress,
                                    style: AppStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(AppStyles.spacing16),
                                children: [
                                  ...FeatureGatingService.getAllFeatures().entries.map((entry) {
                                    final featureKey = entry.key;
                                    final featureName = entry.value;
                                    final isEnabled = _enabledFeatures[featureKey] ?? false;

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
                                      child: SwitchListTile(
                                        title: Text(
                                          featureName,
                                          style: AppStyles.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Feature Key: $featureKey',
                                          style: AppStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        value: isEnabled,
                                        onChanged: (value) {
                                          setState(() {
                                            _enabledFeatures[featureKey] = value;
                                          });
                                        },
                                        secondary: Icon(
                                          isEnabled
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: isEnabled
                                              ? AppColors.success
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

