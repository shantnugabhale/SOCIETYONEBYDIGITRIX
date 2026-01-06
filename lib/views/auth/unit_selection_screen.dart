import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../models/society_model.dart';
import '../../widgets/card_widget.dart';
import '../../widgets/input_field.dart';

class UnitSelectionScreen extends StatefulWidget {
  const UnitSelectionScreen({super.key});

  @override
  State<UnitSelectionScreen> createState() => _UnitSelectionScreenState();
}

class _UnitSelectionScreenState extends State<UnitSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  
  SocietyModel? _society;
  List<String> _availableBlocks = [];
  List<UnitModel> _availableUnits = [];
  String? _selectedBlock;
  UnitModel? _selectedUnit;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _society = Get.arguments as SocietyModel?;
    if (_society != null) {
      _loadSocietyData();
    }
  }

  @override
  void dispose() {
    _blockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _loadSocietyData() async {
    if (_society == null) return;

    setState(() => _isLoading = true);

    try {
      // Load blocks from society
      _availableBlocks = _society!.blocks;

      // Load units
      final units = await _firestoreService.getSocietyUnits(
        societyId: _society!.id,
      );

      setState(() {
        _availableUnits = units;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load data: ${e.toString()}');
    }
  }

  void _onBlockChanged(String? block) {
    setState(() {
      _selectedBlock = block;
      _selectedUnit = null;
      _unitController.clear();
    });
    _loadUnitsForBlock(block);
  }

  Future<void> _loadUnitsForBlock(String? block) async {
    if (_society == null || block == null) return;

    setState(() => _isLoading = true);

    try {
      final units = await _firestoreService.getSocietyUnits(
        societyId: _society!.id,
        block: block,
      );

      setState(() {
        _availableUnits = units;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _selectUnit(UnitModel unit) {
    setState(() {
      _selectedUnit = unit;
      _unitController.text = unit.fullAddress;
    });
  }

  void _proceedToRoleSelection() {
    if (_society == null || _selectedUnit == null) {
      Get.snackbar('Error', 'Please select a unit');
      return;
    }

    Get.toNamed('/role-selection', arguments: {
      'society': _society,
      'unit': _selectedUnit,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Your Unit'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: _society == null
          ? const Center(child: Text('Society not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppStyles.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Society Info Card
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.apartment_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppStyles.spacing12),
                            Expanded(
                              child: Text(
                                _society!.name,
                                style: AppStyles.heading6.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppStyles.spacing8),
                        Text(
                          _society!.fullAddress,
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing24),

                  // Block Selection
                  if (_availableBlocks.isNotEmpty) ...[
                    Text(
                      'Select Block/Wing',
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBlock,
                      decoration: const InputDecoration(
                        labelText: 'Block/Wing',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                      items: _availableBlocks.map((block) {
                        return DropdownMenuItem(
                          value: block,
                          child: Text(block),
                        );
                      }).toList(),
                      onChanged: _onBlockChanged,
                    ),
                    const SizedBox(height: AppStyles.spacing24),
                  ] else ...[
                    CustomInputField(
                      controller: _blockController,
                      hint: 'Enter Block/Wing',
                      prefixIcon: const Icon(Icons.business_rounded),
                    ),
                    const SizedBox(height: AppStyles.spacing16),
                  ],

                  // Unit Selection
                  Text(
                    'Select Flat/Unit',
                    style: AppStyles.heading6.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing12),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppStyles.spacing32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_availableUnits.isEmpty && _selectedBlock != null)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.home_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppStyles.spacing16),
                          Text(
                            'No units found',
                            style: AppStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_availableUnits.isEmpty)
                    CustomInputField(
                      controller: _unitController,
                      hint: 'Enter Flat/Unit Number',
                      prefixIcon: const Icon(Icons.home_rounded),
                    )
                  else
                    ..._availableUnits.map((unit) => _buildUnitCard(unit)),

                  const SizedBox(height: AppStyles.spacing32),

                  // Proceed Button
                  ElevatedButton(
                    onPressed: _selectedUnit != null || _unitController.text.isNotEmpty
                        ? _proceedToRoleSelection
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppStyles.spacing16,
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUnitCard(UnitModel unit) {
    final isSelected = _selectedUnit?.id == unit.id;
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
      onTap: () => _selectUnit(unit),
      isClickable: true,
      child: Container(
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          borderRadius: BorderRadius.circular(AppStyles.radius12),
        ),
        padding: const EdgeInsets.all(AppStyles.spacing12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacing8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppStyles.radius8),
              ),
              child: Icon(
                Icons.home_rounded,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppStyles.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.fullAddress,
                    style: AppStyles.heading6.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.floorNumber.isNotEmpty) ...[
                    const SizedBox(height: AppStyles.spacing4),
                    Text(
                      'Floor: ${unit.floorNumber}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

