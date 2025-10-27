import 'package:flutter_test/flutter_test.dart';
import 'package:omada/core/data/models/models.dart';

void main() {
  group('OmadaRole', () {
    test('hierarchy levels are correct', () {
      expect(OmadaRole.guest.hierarchyLevel, 1);
      expect(OmadaRole.member.hierarchyLevel, 2);
      expect(OmadaRole.moderator.hierarchyLevel, 3);
      expect(OmadaRole.admin.hierarchyLevel, 4);
      expect(OmadaRole.owner.hierarchyLevel, 5);
    });

    test('hasPermission works correctly', () {
      expect(OmadaRole.admin.hasPermission(OmadaRole.member), true);
      expect(OmadaRole.admin.hasPermission(OmadaRole.moderator), true);
      expect(OmadaRole.admin.hasPermission(OmadaRole.admin), true);
      expect(OmadaRole.admin.hasPermission(OmadaRole.owner), false);

      expect(OmadaRole.member.hasPermission(OmadaRole.admin), false);
      expect(OmadaRole.member.hasPermission(OmadaRole.member), true);
    });

    test('canManage works correctly', () {
      expect(OmadaRole.admin.canManage(OmadaRole.member), true);
      expect(OmadaRole.admin.canManage(OmadaRole.moderator), true);
      expect(OmadaRole.admin.canManage(OmadaRole.admin), false);
      expect(OmadaRole.admin.canManage(OmadaRole.owner), false);

      expect(OmadaRole.owner.canManage(OmadaRole.admin), true);
      expect(OmadaRole.member.canManage(OmadaRole.guest), true);
    });

    test('fromString converts correctly', () {
      expect(OmadaRole.fromString('guest'), OmadaRole.guest);
      expect(OmadaRole.fromString('member'), OmadaRole.member);
      expect(OmadaRole.fromString('moderator'), OmadaRole.moderator);
      expect(OmadaRole.fromString('admin'), OmadaRole.admin);
      expect(OmadaRole.fromString('owner'), OmadaRole.owner);

      // Case insensitive
      expect(OmadaRole.fromString('ADMIN'), OmadaRole.admin);
    });

    test('toDbString returns lowercase name', () {
      expect(OmadaRole.admin.toDbString(), 'admin');
      expect(OmadaRole.owner.toDbString(), 'owner');
    });
  });

  group('JoinPolicy', () {
    test('fromString converts correctly', () {
      expect(JoinPolicy.fromString('open'), JoinPolicy.open);
      expect(JoinPolicy.fromString('approval'), JoinPolicy.approval);
      expect(JoinPolicy.fromString('closed'), JoinPolicy.closed);

      // Default to approval for unknown
      expect(JoinPolicy.fromString('invalid'), JoinPolicy.approval);
    });

    test('dbValue returns correct string', () {
      expect(JoinPolicy.open.dbValue, 'open');
      expect(JoinPolicy.approval.dbValue, 'approval');
      expect(JoinPolicy.closed.dbValue, 'closed');
    });
  });

  group('OmadaModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'test-id',
        'owner_id': 'owner-id',
        'name': 'Test Omada',
        'description': 'Test description',
        'color': '#FF6B6B',
        'icon': 'test-icon',
        'avatar_url': 'https://example.com/avatar.png',
        'join_policy': 'approval',
        'is_public': true,
        'is_deleted': false,
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'member_count': 5,
        'pending_requests_count': 2,
      };

      final omada = OmadaModel.fromJson(json);

      expect(omada.id, 'test-id');
      expect(omada.name, 'Test Omada');
      expect(omada.joinPolicy, JoinPolicy.approval);
      expect(omada.isPublic, true);
      expect(omada.memberCount, 5);
      expect(omada.pendingRequestsCount, 2);
    });

    test('toJson converts correctly', () {
      final omada = OmadaModel(
        id: 'test-id',
        ownerId: 'owner-id',
        name: 'Test Omada',
        description: 'Test description',
        color: '#FF6B6B',
        joinPolicy: JoinPolicy.open,
        isPublic: false,
        createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T00:00:00Z'),
        memberCount: 10,
      );

      final json = omada.toJson();

      expect(json['id'], 'test-id');
      expect(json['name'], 'Test Omada');
      expect(json['join_policy'], 'open');
      expect(json['is_public'], false);
      expect(json['member_count'], 10);
    });

    test('copyWith works correctly', () {
      final original = OmadaModel(
        id: 'test-id',
        ownerId: 'owner-id',
        name: 'Original Name',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(name: 'New Name', memberCount: 5);

      expect(updated.name, 'New Name');
      expect(updated.memberCount, 5);
      expect(updated.id, original.id);
      expect(updated.ownerId, original.ownerId);
    });
  });

  group('OmadaMembershipModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'membership-id',
        'omada_id': 'omada-id',
        'user_id': 'user-id',
        'role_name': 'admin',
        'joined_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'profiles': {
          'name': 'John Doe',
          'avatar_url': 'https://example.com/avatar.png',
        },
      };

      final membership = OmadaMembershipModel.fromJson(json);

      expect(membership.id, 'membership-id');
      expect(membership.role, OmadaRole.admin);
      expect(membership.userName, 'John Doe');
      expect(membership.userAvatar, 'https://example.com/avatar.png');
    });

    test('toJson converts correctly', () {
      final membership = OmadaMembershipModel(
        id: 'membership-id',
        omadaId: 'omada-id',
        userId: 'user-id',
        role: OmadaRole.moderator,
        joinedAt: DateTime.parse('2025-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T00:00:00Z'),
      );

      final json = membership.toJson();

      expect(json['id'], 'membership-id');
      expect(json['role_name'], 'moderator');
    });
  });

  group('JoinRequestModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'request-id',
        'omada_id': 'omada-id',
        'user_id': 'user-id',
        'status': 'pending',
        'message': 'Please let me join',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
      };

      final request = JoinRequestModel.fromJson(json);

      expect(request.id, 'request-id');
      expect(request.status, JoinRequestStatus.pending);
      expect(request.message, 'Please let me join');
      expect(request.isPending, true);
    });

    test('status helpers work correctly', () {
      final pending = JoinRequestModel(
        id: 'id',
        omadaId: 'omada-id',
        userId: 'user-id',
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pending.isPending, true);
      expect(pending.isApproved, false);
      expect(pending.isRejected, false);

      final approved = pending.copyWith(status: JoinRequestStatus.approved);
      expect(approved.isApproved, true);
      expect(approved.isPending, false);

      final rejected = pending.copyWith(status: JoinRequestStatus.rejected);
      expect(rejected.isRejected, true);
    });
  });

  group('Role Hierarchy Business Logic', () {
    test('owner has highest permissions', () {
      final owner = OmadaRole.owner;

      expect(owner.canManage(OmadaRole.admin), true);
      expect(owner.canManage(OmadaRole.moderator), true);
      expect(owner.canManage(OmadaRole.member), true);
      expect(owner.canManage(OmadaRole.guest), true);
    });

    test('admin cannot manage owner', () {
      final admin = OmadaRole.admin;

      expect(admin.canManage(OmadaRole.owner), false);
      expect(admin.hasPermission(OmadaRole.owner), false);
    });

    test('member can only manage guests', () {
      final member = OmadaRole.member;

      expect(member.canManage(OmadaRole.guest), true);
      expect(member.canManage(OmadaRole.member), false);
      expect(member.canManage(OmadaRole.moderator), false);
    });
  });
}
