import 'dart:io';
import 'package:uuid/uuid.dart';
import 'supabase_client.dart';

/// File upload service for handling avatar and attachment uploads to Supabase Storage
class FileUploadService {
  static const _uuid = Uuid();

  /// Storage bucket name for contact avatars
  /// TODO: Create this bucket in Supabase Storage
  static const String _avatarBucket = 'contact-avatars';

  /// Storage bucket name for attachments
  /// TODO: Create this bucket in Supabase Storage
  static const String _attachmentsBucket = 'contact-attachments';

  /// Upload contact avatar image
  /// TODO: Implement avatar upload
  static Future<String> uploadContactAvatar({
    required String contactId,
    required File imageFile,
  }) async {
    try {
      // TODO: Generate unique file name
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${contactId}_${_uuid.v4()}.$fileExtension';
      final filePath = 'contacts/$fileName';

      // TODO: Upload file to Supabase Storage
      final response = await SupabaseClientService.client.storage
          .from(_avatarBucket)
          .upload(filePath, imageFile);

      // TODO: Get public URL for the uploaded file
      final publicUrl = SupabaseClientService.client.storage
          .from(_avatarBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Update contact avatar (replaces existing)
  /// TODO: Implement avatar replacement
  static Future<String> updateContactAvatar({
    required String contactId,
    required File imageFile,
    String? oldAvatarUrl,
  }) async {
    try {
      // TODO: Delete old avatar if exists
      if (oldAvatarUrl != null) {
        await deleteFileFromUrl(oldAvatarUrl, _avatarBucket);
      }

      // TODO: Upload new avatar
      return await uploadContactAvatar(
        contactId: contactId,
        imageFile: imageFile,
      );
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Delete contact avatar
  /// TODO: Implement avatar deletion
  static Future<void> deleteContactAvatar(String avatarUrl) async {
    try {
      // TODO: Delete file from storage
      await deleteFileFromUrl(avatarUrl, _avatarBucket);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Upload attachment file
  /// TODO: Implement attachment upload
  static Future<String> uploadAttachment({
    required String contactId,
    required File file,
    String? description,
  }) async {
    try {
      // TODO: Generate unique file name preserving original name
      final originalName = file.path.split('/').last;
      final fileExtension = originalName.contains('.')
          ? originalName.split('.').last
          : '';
      final baseName = originalName.contains('.')
          ? originalName.substring(0, originalName.lastIndexOf('.'))
          : originalName;

      final fileName = '${contactId}_${_uuid.v4()}_$baseName.$fileExtension';
      final filePath = 'contacts/$contactId/attachments/$fileName';

      // TODO: Upload file to Supabase Storage
      await SupabaseClientService.client.storage
          .from(_attachmentsBucket)
          .upload(filePath, file);

      // TODO: Get public URL for the uploaded file
      final publicUrl = SupabaseClientService.client.storage
          .from(_attachmentsBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Delete attachment file
  /// TODO: Implement attachment deletion
  static Future<void> deleteAttachment(String attachmentUrl) async {
    try {
      // TODO: Delete file from storage
      await deleteFileFromUrl(attachmentUrl, _attachmentsBucket);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get file info from URL
  /// TODO: Implement file info retrieval
  static Future<Map<String, dynamic>?> getFileInfo(
    String fileUrl,
    String bucket,
  ) async {
    try {
      // TODO: Extract file path from URL
      final filePath = extractFilePathFromUrl(fileUrl, bucket);
      if (filePath == null) return null;

      // TODO: Get file metadata from Supabase Storage
      // Note: This might require additional Supabase client methods
      // For now, return basic info
      return {'url': fileUrl, 'path': filePath, 'bucket': bucket};
    } catch (e) {
      // TODO: Add proper error handling and logging
      return null;
    }
  }

  /// List files in a directory
  /// TODO: Implement file listing
  static Future<List<Map<String, dynamic>>> listFiles({
    required String bucket,
    String? folder,
  }) async {
    try {
      // TODO: List files in bucket/folder
      final response = await SupabaseClientService.client.storage
          .from(bucket)
          .list(path: folder);

      return response;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return [];
    }
  }

  /// Get file download URL with expiration
  /// TODO: Implement signed URL generation
  static Future<String> getSignedUrl({
    required String bucket,
    required String filePath,
    int expiresInSeconds = 3600,
  }) async {
    try {
      // TODO: Generate signed URL for temporary access
      final signedUrl = await SupabaseClientService.client.storage
          .from(bucket)
          .createSignedUrl(filePath, expiresInSeconds);

      return signedUrl;
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Delete file using its public URL
  /// TODO: Implement file deletion by URL
  static Future<void> deleteFileFromUrl(String fileUrl, String bucket) async {
    try {
      // TODO: Extract file path from public URL
      final filePath = extractFilePathFromUrl(fileUrl, bucket);
      if (filePath == null) {
        throw Exception('Could not extract file path from URL: $fileUrl');
      }

      // TODO: Delete file from storage
      await SupabaseClientService.client.storage.from(bucket).remove([
        filePath,
      ]);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Extract file path from Supabase public URL
  /// TODO: Implement URL parsing
  static String? extractFilePathFromUrl(String fileUrl, String bucket) {
    try {
      // TODO: Parse Supabase public URL to extract file path
      // Format: https://project.supabase.co/storage/v1/object/public/bucket/path
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // Find bucket in path segments
      int bucketIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == bucket) {
          bucketIndex = i;
          break;
        }
      }

      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        return null;
      }

      // Extract path after bucket name
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// Validate file type for avatars
  /// TODO: Implement file type validation
  static bool isValidImageFile(File file) {
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final extension = file.path.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Validate file size
  /// TODO: Implement file size validation
  static bool isValidFileSize(File file, {int maxSizeInMB = 10}) async {
    try {
      final fileSize = await file.length();
      final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
      return fileSize <= maxSizeInBytes;
    } catch (e) {
      return false;
    }
  }

  /// Get file size in bytes
  /// TODO: Implement file size retrieval
  static Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Get file extension
  /// TODO: Implement file extension extraction
  static String getFileExtension(File file) {
    final path = file.path;
    if (path.contains('.')) {
      return path.split('.').last.toLowerCase();
    }
    return '';
  }

  /// Check if file exists in storage
  /// TODO: Implement file existence check
  static Future<bool> fileExists({
    required String bucket,
    required String filePath,
  }) async {
    try {
      // TODO: Check if file exists in bucket
      final files = await SupabaseClientService.client.storage
          .from(bucket)
          .list(path: filePath);

      return files.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Copy file to another location
  /// TODO: Implement file copying
  static Future<String> copyFile({
    required String sourceBucket,
    required String sourceFilePath,
    required String destinationBucket,
    required String destinationFilePath,
  }) async {
    try {
      // TODO: Implement file copying logic
      // This might require downloading and re-uploading
      throw UnimplementedError('File copying not yet implemented');
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Move file to another location
  /// TODO: Implement file moving
  static Future<String> moveFile({
    required String sourceBucket,
    required String sourceFilePath,
    required String destinationBucket,
    required String destinationFilePath,
  }) async {
    try {
      // TODO: Copy file to new location then delete original
      final newUrl = await copyFile(
        sourceBucket: sourceBucket,
        sourceFilePath: sourceFilePath,
        destinationBucket: destinationBucket,
        destinationFilePath: destinationFilePath,
      );

      await SupabaseClientService.client.storage.from(sourceBucket).remove([
        sourceFilePath,
      ]);

      return newUrl;
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Clean up orphaned files
  /// TODO: Implement cleanup operations
  static Future<void> cleanupOrphanedFiles({
    required String bucket,
    required List<String> validFilePaths,
  }) async {
    try {
      // TODO: List all files in bucket and compare with valid paths
      final allFiles = await listFiles(bucket: bucket);
      final allFilePaths = allFiles
          .map((file) => file['name'] as String?)
          .where((name) => name != null)
          .cast<String>()
          .toList();

      // TODO: Identify orphaned files
      final orphanedFiles = allFilePaths
          .where((path) => !validFilePaths.contains(path))
          .toList();

      // TODO: Delete orphaned files
      if (orphanedFiles.isNotEmpty) {
        await SupabaseClientService.client.storage
            .from(bucket)
            .remove(orphanedFiles);
      }
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }
}
