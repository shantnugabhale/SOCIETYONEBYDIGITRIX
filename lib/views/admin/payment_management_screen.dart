import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/utility_model.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  
  List<UserModel> _allMembers = [];
  bool _isSearchActive = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Data grouped by member
  Map<String, List<UtilityModel>> _pendingBillsByMember = {};
  Map<String, List<PaymentModel>> _completedPaymentsByMember = {};
  Map<String, List<UtilityModel>> _overdueBillsByMember = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _firestoreService.getAllUtilityBills(),
        _loadAllPayments(),
        _firestoreService.getAllMembers(),
      ]);

      final bills = results[0] as List<UtilityModel>;
      final payments = results[1] as List<PaymentModel>;
      final members = results[2] as List<UserModel>;

      final now = DateTime.now();
      
      // Create a map of userId to member info
      final memberMap = <String, UserModel>{};
      for (var member in members) {
        memberMap[member.id] = member;
      }

      // Group bills by member (check who hasn't paid)
      final pendingBillsByMember = <String, List<UtilityModel>>{};
      final overdueBillsByMember = <String, List<UtilityModel>>{};
      
      for (var bill in bills) {
        if (bill.status == 'cancelled') continue;
        
        // Check all members who haven't paid this bill
        for (var member in members) {
          if (!bill.hasPaidBy(member.id)) {
            if (bill.dueDate.isAfter(now)) {
              // Pending
              pendingBillsByMember.putIfAbsent(member.id, () => []).add(bill);
            } else {
              // Overdue
              overdueBillsByMember.putIfAbsent(member.id, () => []).add(bill);
            }
          }
        }
      }

      // Group completed payments by member
      final completedPaymentsByMember = <String, List<PaymentModel>>{};
      for (var payment in payments) {
        if (payment.status == 'success') {
          completedPaymentsByMember.putIfAbsent(
            payment.userId,
            () => [],
          ).add(payment);
        }
      }

      setState(() {
        _allMembers = members;
        _pendingBillsByMember = pendingBillsByMember;
        _completedPaymentsByMember = completedPaymentsByMember;
        _overdueBillsByMember = overdueBillsByMember;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load payment data: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<List<PaymentModel>> _loadAllPayments() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('payments')
          .orderBy('paidDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            final model = PaymentModel.fromMap(Map<String, dynamic>.from(data));
            return model.copyWith(id: doc.id);
          })
          .toList();
    } catch (e) {
      return [];
    }
  }

  String _getMemberDisplayName(String userId) {
    final member = _allMembers.firstWhere(
      (m) => m.id == userId,
      orElse: () => UserModel(
        id: userId,
        email: '',
        name: 'Unknown Member',
        mobileNumber: '',
        role: 'member',
        apartmentNumber: '',
        buildingName: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    if (member.apartmentNumber.isNotEmpty && member.buildingName.isNotEmpty) {
      return '${member.name} - Flat ${member.apartmentNumber}, ${member.buildingName}';
    } else if (member.apartmentNumber.isNotEmpty) {
      return '${member.name} - Flat ${member.apartmentNumber}';
    }
    return member.name;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Get all matching member IDs based on search query
  Set<String> get _matchingMemberIds {
    if (_searchQuery.isEmpty) {
      // If no search, return all member IDs that have any payment data
      final allMemberIds = <String>{};
      allMemberIds.addAll(_pendingBillsByMember.keys);
      allMemberIds.addAll(_completedPaymentsByMember.keys);
      allMemberIds.addAll(_overdueBillsByMember.keys);
      return allMemberIds;
    }
    
    final query = _searchQuery.toLowerCase();
    final matchingIds = <String>{};
    
    for (var member in _allMembers) {
      final memberName = member.name.toLowerCase();
      final apartment = member.apartmentNumber.toLowerCase();
      final building = member.buildingName.toLowerCase();
      
      // Check if search matches member info
      final matchesMember = memberName.contains(query) ||
          apartment.contains(query) ||
          building.contains(query);
      
      if (matchesMember) {
        matchingIds.add(member.id);
      }
    }
    
    // Also check for bill type matches
    _pendingBillsByMember.forEach((memberId, bills) {
      final matchingBills = bills.where((bill) {
        return bill.utilityType.toLowerCase().contains(query);
      }).toList();
      if (matchingBills.isNotEmpty) {
        matchingIds.add(memberId);
      }
    });
    
    _overdueBillsByMember.forEach((memberId, bills) {
      final matchingBills = bills.where((bill) {
        return bill.utilityType.toLowerCase().contains(query);
      }).toList();
      if (matchingBills.isNotEmpty) {
        matchingIds.add(memberId);
      }
    });
    
    return matchingIds;
  }
  
  // Filtered data based on search query - shows all info for matching members
  Map<String, List<UtilityModel>> get _filteredPendingBills {
    if (_searchQuery.isEmpty) return _pendingBillsByMember;
    
    final matchingIds = _matchingMemberIds;
    final filtered = <String, List<UtilityModel>>{};
    final query = _searchQuery.toLowerCase();
    
    _pendingBillsByMember.forEach((memberId, bills) {
      if (matchingIds.contains(memberId)) {
        // Check if match is by member info (show all bills) or bill type (filter bills)
        final member = _allMembers.firstWhere(
          (m) => m.id == memberId,
          orElse: () => UserModel(
            id: memberId,
            email: '',
            name: '',
            mobileNumber: '',
            role: 'member',
            apartmentNumber: '',
            buildingName: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        final matchesMemberInfo = member.name.toLowerCase().contains(query) ||
            member.apartmentNumber.toLowerCase().contains(query) ||
            member.buildingName.toLowerCase().contains(query);
        
        if (matchesMemberInfo) {
          // Member matches - show ALL their pending bills
          filtered[memberId] = bills;
        } else {
          // Match is by bill type - show only matching bills
          final matchingBills = bills.where((bill) {
            return bill.utilityType.toLowerCase().contains(query);
          }).toList();
          if (matchingBills.isNotEmpty) {
            filtered[memberId] = matchingBills;
          }
        }
      }
    });
    
    return filtered;
  }
  
  Map<String, List<PaymentModel>> get _filteredCompletedPayments {
    if (_searchQuery.isEmpty) return _completedPaymentsByMember;
    
    final matchingIds = _matchingMemberIds;
    final filtered = <String, List<PaymentModel>>{};
    
    // If a member matches, show ALL their completed payments
    _completedPaymentsByMember.forEach((memberId, payments) {
      if (matchingIds.contains(memberId)) {
        filtered[memberId] = payments;
      }
    });
    
    return filtered;
  }
  
  Map<String, List<UtilityModel>> get _filteredOverdueBills {
    if (_searchQuery.isEmpty) return _overdueBillsByMember;
    
    final matchingIds = _matchingMemberIds;
    final filtered = <String, List<UtilityModel>>{};
    final query = _searchQuery.toLowerCase();
    
    _overdueBillsByMember.forEach((memberId, bills) {
      if (matchingIds.contains(memberId)) {
        // Check if match is by member info (show all bills) or bill type (filter bills)
        final member = _allMembers.firstWhere(
          (m) => m.id == memberId,
          orElse: () => UserModel(
            id: memberId,
            email: '',
            name: '',
            mobileNumber: '',
            role: 'member',
            apartmentNumber: '',
            buildingName: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        final matchesMemberInfo = member.name.toLowerCase().contains(query) ||
            member.apartmentNumber.toLowerCase().contains(query) ||
            member.buildingName.toLowerCase().contains(query);
        
        if (matchesMemberInfo) {
          // Member matches - show ALL their overdue bills
          filtered[memberId] = bills;
        } else {
          // Match is by bill type - show only matching bills
          final matchingBills = bills.where((bill) {
            return bill.utilityType.toLowerCase().contains(query);
          }).toList();
          if (matchingBills.isNotEmpty) {
            filtered[memberId] = matchingBills;
          }
        }
      }
    });
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: AppColors.textOnPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by name, flat, or bill type...',
                  hintStyle: TextStyle(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textOnPrimary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppColors.textOnPrimary,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
              )
            : Text(
                'Payment Management',
                style: AppStyles.heading6.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        actions: [
          if (_isSearchActive)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearchActive = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              tooltip: 'Close search',
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearchActive = true;
                });
              },
              tooltip: 'Search',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textOnPrimary,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
          labelStyle: AppStyles.bodyLarge,
          unselectedLabelStyle: AppStyles.bodyMedium,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'Overdue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingPayments(),
          _buildCompletedPayments(),
          _buildOverduePayments(),
        ],
      ),
    );
  }

  Widget _buildPendingPayments() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredPending = _filteredPendingBills;
    
    if (filteredPending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppStyles.spacing16),
            Text(
              'No pending payments',
              style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppStyles.spacing16),
        children: filteredPending.entries.map((entry) {
          final memberId = entry.key;
          final bills = entry.value;
          final memberName = _getMemberDisplayName(memberId);
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppStyles.spacing8,
                  bottom: AppStyles.spacing8,
                ),
                child: Text(
                  memberName,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              ...bills.map((bill) => Padding(
                padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
                child: CustomCard(
                  child: ListTile(
                    leading: Icon(Icons.payment, color: AppColors.warning),
                    title: Text('${bill.utilityType} Bill'),
                    subtitle: Text('Due: ${_formatDate(bill.dueDate)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(bill.totalAmount),
                          style: AppStyles.heading6.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (bill.overdueAmount > 0)
                          Text(
                            'Overdue: ${_formatCurrency(bill.overdueAmount)}',
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(height: AppStyles.spacing16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompletedPayments() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredCompleted = _filteredCompletedPayments;
    
    if (filteredCompleted.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppStyles.spacing16),
            Text(
              'No completed payments',
              style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppStyles.spacing16),
        children: filteredCompleted.entries.map((entry) {
          final memberId = entry.key;
          final payments = entry.value;
          final memberName = _getMemberDisplayName(memberId);
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppStyles.spacing8,
                  bottom: AppStyles.spacing8,
                ),
                child: Text(
                  memberName,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
              ...payments.map((payment) => Padding(
                padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
                child: CustomCard(
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: AppColors.success),
                    title: Text('Payment - ${payment.billIds.length} bill${payment.billIds.length > 1 ? 's' : ''}'),
                    subtitle: Text('Paid: ${_formatDate(payment.paidDate)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(payment.amount),
                          style: AppStyles.heading6.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          payment.paymentMethod.toUpperCase(),
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(height: AppStyles.spacing16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverduePayments() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredOverdue = _filteredOverdueBills;
    
    if (filteredOverdue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppStyles.spacing16),
            Text(
              'No overdue payments',
              style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppStyles.spacing16),
        children: filteredOverdue.entries.map((entry) {
          final memberId = entry.key;
          final bills = entry.value;
          final memberName = _getMemberDisplayName(memberId);
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppStyles.spacing8,
                  bottom: AppStyles.spacing8,
                ),
                child: Text(
                  memberName,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
              ...bills.map((bill) => Padding(
                padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
                child: CustomCard(
                  child: ListTile(
                    leading: Icon(Icons.warning, color: AppColors.error),
                    title: Text('${bill.utilityType} Bill'),
                    subtitle: Text('Due: ${_formatDate(bill.dueDate)} (Overdue)'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(bill.totalAmount),
                          style: AppStyles.heading6.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        if (bill.overdueAmount > 0)
                          Text(
                            'Overdue: ${_formatCurrency(bill.overdueAmount)}',
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(height: AppStyles.spacing16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

