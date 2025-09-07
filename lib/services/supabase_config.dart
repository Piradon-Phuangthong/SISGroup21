/// Supabase configuration and initialization
/// TODO: Replace with your actual Supabase project credentials

class SupabaseConfig {
  /// TODO: Replace with your Supabase project URL
  /// Get this from: https://app.supabase.io/project/YOUR_PROJECT/settings/api
  static const String supabaseUrl = 'https://cbxqcsnqtgtxqxoetmwz.supabase.co';

  /// TODO: Replace with your Supabase anon/public key
  /// Get this from: https://app.supabase.io/project/YOUR_PROJECT/settings/api
  static const String supabaseAnonKey = 'puAvjXK5gQ04EBm8';

  static const String redirectUri = 'com.myapp.contacts://login-callback'; 

  /// Storage bucket configurations
  /// TODO: Create these buckets in Supabase Storage
  static const String avatarBucket = 'contact-avatars';
  static const String attachmentsBucket = 'contact-attachments';

  /// RLS (Row Level Security) policies that need to be set up
  /// TODO: Apply these policies in your Supabase dashboard
  static const Map<String, List<String>> rlsPolicies = {
    'profiles': [
      'Users can read their own profile',
      'Users can update their own profile',
      'Users can insert their own profile on signup',
    ],
    'contacts': [
      'Users can read their own contacts',
      'Users can create their own contacts',
      'Users can update their own contacts',
      'Users can delete their own contacts',
      'Users can read shared contacts with proper permissions',
    ],
    'contact_channels': [
      'Users can read channels for their contacts',
      'Users can create channels for their contacts',
      'Users can update channels for their contacts',
      'Users can delete channels for their contacts',
      'Users can read shared contact channels',
    ],
    'tags': [
      'Users can read their own tags',
      'Users can create their own tags',
      'Users can update their own tags',
      'Users can delete their own tags',
    ],
    'contact_tags': [
      'Users can manage tags for their contacts',
      'Users can read tags for shared contacts',
    ],
    'share_requests': [
      'Users can read requests sent to them',
      'Users can read requests they sent',
      'Users can create share requests',
      'Users can update requests sent to them',
    ],
    'contact_shares': [
      'Contact owners can read their shares',
      'Contact owners can create shares',
      'Contact owners can update their shares',
      'Contact owners can delete their shares',
      'Recipients can read shares granted to them',
    ],
  };

  /// Database functions that should be created
  /// TODO: Create these functions in your Supabase SQL editor
  static const List<String> requiredFunctions = [
    'get_tag_usage_stats(owner_user_id uuid)',
    'search_contacts_full_text(owner_id uuid, search_term text)',
    'cleanup_orphaned_data()',
  ];

  /// Indexes that should be created for performance
  /// TODO: Create these indexes in your Supabase SQL editor
  static const List<String> recommendedIndexes = [
    'CREATE INDEX IF NOT EXISTS contacts_owner_updated_idx ON contacts(owner_id, updated_at DESC);',
    'CREATE INDEX IF NOT EXISTS contacts_search_idx ON contacts USING gin(to_tsvector(\'english\', coalesce(full_name,\'\') || \' \' || coalesce(given_name,\'\') || \' \' || coalesce(family_name,\'\')));',
    'CREATE INDEX IF NOT EXISTS channels_contact_kind_idx ON contact_channels(contact_id, kind);',
    'CREATE INDEX IF NOT EXISTS channels_value_search_idx ON contact_channels USING gin(to_tsvector(\'english\', coalesce(value,\'\')));',
    'CREATE INDEX IF NOT EXISTS contact_tags_contact_idx ON contact_tags(contact_id);',
    'CREATE INDEX IF NOT EXISTS contact_tags_tag_idx ON contact_tags(tag_id);',
    'CREATE INDEX IF NOT EXISTS share_requests_recipient_status_idx ON share_requests(recipient_id, status);',
    'CREATE INDEX IF NOT EXISTS contact_shares_to_user_active_idx ON contact_shares(to_user_id) WHERE revoked_at IS NULL;',
  ];

  /// Real-time subscriptions configuration
  static const Map<String, List<String>> realtimeSubscriptions = {
    'contacts': ['INSERT', 'UPDATE', 'DELETE'],
    'contact_channels': ['INSERT', 'UPDATE', 'DELETE'],
    'tags': ['INSERT', 'UPDATE', 'DELETE'],
    'contact_tags': ['INSERT', 'DELETE'],
    'share_requests': ['INSERT', 'UPDATE'],
    'contact_shares': ['INSERT', 'UPDATE', 'DELETE'],
  };

  /// File upload constraints
  static const Map<String, dynamic> uploadConstraints = {
    'maxAvatarSizeMB': 5,
    'maxAttachmentSizeMB': 25,
    'allowedImageTypes': ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    'allowedAttachmentTypes': [
      'pdf',
      'doc',
      'docx',
      'txt',
      'jpg',
      'jpeg',
      'png',
    ],
  };
}
