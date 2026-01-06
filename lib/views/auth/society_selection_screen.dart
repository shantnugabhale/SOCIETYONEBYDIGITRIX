import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../models/society_model.dart';
import '../../models/building_model.dart';
import '../../widgets/card_widget.dart';
import '../../widgets/input_field.dart';

class SocietySelectionScreen extends StatefulWidget {
  const SocietySelectionScreen({super.key});

  @override
  State<SocietySelectionScreen> createState() => _SocietySelectionScreenState();
}

class _SocietySelectionScreenState extends State<SocietySelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<SocietyModel> _societies = [];
  List<SocietyModel> _filteredSocieties = [];
  BuildingModel? _selectedBuilding;
  String? _buildingId;
  bool _isLoading = false;
  String _searchType = 'name'; // 'name', 'city', 'pinCode'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Get buildingId from arguments
    final args = Get.arguments;
    if (args != null && args is String) {
      _buildingId = args;
      _loadBuildingAndSocieties();
    } else {
      // No building selected - redirect to building selection
      Get.offNamed('/building-selection');
    }
  }

  Future<void> _loadBuildingAndSocieties() async {
    if (_buildingId == null) return;
    
    setState(() => _isLoading = true);
    try {
      // Load building details
      final building = await _firestoreService.getBuildingById(_buildingId!);
      if (building == null) {
        Get.snackbar('Error', 'Building not found');
        Get.offNamed('/building-selection');
        return;
      }
      
      // Load societies within this building
      final societies = await _firestoreService.getSocietiesByBuilding(_buildingId!);
      
      setState(() {
        _selectedBuilding = building;
        _societies = societies;
        _filteredSocieties = societies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load societies: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _filteredSocieties = _societies);
      return;
    }

    setState(() {
      _filteredSocieties = _societies.where((society) {
        switch (_searchType) {
          case 'name':
            return society.name.toLowerCase().contains(query.toLowerCase());
          case 'city':
            return society.city.toLowerCase().contains(query.toLowerCase());
          case 'pinCode':
            return society.pinCode.contains(query);
          default:
            return false;
        }
      }).toList();
    });
  }

  // Local search only - no need for API call since we already have societies from building
  void _searchSocieties() {
    // Search is handled by _onSearchChanged listener
    // This method is kept for compatibility but does local filtering
  }

  void _selectSociety(SocietyModel society) {
    Get.toNamed('/unit-selection', arguments: society);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Your Society'),
            if (_selectedBuilding != null)
              Text(
                _selectedBuilding!.name,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Type Selector
            Container(
              padding: const EdgeInsets.all(AppStyles.spacing12),
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(AppStyles.radius12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSearchTypeChip('name', 'Name'),
                  ),
                  const SizedBox(width: AppStyles.spacing8),
                  Expanded(
                    child: _buildSearchTypeChip('city', 'City'),
                  ),
                  const SizedBox(width: AppStyles.spacing8),
                  Expanded(
                    child: _buildSearchTypeChip('pinCode', 'PIN Code'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppStyles.spacing16),

            // Search Input (Local search only)
            CustomInputField(
              controller: _searchController,
              hint: _getSearchHint(),
              prefixIcon: const Icon(Icons.search_rounded),
              label: 'Search Society',
            ),
            const SizedBox(height: AppStyles.spacing24),

            // Results
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppStyles.spacing32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredSocieties.isEmpty && _societies.isEmpty)
              Center(
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
                      'No Societies Found',
                      style: AppStyles.heading5,
                    ),
                    const SizedBox(height: AppStyles.spacing8),
                    Text(
                      _selectedBuilding != null
                          ? 'No societies found in ${_selectedBuilding!.name}'
                          : 'No societies available',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppStyles.spacing16),
                    if (_selectedBuilding != null)
                      TextButton.icon(
                        onPressed: () => Get.offNamed('/building-selection'),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Select Different Building'),
                      ),
                  ],
                ),
              )
            else
              ..._filteredSocieties.map((society) => _buildSocietyCard(society)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTypeChip(String type, String label) {
    final isSelected = _searchType == type;
    return InkWell(
      onTap: () {
        setState(() => _searchType = type);
        _onSearchChanged();
      },
      borderRadius: BorderRadius.circular(AppStyles.radius8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacing12,
          vertical: AppStyles.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppStyles.radius8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getSearchHint() {
    switch (_searchType) {
      case 'name':
        return 'Enter society name';
      case 'city':
        return 'Enter city name';
      case 'pinCode':
        return 'Enter PIN code';
      default:
        return 'Search...';
    }
  }

  Widget _buildSocietyCard(SocietyModel society) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
      onTap: () => _selectSociety(society),
      isClickable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius12),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppStyles.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      society.name,
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing4),
                    Text(
                      society.fullAddress,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          if (society.totalUnits > 0) ...[
            const SizedBox(height: AppStyles.spacing12),
            Row(
              children: [
                Icon(
                  Icons.home_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppStyles.spacing8),
                Text(
                  '${society.totalUnits} units',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (society.blocks.isNotEmpty) ...[
                  const SizedBox(width: AppStyles.spacing16),
                  Icon(
                    Icons.business_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppStyles.spacing8),
                  Text(
                    '${society.blocks.length} blocks',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

