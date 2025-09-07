import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart'; // for FileObject
import 'package:uuid/uuid.dart';
import 'supabase_client.dart';

/// File upload service for handling avatar and attachment uploads to Supabase Storage
class FileUploadService {
  static const _uuid = Uuid();

  /// Storage bucket names
  static const String _avatarBucket = 'contact-avatars';
  static const String _attachmentsBucket = 'contact-attachments';

  /// Upload contact avatar image -> returns public URL
  static Future<String> uploadContactAvatar({
    required String contactId,
    required File imageFile,
  }) async {
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${contactId}_${_uuid.v4()}.$ext';
      final filePath = 'contacts/$fileName';

      await SupabaseClientService.client.storage
          .from(_avatarBucket)
          .upload(filePath, imageFile);

      final publicUrl = SupabaseClientService.client.storage
          .from(_avatarBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Replace avatar (delete old if provided) -> returns new public URL
  static Future<String> updateContactAvatar({
    required String contactId,
    required File imageFile,
    String? oldAvatarUrl,
  }) async {
    try {
      if (oldAvatarUrl != null) {
        await deleteFileFromUrl(oldAvatarUrl, _avatarBucket);
      }
      return uploadContactAvatar(contactId: contactId, imageFile: imageFile);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete avatar by its public URL
  static Future<void> deleteContactAvatar(String avatarUrl) async {
    await deleteFileFromUrl(avatarUrl, _avatarBucket);
  }

  /// Upload attachment -> returns public URL
  static Future<String> uploadAttachment({
    required String contactId,
    required File file,
    String? description, // not used yet, keep for future metadata
  }) async {
    try {
      final originalName = file.path.split('/').last;
      final idx = originalName.lastIndexOf('.');
      final base = idx >= 0 ? originalName.substring(0, idx) : originalName;
      final ext = idx >= 0 ? originalName.substring(idx + 1) : '';
      final fileName = '${contactId}_${_uuid.v4()}_$base${ext.isNotEmpty ? '.$ext' : ''}';
      final filePath = 'contacts/$contactId/attachments/$fileName';

      await SupabaseClientService.client.storage
          .from(_attachmentsBucket)
          .upload(filePath, file);

      final publicUrl = SupabaseClientService.client.storage
          .from(_attachmentsBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete attachment by its public URL
  static Future<void> deleteAttachment(String attachmentUrl) async {
    await deleteFileFromUrl(attachmentUrl, _attachmentsBucket);
  }

  /// Get basic file info from a public URL
  static Future<Map<String, dynamic>?> getFileInfo(
    String fileUrl,
    String bucket,
  ) async {
    try {
      final path = extractFilePathFromUrl(fileUrl, bucket);
      if (path == null) return null;
      // For richer metadata you’d need a head/stat API; return basic info for now.
      return {'url': fileUrl, 'path': path, 'bucket': bucket};
    } catch (_) {
      return null;
    }
  }

  /// List files in a bucket (optionally inside a folder/prefix)
  static Future<List<FileObject>> listFiles({
    required String bucket,
    String? folder, // e.g. 'contacts/123/attachments'
  }) async {
    try {
      final items = await SupabaseClientService.client.storage
          .from(bucket)
          .list(path: folder);
      return items; // List<FileObject>
    } catch (e) {
      return <FileObject>[];
    }
  }

  /// Create a signed URL that expires after [expiresInSeconds]
  static Future<String> getSignedUrl({
    required String bucket,
    required String filePath,
    int expiresInSeconds = 3600,
  }) async {
    try {
      final url = await SupabaseClientService.client.storage
          .from(bucket)
          .createSignedUrl(filePath, expiresInSeconds);
      return url;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete file by its public URL
  static Future<void> deleteFileFromUrl(String fileUrl, String bucket) async {
    final path = extractFilePathFromUrl(fileUrl, bucket);
    if (path == null) {
      throw Exception('Could not extract file path from URL: $fileUrl');
    }
    await SupabaseClientService.client.storage.from(bucket).remove([path]);
  }

  /// Extract `<path>` from: https://<proj>.supabase.co/storage/v1/object/public/<bucket>/<path>
  static String? extractFilePathFromUrl(String fileUrl, String bucket) {
    try {
      final uri = Uri.parse(fileUrl);
      final segs = uri.pathSegments;
      final i = segs.indexOf(bucket);
      if (i == -1 || i >= segs.length - 1) return null;
      return segs.sublist(i + 1).join('/');
    } catch (_) {
      return null;
    }
  }

  /// Validate image extension
  static bool isValidImageFile(File file) {
    const allowed = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final ext = file.path.split('.').last.toLowerCase();
    return allowed.contains(ext);
  }

  /// Validate file size (async)
  static Future<bool> isValidFileSize(File file, {int maxSizeInMB = 10}) async {
    try {
      final size = await file.length();
      return size <= maxSizeInMB * 1024 * 1024;
    } catch (_) {
      return false;
    }
  }

  static Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  static String getFileExtension(File file) {
    final idx = file.path.lastIndexOf('.');
    return idx >= 0 ? file.path.substring(idx + 1).toLowerCase() : '';
    }

  /// Check if a file exists (lists the exact path’s parent and looks for name)
  static Future<bool> fileExists({
    required String bucket,
    required String filePath,
  }) async {
    try {
      // Split to parent folder + basename
      final parts = filePath.split('/');
      final name = parts.removeLast();
      final parent = parts.isEmpty ? null : parts.join('/');

      final items = await SupabaseClientService.client.storage
          .from(bucket)
          .list(path: parent);

      return items.any((f) => f.name == name);
    } catch (_) {
      return false;
    }
  }

  /// Copy/move helpers – left unimplemented intentionally
  static Future<String> copyFile({
    required String sourceBucket,
    required String sourceFilePath,
    required String destinationBucket,
    required String destinationFilePath,
  }) async {
    // Implement by downloading bytes and re-uploading; Supabase Storage
    // doesn't yet expose a server-side cross-bucket copy in the Flutter SDK.
    throw UnimplementedError('File copying not yet implemented');
  }

  static Future<String> moveFile({
    required String sourceBucket,
    required String sourceFilePath,
    required String destinationBucket,
    required String destinationFilePath,
  }) async {
    final newUrl = await copyFile(
      sourceBucket: sourceBucket,
      sourceFilePath: sourceFilePath,
      destinationBucket: destinationBucket,
      destinationFilePath: destinationFilePath,
    );
    await SupabaseClientService.client.storage
        .from(sourceBucket)
        .remove([sourceFilePath]);
    return newUrl;
  }

  /// Remove files that aren’t in [validFilePaths]
  static Future<void> cleanupOrphanedFiles({
    required String bucket,
    required List<String> validFilePaths,
  }) async {
    try {
      final items = await listFiles(bucket: bucket);
      // list() returns only names relative to the provided folder.
      // If you call with no folder, this is top-level names.
      final names = items.map((f) => f.name).toList();

      final orphaned = names.where((p) => !validFilePaths.contains(p)).toList();
      if (orphaned.isNotEmpty) {
        await SupabaseClientService.client.storage.from(bucket).remove(orphaned);
      }
    } catch (e) {
      rethrow;
    }
  }
}
