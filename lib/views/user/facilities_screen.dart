import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/modern_empty_state.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/facility_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/format_utils.dart';

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({super.key});

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _firestoreService.getCurrentUserProfile();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Facilities'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<FacilityModel>>(
        stream: _firestoreService.getFacilitiesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final facilities = snapshot.data ?? [];

          if (facilities.isEmpty) {
            return const ModernEmptyState(
              icon: Icons.sports_tennis_rounded,
              title: 'No Facilities Available',
              subtitle: 'No facilities are currently available for booking.\nContact admin for more information',
              iconColor: AppColors.accent,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppStyles.spacing16),
              itemCount: facilities.length,
              itemBuilder: (context, index) {
                return _buildFacilityCard(facilities[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookingDialog(context),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: AppColors.textOnPrimary),
        label: const Text(
          'Book Now',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityCard(FacilityModel facility) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppStyles.spacing12),
      onTap: () => _showFacilityDetails(facility),
      isClickable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius12),
                ),
                child: Icon(
                  _getFacilityIcon(facility.type),
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppStyles.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      style: AppStyles.heading6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacing4),
                    Text(
                      facility.location,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (facility.hourlyRate > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spacing8,
                    vertical: AppStyles.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                  ),
                  child: Text(
                    '${FormatUtils.formatCurrency(facility.hourlyRate)}/hr',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spacing8,
                    vertical: AppStyles.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                  ),
                  child: Text(
                    'FREE',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (facility.description.isNotEmpty) ...[
            const SizedBox(height: AppStyles.spacing12),
            Text(
              facility.description,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (facility.amenities.isNotEmpty) ...[
            const SizedBox(height: AppStyles.spacing12),
            Wrap(
              spacing: AppStyles.spacing8,
              runSpacing: AppStyles.spacing8,
              children: facility.amenities.take(3).map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spacing8,
                    vertical: AppStyles.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radius8),
                  ),
                  child: Text(
                    amenity,
                    style: AppStyles.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getFacilityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sports_court':
        return Icons.sports_tennis_rounded;
      case 'swimming_pool':
        return Icons.pool_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'clubhouse':
        return Icons.home_work_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'playground':
        return Icons.child_care_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  void _showFacilityDetails(FacilityModel facility) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radius20),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spacing24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        facility.name,
                        style: AppStyles.heading5.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacing16),
                Text(
                  facility.description,
                  style: AppStyles.bodyMedium,
                ),
                const SizedBox(height: AppStyles.spacing16),
                _buildDetailRow(Icons.location_on, 'Location', facility.location),
                _buildDetailRow(
                  Icons.people,
                  'Max Capacity',
                  '${facility.maxCapacity} people',
                ),
                _buildDetailRow(
                  Icons.currency_rupee,
                  'Rate',
                  facility.hourlyRate > 0
                      ? '${FormatUtils.formatCurrency(facility.hourlyRate)}/hour'
                      : 'Free',
                ),
                const SizedBox(height: AppStyles.spacing24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _bookFacility(facility),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    child: const Text('Book Facility'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppStyles.spacing12),
          Text(
            '$label: ',
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    Get.snackbar('Info', 'Select a facility to book');
  }

  Future<void> _bookFacility(FacilityModel facility) async {
    if (_currentUser == null) {
      Get.snackbar('Error', 'Please wait while we load your profile');
      return;
    }

    final startDate = DateTime.now();
    final endDate = startDate.add(const Duration(hours: 1));

    final booking = FacilityBookingModel(
      id: '',
      facilityId: facility.id,
      facilityName: facility.name,
      userId: _authService.currentUser?.uid ?? '',
      userName: _currentUser!.name,
      userApartment: '${_currentUser!.buildingName} - ${_currentUser!.apartmentNumber}',
      startTime: startDate,
      endTime: endDate,
      numberOfGuests: 1,
      status: facility.requiresApproval ? 'pending' : 'approved',
      totalAmount: facility.hourlyRate,
      paymentStatus: facility.hourlyRate > 0 ? 'pending' : 'paid',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _firestoreService.createFacilityBooking(booking);
      Get.back(); // Close facility details dialog
      Get.snackbar(
        'Success',
        'Facility booking ${facility.requiresApproval ? "requested" : "confirmed"}!',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to book facility: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }
}
