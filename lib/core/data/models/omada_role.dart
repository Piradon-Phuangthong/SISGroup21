/// Roles available in an Omada with their hierarchy
enum OmadaRole {
  guest(1, 'Guest'),
  member(2, 'Member'),
  moderator(3, 'Moderator'),
  admin(4, 'Admin'),
  owner(5, 'Owner');

  final int hierarchyLevel;
  final String displayName;

  const OmadaRole(this.hierarchyLevel, this.displayName);

  /// Convert from database string to enum
  static OmadaRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'guest':
        return OmadaRole.guest;
      case 'member':
        return OmadaRole.member;
      case 'moderator':
        return OmadaRole.moderator;
      case 'admin':
        return OmadaRole.admin;
      case 'owner':
        return OmadaRole.owner;
      default:
        throw ArgumentError('Unknown role: $role');
    }
  }

  /// Convert enum to database string
  String toDbString() {
    return name;
  }

  /// Check if this role has permission based on hierarchy
  bool hasPermission(OmadaRole requiredRole) {
    return hierarchyLevel >= requiredRole.hierarchyLevel;
  }

  /// Check if this role can manage another role
  bool canManage(OmadaRole targetRole) {
    return hierarchyLevel > targetRole.hierarchyLevel;
  }
}

/// Join policies for Omadas
enum JoinPolicy {
  open('open', 'Open - Anyone can join'),
  approval('approval', 'Approval Required'),
  closed('closed', 'Closed - Invite only');

  final String dbValue;
  final String displayName;

  const JoinPolicy(this.dbValue, this.displayName);

  static JoinPolicy fromString(String policy) {
    switch (policy.toLowerCase()) {
      case 'open':
        return JoinPolicy.open;
      case 'approval':
        return JoinPolicy.approval;
      case 'closed':
        return JoinPolicy.closed;
      default:
        return JoinPolicy.approval;
    }
  }
}
