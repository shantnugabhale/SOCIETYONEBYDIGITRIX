import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/society_model.dart';
import '../../widgets/card_widget.dart';

/// Mandatory Address Proof Upload Screen
/// User MUST upload address proof before proceeding
/// After upload, user is FORCEFULLY logged out
class AddressProofUploadScreen extends StatefulWidget {
  const AddressProofUploadScreen({super.key});

  @override
  State<AddressProofUploadScreen> createState() => _AddressProofUploadScreenState();
}

class _AddressProofUploadScreenState extends State<AddressProofUploadScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _addressProofFile;
  bool _isUploading = false;
  bool _uploadComplete = false;
  UserModel? _currentUser;
  SocietyModel? _society;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _firestoreService.getCurrentUserProfile();
      if (user != null && user.societyId != null) {
        final society = await _firestoreService.getSocietyById(user.societyId!);
        setState(() {
          _currentUser = user;
          _society = society;
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user data');
    }
  }

  Future<void> _pickAddressProof() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _addressProofFile = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _uploadAddressProof() async {
    if (_addressProofFile == null) {
      Get.snackbar('Error', 'Please select an address proof document');
      return;
    }

    if (_currentUser == null) {
      Get.snackbar('Error', 'User not found');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload to Firebase Storage
      final downloadUrl = await _storageService.uploadAddressProof(
        _addressProofFile!,
        _currentUser!.id,
      );

      // Update user profile with address proof URL
      await _firestoreService.updateUserAddressProof(
        _currentUser!.id,
        downloadUrl,
      );

      setState(() {
        _isUploading = false;
        _uploadComplete = true;
      });

      // Show success message
      Get.snackbar(
        'Success',
        'Address proof uploaded successfully. You will be logged out for verification.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Force logout after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      await _forceLogout();
    } catch (e) {
      setState(() => _isUploading = false);
      Get.snackbar(
        'Error',
        'Failed to upload: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _forceLogout() async {
    try {
      final authService = AuthService();
      await authService.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Address Proof'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: PopScope(
        canPop: false, // Prevent back navigation
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(AppStyles.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppStyles.spacing8),
                        Text(
                          'Mandatory Verification',
                          style: AppStyles.heading6.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppStyles.spacing12),
                    Text(
                      'You must upload a valid address proof document to verify your residence.',
                      style: AppStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppStyles.spacing8),
                    Text(
                      'Accepted documents: Aadhaar, Utility Bill, Rent Agreement, Sale Deed',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppStyles.spacing32),

              // Society Info
              if (_society != null) ...[
                Text(
                  'Society Details',
                  style: AppStyles.heading6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppStyles.spacing12),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _society!.name,
                        style: AppStyles.heading6,
                      ),
                      const SizedBox(height: AppStyles.spacing4),
                      Text(
                        _society!.fullAddress,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_currentUser != null) ...[
                        const SizedBox(height: AppStyles.spacing8),
                        Text(
                          '${_currentUser!.buildingName} - ${_currentUser!.apartmentNumber}',
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.spacing32),
              ],

              // Upload Section
              Text(
                'Address Proof Document',
                style: AppStyles.heading6.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppStyles.spacing12),

              // Image Preview or Upload Button
              if (_addressProofFile == null)
                InkWell(
                  onTap: _pickAddressProof,
                  borderRadius: BorderRadius.circular(AppStyles.radius12),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(AppStyles.radius12),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: AppStyles.spacing12),
                        Text(
                          'Tap to Upload Address Proof',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppStyles.spacing4),
                        Text(
                          'JPG, PNG or PDF',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Stack(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppStyles.radius12),
                        border: Border.all(
                          color: AppColors.success,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppStyles.radius12),
                        child: Image.file(
                          _addressProofFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () {
                          setState(() => _addressProofFile = null);
                        },
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.error,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: AppStyles.spacing32),

              // Upload Button
              if (_uploadComplete)
                Container(
                  padding: const EdgeInsets.all(AppStyles.spacing16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radius12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppStyles.spacing12),
                      Expanded(
                        child: Text(
                          'Upload complete! Logging out for verification...',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: _isUploading || _addressProofFile == null
                      ? null
                      : _uploadAddressProof,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppStyles.spacing16,
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Upload & Submit for Verification'),
                ),

              const SizedBox(height: AppStyles.spacing24),

              // Warning
              Container(
                padding: const EdgeInsets.all(AppStyles.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radius12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppStyles.spacing12),
                    Expanded(
                      child: Text(
                        'After uploading, you will be logged out. Only Chairman, Secretary, or Treasurer can approve your request.',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

