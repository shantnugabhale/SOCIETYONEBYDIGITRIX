import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  List<UserModel> _members = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final firestoreService = FirestoreService();
      final members = await firestoreService.getAllMembers();
      
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      Get.snackbar(
        'Error',
        'Failed to load members: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textOnPrimary,
      );
    }
  }

  List<UserModel> get _filteredMembers {
    if (_searchQuery.isEmpty) {
      return _members;
    }
    
    final query = _searchQuery.toLowerCase();
    return _members.where((member) {
      return member.name.toLowerCase().contains(query) ||
          member.mobileNumber.contains(query) ||
          member.email.toLowerCase().contains(query) ||
          member.apartmentNumber.toLowerCase().contains(query) ||
          member.buildingName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Member Management',
          style: AppStyles.heading6.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppStyles.spacing16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, email, or flat number...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radius12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Members List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppStyles.spacing16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No members found'
                                  : 'No members registered yet',
                              style: AppStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMembers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppStyles.spacing16),
                          itemCount: _filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = _filteredMembers[index];
                            return CustomCard(
                              margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(AppStyles.spacing16),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  member.name,
                                  style: AppStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: AppStyles.spacing4),
                                    Text(
                                      'Phone: ${member.mobileNumber}',
                                      style: AppStyles.bodySmall,
                                    ),
                                    Text(
                                      'Email: ${member.email}',
                                      style: AppStyles.bodySmall,
                                    ),
                                    Text(
                                      'Flat ${member.apartmentNumber}, ${member.buildingName}',
                                      style: AppStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: member.isActive
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppStyles.spacing12,
                                          vertical: AppStyles.spacing4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(AppStyles.radius8),
                                        ),
                                        child: Text(
                                          'Active',
                                          style: AppStyles.bodySmall.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppStyles.spacing12,
                                          vertical: AppStyles.spacing4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(AppStyles.radius8),
                                        ),
                                        child: Text(
                                          'Inactive',
                                          style: AppStyles.bodySmall.copyWith(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

