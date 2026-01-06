import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../models/building_model.dart';
import '../../widgets/card_widget.dart';
import '../../widgets/input_field.dart';

/// Building Selection Screen
/// First step in signup flow - User selects building
/// Then societies within that building will be shown
class BuildingSelectionScreen extends StatefulWidget {
  const BuildingSelectionScreen({super.key});

  @override
  State<BuildingSelectionScreen> createState() => _BuildingSelectionScreenState();
}

class _BuildingSelectionScreenState extends State<BuildingSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<BuildingModel> _buildings = [];
  List<BuildingModel> _filteredBuildings = [];
  bool _isLoading = false;
  String _searchType = 'name'; // 'name', 'city', 'pinCode'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAllBuildings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllBuildings() async {
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

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredBuildings = _buildings);
      return;
    }

    setState(() {
      _filteredBuildings = _buildings.where((building) {
        switch (_searchType) {
          case 'name':
            return building.name.toLowerCase().contains(query);
          case 'city':
            return building.city.toLowerCase().contains(query);
          case 'pinCode':
            return building.pinCode.contains(query);
          default:
            return false;
        }
      }).toList();
    });
  }

  void _selectBuilding(BuildingModel building) {
    // Navigate to society selection with buildingId
    Get.toNamed('/society-selection', arguments: building.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Building'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(AppStyles.spacing16),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Type Selector
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Name'),
                        selected: _searchType == 'name',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _searchType = 'name');
                            _onSearchChanged();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacing8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('City'),
                        selected: _searchType == 'city',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _searchType = 'city');
                            _onSearchChanged();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacing8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('PIN Code'),
                        selected: _searchType == 'pinCode',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _searchType = 'pinCode');
                            _onSearchChanged();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacing12),
                // Search Field
                CustomInputField(
                  label: 'Search Building',
                  hint: 'Enter ${_searchType == 'name' ? 'building name' : _searchType == 'city' ? 'city name' : 'PIN code'}',
                  controller: _searchController,
                  prefixIcon: const Icon(Icons.search_rounded),
                  textInputAction: TextInputAction.search,
                ),
              ],
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
                              _searchController.text.trim().isEmpty
                                  ? 'No Buildings Found'
                                  : 'No Buildings Match Your Search',
                              style: AppStyles.heading5,
                            ),
                            const SizedBox(height: AppStyles.spacing8),
                            Text(
                              _searchController.text.trim().isEmpty
                                  ? 'Buildings will appear here once added by Super Admin'
                                  : 'Try a different search term',
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppStyles.spacing16),
                        itemCount: _filteredBuildings.length,
                        itemBuilder: (context, index) {
                          final building = _filteredBuildings[index];
                          return CustomCard(
                            margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
                            child: InkWell(
                              onTap: () => _selectBuilding(building),
                              borderRadius: BorderRadius.circular(AppStyles.radius12),
                              child: Padding(
                                padding: const EdgeInsets.all(AppStyles.spacing16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppStyles.radius12),
                                      ),
                                      child: Icon(
                                        Icons.business_rounded,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: AppStyles.spacing16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            building.name,
                                            style: AppStyles.heading6.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: AppStyles.spacing4),
                                          Text(
                                            building.fullAddress,
                                            style: AppStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

