import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

// FileInfo class for handling both web and mobile file uploads
class FileInfo {
  final File? file; // For mobile/desktop
  final Uint8List? bytes; // For web
  final String name;
  final String? path; // For mobile/desktop

  FileInfo({
    this.file,
    this.bytes,
    required this.name,
    this.path,
  });

  bool get isWeb => bytes != null;
  
  String get displayName => name;
  
  IconData get icon {
    final extension = name.split('.').last.toLowerCase();
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
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage
  /// Returns the download URL
  Future<String> uploadFile({
    required File file,
    required String folder,
    String? fileName,
  }) async {
    try {
      // Generate unique filename if not provided
      final String finalFileName = fileName ?? 
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      
      // Create reference to the file location
      final Reference ref = _storage.ref().child('$folder/$finalFileName');

      // Upload file
      final UploadTask uploadTask = ref.putFile(file);
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        debugPrint('File uploaded successfully: $downloadUrl');
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error uploading file: $e');
      }
      throw Exception('Failed to upload file: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error uploading file: $e');
      }
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload multiple files to Firebase Storage
  /// Returns list of download URLs
  Future<List<String>> uploadFiles({
    required List<File> files,
    required String folder,
  }) async {
    try {
      final List<String> downloadUrls = [];
      
      for (final file in files) {
        final url = await uploadFile(
          file: file,
          folder: folder,
        );
        downloadUrls.add(url);
      }
      
      return downloadUrls;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error uploading files: $e');
      }
      throw Exception('Failed to upload files: $e');
    }
  }

  /// Upload FileInfo objects (handles both web and mobile)
  /// Automatically organizes files into separate folders: Photo's for images, pdf's for PDFs
  /// Returns list of download URLs
  Future<List<String>> uploadFileInfos({
    required List<FileInfo> fileInfos,
    required String folder,
  }) async {
    try {
      final List<String> downloadUrls = [];
      
      for (final fileInfo in fileInfos) {
        // Determine file type and subfolder
        final fileExtension = fileInfo.name.split('.').last.toLowerCase();
        final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension);
        final isPdf = fileExtension == 'pdf';
        
        // Build folder path with subfolder based on file type
        String targetFolder = folder;
        if (isImage) {
          targetFolder = '$folder/Photo\'s';
        } else if (isPdf) {
          targetFolder = '$folder/pdf\'s';
        }
        
        String url;
        if (fileInfo.isWeb && fileInfo.bytes != null) {
          // For web, use bytes
          url = await uploadBytes(
            bytes: fileInfo.bytes!,
            folder: targetFolder,
            fileName: fileInfo.name,
          );
        } else if (fileInfo.file != null) {
          // For mobile/desktop, use file
          url = await uploadFile(
            file: fileInfo.file!,
            folder: targetFolder,
            fileName: fileInfo.name,
          );
        } else {
          throw Exception('FileInfo has neither bytes nor file');
        }
        downloadUrls.add(url);
      }
      
      return downloadUrls;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error uploading file infos: $e');
      }
      throw Exception('Failed to upload files: $e');
    }
  }

  /// Upload bytes to Firebase Storage (for web)
  /// Returns the download URL
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
  }) async {
    try {
      // Generate unique filename if needed
      final String finalFileName = 
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      // Create reference to the file location
      final Reference ref = _storage.ref().child('$folder/$finalFileName');

      // Upload bytes
      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: _getContentType(fileName)),
      );
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        debugPrint('File uploaded successfully: $downloadUrl');
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error uploading bytes: $e');
      }
      throw Exception('Failed to upload file: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error uploading bytes: $e');
      }
      throw Exception('Failed to upload file: $e');
    }
  }

  String? _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return null;
    }
  }

  /// Delete a file from Firebase Storage using its URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Extract the file path from the Firebase Storage URL
      final Uri uri = Uri.parse(fileUrl);
      
      // Firebase Storage URLs have format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media
      // Extract the path from the URL
      String? path;
      if (uri.host.contains('firebasestorage')) {
        // Extract path from pathSegments (skip 'v0', 'b', bucket name, 'o')
        // Path segments: ['v0', 'b', '{bucket}', 'o', ...path segments...]
        if (uri.pathSegments.length >= 5) {
          // Join all segments after 'o' to get the full path
          path = uri.pathSegments.sublist(4).join('/');
          // Decode the path (URL encoded)
          path = Uri.decodeComponent(path);
        }
      } else {
        // Fallback: use the last path segment if not a Firebase Storage URL
        path = uri.pathSegments.last;
      }
      
      if (path == null || path.isEmpty) {
        throw Exception('Could not extract file path from URL');
      }
      
      // Get reference to the file
      final Reference ref = _storage.ref().child(path);
      
      // Delete the file
      await ref.delete();
      
      if (kDebugMode) {
        debugPrint('File deleted successfully: $path');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error deleting file: $e');
      }
      // Don't throw error if file doesn't exist
      if (e.code != 'object-not-found') {
        throw Exception('Failed to delete file: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting file: $e');
      }
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Delete multiple files from Firebase Storage
  Future<void> deleteFiles(List<String> fileUrls) async {
    try {
      for (final url in fileUrls) {
        await deleteFile(url);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting files: $e');
      }
      throw Exception('Failed to delete files: $e');
    }
  }

  /// Get download URL for a file (if already uploaded)
  Future<String> getDownloadUrl(String filePath) async {
    try {
      final Reference ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase error getting download URL: $e');
      }
      throw Exception('Failed to get download URL: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting download URL: $e');
      }
      throw Exception('Failed to get download URL: $e');
    }
  }
}

