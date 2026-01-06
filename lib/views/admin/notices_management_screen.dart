import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdfx/pdfx.dart';
 
import 'package:http/http.dart' as http;
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../widgets/card_widget.dart' show NoticeCard;
import '../../widgets/input_field.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart' show FileInfo, StorageService;
import '../../models/notice_model.dart';

class NoticesManagementScreen extends StatefulWidget {
  const NoticesManagementScreen({super.key});

  @override
  State<NoticesManagementScreen> createState() => _NoticesManagementScreenState();
}

class _NoticesManagementScreenState extends State<NoticesManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<NoticeModel> _notices = [];
  List<NoticeModel> _allNotices = []; // Store all notices for filtering
  String? _selectedCategory; // null means "All"
  String? _selectedDateFilter; // null means "All", options: 'today', 'week', 'month', 'year'
  bool _showFilters = false; // Controls filter visibility
  
  final List<Map<String, String>> _categories = const [
    {'value': 'general', 'label': 'General'},
    {'value': 'maintenance', 'label': 'Maintenance'},
    {'value': 'payment', 'label': 'Payment'},
    {'value': 'meeting', 'label': 'Meeting'},
    {'value': 'emergency', 'label': 'Emergency'},
    {'value': 'festival', 'label': 'Festival'},
    {'value': 'other', 'label': 'Other'},
  ];
  
  final List<Map<String, String>> _dateFilters = const [
    {'value': 'today', 'label': 'Today'},
    {'value': 'week', 'label': 'This Week'},
    {'value': 'month', 'label': 'This Month'},
    {'value': 'year', 'label': 'This Year'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notices = await _firestoreService.getAllNoticesForAdmin();
      setState(() {
        _allNotices = notices;
        _applyFilters(); // Apply current filters
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load notices: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Notices Management',
          style: AppStyles.heading6.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showFilters ? AppColors.textOnPrimary : AppColors.textOnPrimary.withValues(alpha: 0.7),
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddNoticeDialog();
            },
            tooltip: 'Add Notice',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allNotices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: AppStyles.spacing16),
                      Text(
                        'No notices found',
                        style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotices,
                  child: CustomScrollView(
                    slivers: [
                      // Category Filters (shown only when _showFilters is true)
                      if (_showFilters)
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.only(
                              left: AppStyles.spacing16,
                              right: AppStyles.spacing16,
                              top: AppStyles.spacing12,
                              bottom: AppStyles.spacing8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.spacing8),
                                SizedBox(
                                  height: 40,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      // "All" filter chip
                                      Padding(
                                        padding: const EdgeInsets.only(right: AppStyles.spacing8),
                                        child: FilterChip(
                                          label: const Text('All'),
                                          selected: _selectedCategory == null,
                                          onSelected: (selected) {
                                            setState(() {
                                              _selectedCategory = null;
                                              _applyFilters();
                                            });
                                          },
                                          selectedColor: AppColors.primary,
                                          labelStyle: TextStyle(
                                            color: _selectedCategory == null
                                                ? AppColors.textOnPrimary
                                                : AppColors.textPrimary,
                                            fontWeight: _selectedCategory == null
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      // Category filter chips
                                      for (final category in _categories)
                                        Padding(
                                          padding: const EdgeInsets.only(right: AppStyles.spacing8),
                                          child: FilterChip(
                                            label: Text(category['label']!),
                                            selected: _selectedCategory == category['value'],
                                            onSelected: (selected) {
                                              setState(() {
                                                _selectedCategory = selected ? category['value'] : null;
                                                _applyFilters();
                                              });
                                            },
                                            selectedColor: AppColors.primary,
                                            labelStyle: TextStyle(
                                              color: _selectedCategory == category['value']
                                                  ? AppColors.textOnPrimary
                                                  : AppColors.textPrimary,
                                              fontWeight: _selectedCategory == category['value']
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
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
                      // Date Filters (shown only when _showFilters is true)
                      if (_showFilters)
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.only(
                              left: AppStyles.spacing16,
                              right: AppStyles.spacing16,
                              top: AppStyles.spacing8,
                              bottom: AppStyles.spacing12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.spacing8),
                                SizedBox(
                                  height: 40,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      // "All" date filter chip
                                      Padding(
                                        padding: const EdgeInsets.only(right: AppStyles.spacing8),
                                        child: FilterChip(
                                          label: const Text('All'),
                                          selected: _selectedDateFilter == null,
                                          onSelected: (selected) {
                                            setState(() {
                                              _selectedDateFilter = null;
                                              _applyFilters();
                                            });
                                          },
                                          selectedColor: AppColors.primary,
                                          labelStyle: TextStyle(
                                            color: _selectedDateFilter == null
                                                ? AppColors.textOnPrimary
                                                : AppColors.textPrimary,
                                            fontWeight: _selectedDateFilter == null
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      // Date filter chips
                                      for (final dateFilter in _dateFilters)
                                        Padding(
                                          padding: const EdgeInsets.only(right: AppStyles.spacing8),
                                          child: FilterChip(
                                            label: Text(dateFilter['label']!),
                                            selected: _selectedDateFilter == dateFilter['value'],
                                            onSelected: (selected) {
                                              setState(() {
                                                _selectedDateFilter = selected ? dateFilter['value'] : null;
                                                _applyFilters();
                                              });
                                            },
                                            selectedColor: AppColors.primary,
                                            labelStyle: TextStyle(
                                              color: _selectedDateFilter == dateFilter['value']
                                                  ? AppColors.textOnPrimary
                                                  : AppColors.textPrimary,
                                              fontWeight: _selectedDateFilter == dateFilter['value']
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
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
                      // Notices List
                      SliverPadding(
                        padding: const EdgeInsets.all(AppStyles.spacing16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final notice = _notices[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
                                child: Stack(
                                  children: [
                                    NoticeCard(
                                      title: notice.title,
                                      content: notice.content,
                                      category: notice.category,
                                      priority: notice.priority,
                                      publishDate: _formatDate(notice.publishDate),
                                      attachments: notice.attachments,
                                      onImageTap: (url) => _viewImage(url),
                                      onPdfTap: (url) => _viewPdf(url),
                                      onTap: () {
                                        _showNoticeDetails(notice);
                                      },
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: PopupMenuButton(
                                        icon: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            shape: BoxShape.circle,
                                            boxShadow: AppStyles.shadowSmall,
                                          ),
                                          child: const Icon(
                                            Icons.more_vert,
                                            size: 20,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: const Row(
                                              children: [
                                                Icon(Icons.edit, size: 18),
                                                SizedBox(width: AppStyles.spacing8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: const Row(
                                              children: [
                                                Icon(Icons.delete, size: 18, color: AppColors.error),
                                                SizedBox(width: AppStyles.spacing8),
                                                Text('Delete', style: TextStyle(color: AppColors.error)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showEditNoticeDialog(notice);
                                          } else if (value == 'delete') {
                                            _deleteNotice(notice.id);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: _notices.length,
                          ),
                        ),
                      ),
                      // Empty state
                      if (_notices.isEmpty && !_isLoading)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.filter_list_off, size: 64, color: AppColors.textSecondary),
                                const SizedBox(height: AppStyles.spacing16),
                                Text(
                                  'No notices found',
                                  style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  void _applyFilters() {
    var filtered = List<NoticeModel>.from(_allNotices);
    
    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered.where((notice) => notice.category == _selectedCategory).toList();
    }
    
    // Filter by date
    if (_selectedDateFilter != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      switch (_selectedDateFilter) {
        case 'today':
          filtered = filtered.where((notice) {
            final noticeDate = DateTime(
              notice.publishDate.year,
              notice.publishDate.month,
              notice.publishDate.day,
            );
            return noticeDate.isAtSameMomentAs(today);
          }).toList();
          break;
        case 'week':
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          filtered = filtered.where((notice) {
            return notice.publishDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                   notice.publishDate.isBefore(now.add(const Duration(days: 1)));
          }).toList();
          break;
        case 'month':
          final monthStart = DateTime(now.year, now.month, 1);
          filtered = filtered.where((notice) {
            return notice.publishDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
                   notice.publishDate.isBefore(now.add(const Duration(days: 1)));
          }).toList();
          break;
        case 'year':
          final yearStart = DateTime(now.year, 1, 1);
          filtered = filtered.where((notice) {
            return notice.publishDate.isAfter(yearStart.subtract(const Duration(days: 1))) &&
                   notice.publishDate.isBefore(now.add(const Duration(days: 1)));
          }).toList();
          break;
      }
    }
    
    setState(() {
      _notices = filtered;
    });
  }

  void _showAddNoticeDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedCategory = 'general';
    String selectedPriority = 'medium';
    List<FileInfo> selectedFiles = [];
    bool isUploading = false;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radius16),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              padding: const EdgeInsets.all(AppStyles.spacing20),
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Add New Notice',
                        style: AppStyles.heading5,
                      ),
                      const SizedBox(height: AppStyles.spacing20),
                      CustomInputField(
                        label: 'Title',
                        hint: 'Enter notice title',
                        controller: titleController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyles.spacing16),
                      CustomInputField(
                        label: 'Content',
                        hint: 'Enter notice content',
                        controller: contentController,
                        maxLines: 5,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Content is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyles.spacing16),
                      CustomDropdownField<String>(
                        label: 'Category',
                        value: selectedCategory,
                        items: const [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                          DropdownMenuItem(value: 'payment', child: Text('Payment')),
                          DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                          DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                          DropdownMenuItem(value: 'festival', child: Text('Festival')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppStyles.spacing16),
                      CustomDropdownField<String>(
                        label: 'Priority',
                        value: selectedPriority,
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedPriority = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppStyles.spacing16),
                      // File attachments section
                      Text(
                        'Attachments (Images & PDFs)',
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacing8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isUploading ? null : () async {
                                await _pickFiles(setDialogState, selectedFiles);
                              },
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Add Files'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppStyles.spacing8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isUploading ? null : () async {
                                await _pickImage(setDialogState, selectedFiles);
                              },
                              icon: const Icon(Icons.image),
                              label: const Text('Add Image'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: AppStyles.spacing12),
                        ...selectedFiles.asMap().entries.map((entry) {
                          final index = entry.key;
                          final file = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppStyles.spacing8),
                            padding: const EdgeInsets.all(AppStyles.spacing12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppStyles.radius8),
                              border: Border.all(color: AppColors.grey300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  file.icon,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppStyles.spacing8),
                                Expanded(
                                  child: Text(
                                    file.displayName,
                                    style: AppStyles.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: isUploading ? null : () {
                                    setDialogState(() {
                                      selectedFiles.removeAt(index);
                                    });
                                  },
                                  color: AppColors.error,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: AppStyles.spacing20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isUploading ? null : () => Get.back(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: AppStyles.spacing12),
                          ElevatedButton(
                            onPressed: isUploading ? null : () async {
                              if (formKey.currentState!.validate()) {
                                setDialogState(() {
                                  isUploading = true;
                                });
                                // Close dialog first
                                Get.back();
                                // Create notice and show success message
                                await _createNotice(
                                  title: titleController.text.trim(),
                                  content: contentController.text.trim(),
                                  category: selectedCategory,
                                  priority: selectedPriority,
                                  status: 'published',
                                  files: selectedFiles,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                            ),
                            child: isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.textOnPrimary,
                                      ),
                                    ),
                                  )
                                : const Text('Publish'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _createNotice({
    required String title,
    required String content,
    required String category,
    required String priority,
    required String status,
    List<FileInfo> files = const [],
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Upload files if any
      List<String> attachmentUrls = [];
      if (files.isNotEmpty) {
        final storageService = StorageService();
        try {
          attachmentUrls = await storageService.uploadFileInfos(
            fileInfos: files,
            folder: 'notices/${user.uid}',
          );
        } catch (e) {
          Get.back(); // Close loading dialog
          if (mounted) {
            Get.snackbar(
              'Error',
              'Failed to upload files: ${e.toString()}',
              backgroundColor: AppColors.error,
              colorText: AppColors.textOnPrimary,
              duration: const Duration(seconds: 3),
            );
          }
          return;
        }
      }

      final userProfile = await _firestoreService.getCurrentUserProfile();
      final authorName = userProfile?.name ?? 'Admin';

      final now = DateTime.now();
      final notice = NoticeModel(
        id: '', // Will be set by Firestore
        title: title,
        content: content,
        category: category,
        priority: priority,
        status: status,
        targetAudience: 'all',
        authorId: user.uid,
        authorName: authorName,
        publishDate: now,
        createdAt: now,
        updatedAt: now,
        attachments: attachmentUrls,
      );

      await _firestoreService.createNotice(notice);
      
      Get.back(); // Close loading dialog
      
      // Show success message
      if (mounted) {
        Get.snackbar(
          'Success',
          'Notice published ✔ — notification will be sent automatically.',
          backgroundColor: AppColors.success,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
          icon: const Icon(Icons.check_circle, color: AppColors.textOnPrimary),
          margin: const EdgeInsets.all(AppStyles.spacing16),
        );
      }
      
      // Reload notices list
      await _loadNotices();
    } catch (e) {
      Get.back(); // Close loading dialog if still open
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to create notice: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _pickFiles(
    StateSetter setDialogState,
    List<FileInfo> selectedFiles,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setDialogState(() {
          for (var platformFile in result.files) {
            if (kIsWeb) {
              // On web, use bytes
              if (platformFile.bytes != null) {
                selectedFiles.add(FileInfo(
                  bytes: platformFile.bytes,
                  name: platformFile.name,
                ));
              }
            } else {
              // On mobile/desktop, use path
              if (platformFile.path != null) {
                selectedFiles.add(FileInfo(
                  file: File(platformFile.path!),
                  name: platformFile.name,
                  path: platformFile.path,
                ));
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to pick files: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
        );
      }
    }
  }

  Future<void> _pickImage(
    StateSetter setDialogState,
    List<FileInfo> selectedFiles,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setDialogState(() {
          if (kIsWeb) {
            // For web, read bytes
            image.readAsBytes().then((bytes) {
              setDialogState(() {
                selectedFiles.add(FileInfo(
                  bytes: bytes,
                  name: image.name,
                ));
              });
            });
          } else {
            selectedFiles.add(FileInfo(
              file: File(image.path),
              name: image.name,
              path: image.path,
            ));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to pick image: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
        );
      }
    }
  }


  void _showEditNoticeDialog(NoticeModel notice) {
    final titleController = TextEditingController(text: notice.title);
    final contentController = TextEditingController(text: notice.content);
    final formKey = GlobalKey<FormState>();
    String selectedCategory = notice.category;
    String selectedPriority = notice.priority;
    List<FileInfo> selectedFiles = [];
    List<String> existingAttachments = List.from(notice.attachments);
    bool isUploading = false;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radius16),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              padding: const EdgeInsets.all(AppStyles.spacing20),
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Edit Notice',
                        style: AppStyles.heading5,
                      ),
                      const SizedBox(height: AppStyles.spacing20),
                      CustomInputField(
                        label: 'Title',
                        hint: 'Enter notice title',
                        controller: titleController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyles.spacing16),
                      CustomInputField(
                        label: 'Content',
                        hint: 'Enter notice content',
                        controller: contentController,
                        maxLines: 5,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Content is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppStyles.spacing16),
                      CustomDropdownField<String>(
                        label: 'Category',
                        value: selectedCategory,
                        items: const [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                          DropdownMenuItem(value: 'payment', child: Text('Payment')),
                          DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                          DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                          DropdownMenuItem(value: 'festival', child: Text('Festival')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppStyles.spacing16),
                      CustomDropdownField<String>(
                        label: 'Priority',
                        value: selectedPriority,
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedPriority = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppStyles.spacing16),
                      // Existing attachments
                      if (existingAttachments.isNotEmpty) ...[
                        Text(
                          'Existing Attachments',
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppStyles.spacing8),
                        ...existingAttachments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final url = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppStyles.spacing8),
                            padding: const EdgeInsets.all(AppStyles.spacing12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppStyles.radius8),
                              border: Border.all(color: AppColors.grey300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getFileIconFromUrl(url),
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppStyles.spacing8),
                                Expanded(
                                  child: Text(
                                    _getFileNameFromUrl(url),
                                    style: AppStyles.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: isUploading ? null : () {
                                    setDialogState(() {
                                      existingAttachments.removeAt(index);
                                    });
                                  },
                                  color: AppColors.error,
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: AppStyles.spacing12),
                      ],
                      // File attachments section
                      Text(
                        'Add New Attachments (Images & PDFs)',
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacing8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isUploading ? null : () async {
                                await _pickFiles(setDialogState, selectedFiles);
                              },
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Add Files'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppStyles.spacing8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isUploading ? null : () async {
                                await _pickImage(setDialogState, selectedFiles);
                              },
                              icon: const Icon(Icons.image),
                              label: const Text('Add Image'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: AppStyles.spacing12),
                        ...selectedFiles.asMap().entries.map((entry) {
                          final index = entry.key;
                          final file = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppStyles.spacing8),
                            padding: const EdgeInsets.all(AppStyles.spacing12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppStyles.radius8),
                              border: Border.all(color: AppColors.grey300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  file.icon,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppStyles.spacing8),
                                Expanded(
                                  child: Text(
                                    file.displayName,
                                    style: AppStyles.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: isUploading ? null : () {
                                    setDialogState(() {
                                      selectedFiles.removeAt(index);
                                    });
                                  },
                                  color: AppColors.error,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: AppStyles.spacing20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isUploading ? null : () => Get.back(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: AppStyles.spacing12),
                          ElevatedButton(
                            onPressed: isUploading ? null : () async {
                              if (formKey.currentState!.validate()) {
                                setDialogState(() {
                                  isUploading = true;
                                });
                                await _updateNotice(
                                  notice.id,
                                  title: titleController.text.trim(),
                                  content: contentController.text.trim(),
                                  category: selectedCategory,
                                  priority: selectedPriority,
                                  status: notice.status,
                                  existingAttachments: existingAttachments,
                                  newFiles: selectedFiles,
                                );
                                Get.back();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                            ),
                            child: isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.textOnPrimary,
                                      ),
                                    ),
                                  )
                                : const Text('Update'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _updateNotice(
    String noticeId, {
    required String title,
    required String content,
    required String category,
    required String priority,
    required String status,
    List<String> existingAttachments = const [],
    List<FileInfo> newFiles = const [],
  }) async {
    try {
      final existingNotice = await _firestoreService.getNoticeById(noticeId);
      if (existingNotice == null) {
        throw Exception('Notice not found');
      }

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Upload new files if any
      List<String> newAttachmentUrls = [];
      if (newFiles.isNotEmpty) {
        final user = _authService.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }
        
        final storageService = StorageService();
        try {
          newAttachmentUrls = await storageService.uploadFileInfos(
            fileInfos: newFiles,
            folder: 'notices/${user.uid}',
          );
        } catch (e) {
          Get.back(); // Close loading dialog
          if (mounted) {
            Get.snackbar(
              'Error',
              'Failed to upload files: ${e.toString()}',
              backgroundColor: AppColors.error,
              colorText: AppColors.textOnPrimary,
              duration: const Duration(seconds: 3),
            );
          }
          return;
        }
      }

      // Combine existing and new attachments
      final allAttachments = [...existingAttachments, ...newAttachmentUrls];

      final updatedNotice = existingNotice.copyWith(
        title: title,
        content: content,
        category: category,
        priority: priority,
        status: status,
        attachments: allAttachments,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateNotice(noticeId, updatedNotice);
      
      Get.back(); // Close loading dialog
      await _loadNotices();

      if (mounted) {
        Get.snackbar(
          'Success',
          'Notice updated successfully',
          backgroundColor: AppColors.success,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog if still open
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to update notice: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  IconData _getFileIconFromUrl(String url) {
    final extension = url.split('.').last.toLowerCase().split('?').first;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      return 'Attachment';
    } catch (e) {
      return 'Attachment';
    }
  }

  Future<void> _deleteNotice(String noticeId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text('Are you sure you want to delete this notice?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteNotice(noticeId);
        await _loadNotices();

        if (mounted) {
          Get.snackbar(
            'Success',
            'Notice deleted successfully',
            backgroundColor: AppColors.success,
            colorText: AppColors.textOnPrimary,
            duration: const Duration(seconds: 2),
          );
        }
      } catch (e) {
        if (mounted) {
          Get.snackbar(
            'Error',
            'Failed to delete notice: ${e.toString()}',
            backgroundColor: AppColors.error,
            colorText: AppColors.textOnPrimary,
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }

  void _showNoticeDetails(NoticeModel notice) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radius16),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spacing20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: AppStyles.heading5,
                ),
                const SizedBox(height: AppStyles.spacing12),
                Text(
                  notice.content,
                  style: AppStyles.bodyMedium,
                ),
                const SizedBox(height: AppStyles.spacing16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spacing12,
                        vertical: AppStyles.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radius8),
                      ),
                      child: Text(
                        notice.category.toUpperCase(),
                        style: AppStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacing8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spacing12,
                        vertical: AppStyles.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(notice.priority).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radius8),
                      ),
                      child: Text(
                        notice.priority.toUpperCase(),
                        style: AppStyles.caption.copyWith(
                          color: _getPriorityColor(notice.priority),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacing16),
                // Attachments section
                if (notice.attachments.isNotEmpty) ...[
                  Text(
                    'Attachments',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacing8),
                  ...notice.attachments.map((url) {
                    final isImage = _isImageUrl(url);
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppStyles.spacing8),
                      padding: const EdgeInsets.all(AppStyles.spacing12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppStyles.radius8),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIconFromUrl(url),
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: AppStyles.spacing12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getFileNameFromUrl(url),
                                  style: AppStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isImage)
                                  const SizedBox(height: AppStyles.spacing4),
                                if (isImage)
                                  GestureDetector(
                                    onTap: () => _viewImage(url),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(AppStyles.radius8),
                                      child: Image.network(
                                        url,
                                        width: 200,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 200,
                                            height: 150,
                                            color: AppColors.background,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 200,
                                            height: 150,
                                            color: AppColors.background,
                                            child: const Icon(Icons.broken_image),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                if (_isPdfUrl(url))
                                  const SizedBox(height: AppStyles.spacing4),
                                if (_isPdfUrl(url))
                                  Container(
                                    padding: const EdgeInsets.all(AppStyles.spacing8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppStyles.radius8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.picture_as_pdf,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppStyles.spacing8),
                                        TextButton.icon(
                                          onPressed: () => _viewPdf(url),
                                          icon: const Icon(Icons.visibility, size: 16),
                                          label: const Text('View PDF'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppStyles.spacing8,
                                              vertical: AppStyles.spacing4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_isPdfUrl(url))
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _viewPdf(url),
                              tooltip: 'View PDF',
                              color: AppColors.primary,
                            ),
                          if (_isImageUrl(url))
                            IconButton(
                              icon: const Icon(Icons.fullscreen),
                              onPressed: () => _viewImage(url),
                              tooltip: 'View Image',
                              color: AppColors.primary,
                            ),
                          IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => _openFile(url),
                            tooltip: 'Download',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppStyles.spacing16),
                ],
                Text(
                  'Published: ${_formatDate(notice.publishDate)}',
                  style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  'Author: ${notice.authorName}',
                  style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppStyles.spacing20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isImageUrl(String url) {
    final extension = url.split('.').last.toLowerCase().split('?').first;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  bool _isPdfUrl(String url) {
    final extension = url.split('.').last.toLowerCase().split('?').first;
    return extension == 'pdf';
  }

  void _viewImage(String url) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(url),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewPdf(String url) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radius16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.9,
            maxWidth: MediaQuery.of(Get.context!).size.width * 0.9,
          ),
          child: Column(
            children: [
              AppBar(
                title: Text(
                  _getFileNameFromUrl(url),
                  style: AppStyles.heading6.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _openFile(url),
                    tooltip: 'Download',
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<Uint8List>(
                  future: _loadPdfBytes(url),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: AppStyles.spacing16),
                            Text(
                              'Failed to load PDF',
                              style: AppStyles.bodyMedium,
                            ),
                            const SizedBox(height: AppStyles.spacing8),
                            ElevatedButton(
                              onPressed: () => _openFile(url),
                              child: const Text('Open in Browser'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (snapshot.hasData) {
                      return PdfView(
                        controller: PdfController(
                          document: PdfDocument.openData(snapshot.data!),
                        ),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _loadPdfBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to load PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load PDF: $e');
    }
  }

  Future<void> _openFile(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          Get.snackbar(
            'Error',
            'Could not open file',
            backgroundColor: AppColors.error,
            colorText: AppColors.textOnPrimary,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to open file: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
        );
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.info;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}

