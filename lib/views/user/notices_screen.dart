import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/strings.dart';
import '../../widgets/card_widget.dart';
import '../../services/firestore_service.dart';
import '../../models/notice_model.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<NoticeModel> _allNotices = [];
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
      // Fetch all published notices in a single list
      final allNotices = await _firestoreService.getAllNotices();

      setState(() {
        _allNotices = allNotices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        final errorMessage = e.toString();
        
        // Check if it's an index building error
        if (errorMessage.contains('index is currently building') || 
            errorMessage.contains('failed-precondition')) {
          Get.snackbar(
            'Index Building',
            'Firestore indexes are still building. Please wait a few minutes and try again.',
            backgroundColor: AppColors.warning,
            colorText: AppColors.textOnPrimary,
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );
        } else {
          Get.snackbar(
            'Error',
            'Failed to load notices: ${e.toString()}',
            backgroundColor: AppColors.error,
            colorText: AppColors.textOnPrimary,
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> _markAsRead(NoticeModel notice) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestoreService.markNoticeAsRead(notice.id, user.uid);
        await _loadNotices(); // Refresh to update read status
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to mark notice as read: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: AppColors.textOnPrimary,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.notices,
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
                        'No notices available',
                        style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotices,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                      _filteredNotices.isEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.filter_list_off,
                                      size: 64,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: AppStyles.spacing16),
                                     Text(
                                       'No notices found',
                                       style: AppStyles.bodyLarge.copyWith(
                                         color: AppColors.textSecondary,
                                       ),
                                     ),
                                  ],
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.all(AppStyles.spacing16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final notice = _filteredNotices[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: AppStyles.spacing12),
                                      child: NoticeCard(
                                        title: notice.title,
                                        content: notice.content,
                                        category: notice.category,
                                        priority: notice.priority,
                                        publishDate: _formatDate(notice.publishDate),
                                        requiresAcknowledgment: notice.requiresAcknowledgment,
                                        attachments: notice.attachments,
                                        isRead: FirebaseAuth.instance.currentUser != null &&
                                            notice.readBy.contains(
                                              FirebaseAuth.instance.currentUser!.uid,
                                            ),
                                        onImageTap: (url) => _viewImage(url),
                                        onPdfTap: (url) => _viewPdf(url),
                                        onTap: () {
                                          _markAsRead(notice);
                                          _showNoticeDetails(notice);
                                        },
                                      ),
                                    );
                                  },
                                  childCount: _filteredNotices.length,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }


  void _showNoticeDetails(NoticeModel notice) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radius16),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spacing20),
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
                    final isPdf = _isPdfUrl(url);
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppStyles.spacing8),
                      padding: const EdgeInsets.all(AppStyles.spacing12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppStyles.radius8),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPdf ? Icons.picture_as_pdf : Icons.image,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: AppStyles.spacing12),
                              Expanded(
                                child: Text(
                                  _getFileNameFromUrl(url),
                                  style: AppStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPdf)
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () => _viewPdf(url),
                                  tooltip: 'View PDF',
                                  color: AppColors.primary,
                                ),
                              if (isImage)
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
                          if (isImage) ...[
                            const SizedBox(height: AppStyles.spacing8),
                            GestureDetector(
                              onTap: () => _viewImage(url),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppStyles.radius8),
                                child: Image.network(
                                  url,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
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
                                      height: 200,
                                      color: AppColors.background,
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 48),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                          if (isPdf) ...[
                            const SizedBox(height: AppStyles.spacing8),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(AppStyles.radius8),
                                border: Border.all(color: AppColors.grey300),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      size: 64,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(height: AppStyles.spacing8),
                                    Text(
                                      'PDF Document',
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppStyles.spacing8),
                                    ElevatedButton.icon(
                                      onPressed: () => _viewPdf(url),
                                      icon: const Icon(Icons.visibility),
                                      label: const Text('View PDF'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.textOnPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

  bool _isImageUrl(String url) {
    final extension = url.split('.').last.toLowerCase().split('?').first;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  bool _isPdfUrl(String url) {
    final extension = url.split('.').last.toLowerCase().split('?').first;
    return extension == 'pdf';
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

  List<NoticeModel> get _filteredNotices {
    var filtered = _allNotices;
    
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
    
    return filtered;
  }

}