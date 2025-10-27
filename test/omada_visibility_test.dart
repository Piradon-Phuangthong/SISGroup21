import 'package:flutter_test/flutter_test.dart';
import 'package:omada/core/data/models/models.dart';

void main() {
  group('Omada Visibility Tests', () {
    test('OmadaModel.fromJson handles is_public field correctly', () {
      final json = {
        'id': 'test-id',
        'owner_id': 'owner-id',
        'name': 'Test Omada',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'is_public': true,
      };

      final omada = OmadaModel.fromJson(json);
      expect(omada.isPublic, true);
    });

    test('OmadaModel.fromJson handles visibility field correctly - public', () {
      final json = {
        'id': 'test-id',
        'owner_id': 'owner-id',
        'name': 'Test Omada',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'visibility': 'public',
      };

      final omada = OmadaModel.fromJson(json);
      expect(omada.isPublic, true);
    });

    test('OmadaModel.fromJson handles visibility field correctly - private', () {
      final json = {
        'id': 'test-id',
        'owner_id': 'owner-id',
        'name': 'Test Omada',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'visibility': 'private',
      };

      final omada = OmadaModel.fromJson(json);
      expect(omada.isPublic, false);
    });

    test('OmadaModel.fromJson prioritizes is_public over visibility', () {
      final json = {
        'id': 'test-id',
        'owner_id': 'owner-id',
        'name': 'Test Omada',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'is_public': false,
        'visibility': 'public', // This should be ignored
      };

      final omada = OmadaModel.fromJson(json);
      expect(omada.isPublic, false);
    });

    test('OmadaModel.fromJson defaults to public when no visibility fields present', () {
      final json = {
        'id': 'test-id',
        'owner_id': 'owner-id',
        'name': 'Test Omada',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
      };

      final omada = OmadaModel.fromJson(json);
      expect(omada.isPublic, true);
    });

    test('OmadaModel handles case insensitive visibility values', () {
      final jsonPublic = {
        'id': 'test-id',
        'owner_id': 'owner-id',
        'name': 'Test Omada',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'visibility': 'PUBLIC', // Uppercase
      };

      final jsonPrivate = {
        'id': 'test-id',
        'owner_id': 'owner-id',
        'name': 'Test Omada',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'visibility': 'PRIVATE', // Uppercase
      };

      final omadaPublic = OmadaModel.fromJson(jsonPublic);
      final omadaPrivate = OmadaModel.fromJson(jsonPrivate);

      expect(omadaPublic.isPublic, true);
      expect(omadaPrivate.isPublic, false);
    });
  });
}