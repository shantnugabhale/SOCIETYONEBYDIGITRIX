import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../models/society_model.dart';
import '../../models/user_model.dart';

class CommitteeAssignmentScreen extends StatefulWidget {
  const CommitteeAssignmentScreen({super.key});

  @override
  State<CommitteeAssignmentScreen> createState() => _CommitteeAssignmentScreenState();
}

class _CommitteeAssignmentScreenState extends State<CommitteeAssignmentScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<SocietyModel> _societies = [];
  SocietyModel? _selectedSociety;
  List<UserModel> _societyMembers = [];
  bool _isLoading = true;

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

  Future<void> _loadSocietyMembers(String societyId) async {
    try {
      final members = await _firestoreService.getAllMembers();
      final societyMembers = members
          .where((m) => m.societyId == societyId && m.approvalStatus == 'approved')
          .toList();
      setState(() => _societyMembers = societyMembers);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load members: ${e.toString()}');
    }
  }

  Future<void> _assignCommitteeMember(String role, String userId) async {
    if (_selectedSociety == null) return;

    try {
      await _firestoreService.assignCommitteeMember(
        _selectedSociety!.id,
        role,
        userId,
      );
      await _loadSocieties();
      if (_selectedSociety != null) {
        final updatedSociety = await _firestoreService.getSocietyById(_selectedSociety!.id);
        setState(() => _selectedSociety = updatedSociety);
      }
      Get.snackbar(
        'Success',
        'Committee member assigned successfully',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to assign: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _removeCommitteeMember(String role) async {
    if (_selectedSociety == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remove Committee Member'),
        content: Text('Remove $role from ${_selectedSociety!.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.removeCommitteeMember(_selectedSociety!.id, role);
      await _loadSocieties();
      if (_selectedSociety != null) {
        final updatedSociety = await _firestoreService.getSocietyById(_selectedSociety!.id);
        setState(() => _selectedSociety = updatedSociety);
      }
      Get.snackbar(
        'Success',
        'Committee member removed',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _showAssignDialog(String role) async {
    if (_selectedSociety == null) {
      Get.snackbar('Info', 'Please select a society first');
      return;
    }

    await _loadSocietyMembers(_selectedSociety!.id);

    final availableMembers = _societyMembers
        .where((m) => m.committeeRole == null || m.committeeRole != role)
        .toList();

    if (availableMembers.isEmpty) {
      Get.snackbar('Info', 'No available members for this role');
      return;
    }

    await Get.dialog(
      Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          padding: const EdgeInsets.all(AppStyles.spacing16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign $role',
                style: AppStyles.heading5.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppStyles.spacing16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableMembers.length,
                  itemBuilder: (context, index) {
                    final member = availableMembers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(member.name[0].toUpperCase()),
                      ),
                      title: Text(member.name),
                      subtitle: Text('${member.buildingName} - ${member.apartmentNumber}'),
                      onTap: () {
                        Get.back();
                        _assignCommitteeMember(role, member.id);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppStyles.spacing16),
              OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Committee Assignment'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Society Selection
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacing16),
                  color: AppColors.surface,
                  child: DropdownButtonFormField<SocietyModel>(
                    value: _selectedSociety,
                    decoration: const InputDecoration(
                      labelText: 'Select Society',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _societies.map((society) {
                      return DropdownMenuItem(
                        value: society,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(society.name),
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
                      );
                    }).toList(),
                    onChanged: (society) {
                      setState(() {
                        _selectedSociety = society;
                        if (society != null) {
                          _loadSocietyMembers(society.id);
                        }
                      });
                    },
                  ),
                ),

                // Committee Roles
                if (_selectedSociety != null)
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppStyles.spacing16),
                      children: [
                        _buildCommitteeRoleCard(
                          'Chairman',
                          _selectedSociety!.committeeMembers['chairman'],
                        ),
                        const SizedBox(height: AppStyles.spacing12),
                        _buildCommitteeRoleCard(
                          'Secretary',
                          _selectedSociety!.committeeMembers['secretary'],
                        ),
                        const SizedBox(height: AppStyles.spacing12),
                        _buildCommitteeRoleCard(
                          'Treasurer',
                          _selectedSociety!.committeeMembers['treasurer'],
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Text(
                        'Please select a society',
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCommitteeRoleCard(String role, String? userId) {
    final isAssigned = userId != null && userId.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: isAssigned ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(width: AppStyles.spacing12),
                Expanded(
                  child: Text(
                    role.toUpperCase(),
                    style: AppStyles.heading6.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isAssigned)
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: AppColors.error),
                    onPressed: () => _removeCommitteeMember(role.toLowerCase()),
                    tooltip: 'Remove',
                  ),
              ],
            ),
            const SizedBox(height: AppStyles.spacing12),
            if (isAssigned)
              FutureBuilder<UserModel?>(
                future: _firestoreService.getMemberProfile(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  final member = snapshot.data;
                  if (member == null) {
                    return Text(
                      'Member not found',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${member.buildingName} - ${member.apartmentNumber}',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              ElevatedButton.icon(
                onPressed: () => _showAssignDialog(role.toLowerCase()),
                icon: const Icon(Icons.person_add_rounded),
                label: Text('Assign $role'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

