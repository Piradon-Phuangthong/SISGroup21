import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:omada/core/data/models/contact_model.dart';
import 'package:omada/core/data/models/contact_channel_model.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'package:omada/core/controllers/contact_form_controller.dart';
import 'package:omada/core/data/utils/validation_utils.dart';
import 'package:omada/core/data/models/tag_model.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:omada/ui/widgets/app_card.dart';
import 'package:omada/ui/widgets/app_bottom_nav.dart';

class ContactFormPage extends StatefulWidget {
  final ContactModel? contact;

  const ContactFormPage({super.key, this.contact});

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final ContactFormController _controller;

  final TextEditingController _givenNameController = TextEditingController();
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _primaryMobileController =
      TextEditingController();
  final TextEditingController _primaryEmailController = TextEditingController();

  bool _submitting = false;
  bool _isEditing = false;
  List<TagModel> _allTags = [];
  final Set<String> _selectedTagIds = <String>{};
  List<ContactChannelModel> _contactChannels = [];

  @override
  void initState() {
    super.initState();
    _controller = ContactFormController(supabase);

    final contact = widget.contact;
    if (contact != null) {
      // If editing an existing contact, start in read-only mode
      _isEditing = false;
      _givenNameController.text = contact.givenName ?? '';
      _familyNameController.text = contact.familyName ?? '';
      _primaryMobileController.text = contact.primaryMobile ?? '';
      _primaryEmailController.text = contact.primaryEmail?.isNotEmpty == true
          ? contact.primaryEmail!
          : '';
    } else {
      // If creating a new contact, start in editing mode
      _isEditing = true;
    }
    _loadTags(contactId: widget.contact?.id);
    _loadChannels(contactId: widget.contact?.id);
  }

  @override
  void dispose() {
    _givenNameController.dispose();
    _familyNameController.dispose();
    _primaryMobileController.dispose();
    _primaryEmailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final givenName = _givenNameController.text.trim().isEmpty
        ? null
        : _givenNameController.text.trim();
    final familyName = _familyNameController.text.trim().isEmpty
        ? null
        : _familyNameController.text.trim();
    // Build full name from given name + family name
    final fullName = givenName != null || familyName != null
        ? '${givenName ?? ''} ${familyName ?? ''}'.trim()
        : null;
    final primaryMobile = _primaryMobileController.text.trim();
    final primaryEmail = _primaryEmailController.text.trim().isEmpty
        ? null
        : _primaryEmailController.text.trim();

    try {
      if (widget.contact == null) {
        await _controller.createContact(
          fullName: fullName,
          givenName: givenName,
          familyName: familyName,
          primaryMobile: primaryMobile,
          primaryEmail: primaryEmail,
          tagIds: _selectedTagIds.toList(),
        );
      } else {
        await _controller.updateContact(
          widget.contact!.id,
          fullName: fullName,
          givenName: givenName,
          familyName: familyName,
          primaryMobile: primaryMobile,
          primaryEmail: primaryEmail,
          tagIds: _selectedTagIds.toList(),
        );
      }

      if (!mounted) return;
      
      // Reload channels to show newly created mobile/email channels
      if (widget.contact != null) {
        await _loadChannels(contactId: widget.contact!.id);
      }
      
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save contact: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.contact != null;
    final displayName =
        _givenNameController.text.isNotEmpty ||
            _familyNameController.text.isNotEmpty
        ? '${_givenNameController.text} ${_familyNameController.text}'.trim()
        : 'Unnamed Contact';

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(active: AppNav.contacts),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // Custom App Bar with gradient banner
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // TODO: Implement favorite functionality
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3B82F6), // Blue
                        Color(0xFF9370DB), // Medium Purple
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            // Profile Avatar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8A2BE2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Contact Name
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Relationship/Tags
                            if (_selectedTagIds.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: _allTags
                                    .where(
                                      (tag) => _selectedTagIds.contains(tag.id),
                                    )
                                    .map(
                                      (tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          tag.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.white),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            const SizedBox(height: 16),
                            // Quick Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildQuickActionButton(
                                  icon: Icons.phone,
                                  label: 'Call',
                                  onTap: _makePhoneCall,
                                ),
                                _buildQuickActionButton(
                                  icon: Icons.message,
                                  label: 'Message',
                                  onTap: _sendMessage,
                                ),
                                _buildQuickActionButton(
                                  icon: Icons.email,
                                  label: 'Email',
                                  onTap: _sendEmail,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Content Area with form sections
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(OmadaTokens.space16),
                  child: Column(
                    children: [
                      // Contact Information Card
                      AppCard(
                        padding: const EdgeInsets.all(OmadaTokens.space20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Contact Information',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (widget.contact != null)
                                  TextButton.icon(
                                    onPressed: _toggleEditMode,
                                    icon: Icon(
                                      _isEditing ? Icons.close : Icons.edit,
                                      size: 18,
                                      color: Colors.blue[400],
                                    ),
                                    label: Text(
                                      _isEditing ? 'Cancel' : 'Edit',
                                      style: TextStyle(
                                        color: Colors.blue[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: OmadaTokens.space16),
                            // Given and Family Name Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormFieldWithIcon(
                                    icon: Icons.badge,
                                    label: 'Given Name',
                                    controller: _givenNameController,
                                    validator: _isEditing
                                        ? (_) => _validateNameFields()
                                        : null,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    enabled: _isEditing,
                                  ),
                                ),
                                const SizedBox(width: OmadaTokens.space12),
                                Expanded(
                                  child: _buildFormFieldWithIcon(
                                    icon: Icons.family_restroom,
                                    label: 'Family Name',
                                    controller: _familyNameController,
                                    validator: _isEditing
                                        ? (_) => _validateNameFields()
                                        : null,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    enabled: _isEditing,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: OmadaTokens.space16),
                            // Mobile Field
                            _buildFormFieldWithIcon(
                              icon: Icons.phone,
                              label: 'Mobile',
                              controller: _primaryMobileController,
                              validator: _isEditing
                                  ? (value) {
                                      final v = value?.trim() ?? '';
                                      if (v.isEmpty)
                                        return 'Mobile number is required';
                                      if (!ValidationUtils.isValidPhoneNumber(
                                        v,
                                      )) {
                                        return 'Enter a valid phone number';
                                      }
                                      return null;
                                    }
                                  : null,
                              keyboardType: TextInputType.phone,
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: OmadaTokens.space16),
                            // Email Field
                            _buildFormFieldWithIcon(
                              icon: Icons.email,
                              label: 'Email',
                              controller: _primaryEmailController,
                              validator: _isEditing
                                  ? (value) {
                                      final v = value?.trim() ?? '';
                                      if (v.isEmpty) return null;
                                      if (!ValidationUtils.isValidEmail(v)) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    }
                                  : null,
                              keyboardType: TextInputType.emailAddress,
                              enabled: _isEditing,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: OmadaTokens.space16),
                      // Social Media Card
                      AppCard(
                        padding: const EdgeInsets.all(OmadaTokens.space20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Social Media',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: OmadaTokens.space16),
                            // Social Media Buttons - only show if contact has these channels
                            _buildSocialMediaButtons(),
                          ],
                        ),
                      ),
                      const SizedBox(height: OmadaTokens.space16),
                      // Social Media Management Section (only show when editing)
                      if (_isEditing) _buildSocialMediaManagementSection(),
                      const SizedBox(height: OmadaTokens.space24),
                      // Tags Section
                      AppCard(
                        child: _buildTagSection(),
                      ),
                      // Save Button (only show when editing)
                      if (_isEditing) ...[
                        const SizedBox(height: OmadaTokens.space24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _submitting ? null : _save,
                            icon: _submitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              isEditing ? 'Save changes' : 'Create contact',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing && widget.contact != null) {
        // If canceling edit, restore original values
        final contact = widget.contact!;
        _givenNameController.text = contact.givenName ?? '';
        _familyNameController.text = contact.familyName ?? '';
        _primaryMobileController.text = contact.primaryMobile ?? '';
        _primaryEmailController.text = contact.primaryEmail?.isNotEmpty == true
            ? contact.primaryEmail!
            : '';
      }
    });
  }

  String _getInitials() {
    final given = _givenNameController.text.trim();
    final family = _familyNameController.text.trim();
    if (given.isNotEmpty && family.isNotEmpty) {
      return '${given[0].toUpperCase()}${family[0].toUpperCase()}';
    } else if (given.isNotEmpty) {
      return given[0].toUpperCase();
    } else if (family.isNotEmpty) {
      return family[0].toUpperCase();
    }
    return '?';
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFieldWithIcon({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? hintText,
    bool enabled = true,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: controller,
                enabled: enabled,
                keyboardType: keyboardType,
                textCapitalization: textCapitalization,
                validator: validator,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaButtons() {
    final socialMediaChannels = _contactChannels.where((channel) => 
      _isSocialMediaPlatform(channel.kind)
    ).toList();

    if (socialMediaChannels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: socialMediaChannels.map((channel) {
        switch (channel.kind) {
          case ChannelKind.linkedin:
            return _buildSocialMediaButton(
              icon: Icons.business,
              label: 'LinkedIn',
              backgroundColor: const Color(0xFF0A66C2),
              onTap: () => _openSocialMediaProfile(channel),
            );
          case ChannelKind.instagram:
            return _buildSocialMediaButton(
              icon: Icons.camera_alt,
              label: 'Instagram',
              backgroundColor: const Color(0xFFE1306C),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFCAF45),
                  Color(0xFFE1306C),
                  Color(0xFF833AB4),
                ],
              ),
              onTap: () => _openSocialMediaProfile(channel),
            );
          case ChannelKind.whatsapp:
            return _buildSocialMediaButton(
              icon: Icons.chat,
              label: 'WhatsApp',
              backgroundColor: const Color(0xFF25D366),
              onTap: () => _openSocialMediaProfile(channel),
            );
          case ChannelKind.messenger:
            return _buildSocialMediaButton(
              icon: Icons.message,
              label: 'Messenger',
              backgroundColor: const Color(0xFF0088CC),
              onTap: () => _openSocialMediaProfile(channel),
            );
          case 'mobile':
            return _buildSocialMediaButton(
              icon: Icons.phone,
              label: 'Call',
              backgroundColor: const Color(0xFF4CAF50),
              onTap: () => _openSocialMediaProfile(channel),
            );
          case 'email':
            return _buildSocialMediaButton(
              icon: Icons.email,
              label: 'Email',
              backgroundColor: const Color(0xFF2196F3),
              onTap: () => _openSocialMediaProfile(channel),
            );
          default:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  Widget _buildSocialMediaManagementSection() {
    return AppCard(
      padding: const EdgeInsets.all(OmadaTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Manage Social Media',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: OmadaTokens.space16),
          
          // Current Social Media Channels
          if (_contactChannels.any((channel) => _isSocialMediaPlatform(channel.kind))) ...[
            Text(
              'Current Social Media:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ..._contactChannels
                .where((channel) => _isSocialMediaPlatform(channel.kind))
                .map((channel) => _buildChannelItem(channel))
                .toList(),
            const SizedBox(height: OmadaTokens.space16),
          ],
          
          // Add New Social Media Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddSocialMediaDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Social Media'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: OmadaTokens.space12,
                  horizontal: OmadaTokens.space16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelItem(ContactChannelModel channel) {
    String platformName;
    IconData platformIcon;
    Color platformColor;
    
    switch (channel.kind) {
      case ChannelKind.linkedin:
        platformName = 'LinkedIn';
        platformIcon = Icons.business;
        platformColor = const Color(0xFF0A66C2);
        break;
      case ChannelKind.instagram:
        platformName = 'Instagram';
        platformIcon = Icons.camera_alt;
        platformColor = const Color(0xFFE1306C);
        break;
      case ChannelKind.whatsapp:
        platformName = 'WhatsApp';
        platformIcon = Icons.chat;
        platformColor = const Color(0xFF25D366);
        break;
      case ChannelKind.messenger:
        platformName = 'Messenger';
        platformIcon = Icons.message;
        platformColor = const Color(0xFF0088CC);
        break;
      case 'mobile':
        platformName = 'Mobile';
        platformIcon = Icons.phone;
        platformColor = const Color(0xFF4CAF50);
        break;
      case 'email':
        platformName = 'Email';
        platformIcon = Icons.email;
        platformColor = const Color(0xFF2196F3);
        break;
      default:
        platformName = channel.kind;
        platformIcon = Icons.link;
        platformColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: platformColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: platformColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(platformIcon, color: platformColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platformName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: platformColor,
                  ),
                ),
                if (channel.value?.isNotEmpty == true)
                  Text(
                    channel.value!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => _deleteChannel(channel),
            color: Colors.red[400],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onTap,
    LinearGradient? gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          color: gradient != null ? null : backgroundColor,
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateNameFields() {
    final given = _givenNameController.text.trim();
    final family = _familyNameController.text.trim();
    
    // At least one name field must be provided
    if (given.isEmpty && family.isEmpty) {
      return 'Please provide at least a given name or family name';
    }
    
    // Validate given name if provided
    if (given.isNotEmpty && !ValidationUtils.isValidContactName(given)) {
      return 'Invalid given name';
    }
    
    // Validate family name if provided
    if (family.isNotEmpty && !ValidationUtils.isValidContactName(family)) {
      return 'Invalid family name';
    }
    
    return null;
  }

  Future<void> _loadTags({String? contactId}) async {
    try {
      final tags = await _controller.getAllTags();
      if (!mounted) return;
      setState(() => _allTags = tags);

      if (contactId != null) {
        final existing = await _controller.getTagsForContact(contactId);
        if (!mounted) return;
        setState(
          () => _selectedTagIds
            ..clear()
            ..addAll(existing.map((t) => t.id)),
        );
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadChannels({String? contactId}) async {
    if (contactId == null) return;
    
    try {
      final channels = await _controller.getChannelsForContact(contactId);
      if (!mounted) return;
      setState(() => _contactChannels = channels);
    } catch (e) {
      // Ignore errors for MVP
    }
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = _primaryMobileController.text.trim();
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this contact'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone dialer'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not make phone call: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final phoneNumber = _primaryMobileController.text.trim();
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this contact'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch messaging app'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send message: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _sendEmail() async {
    final email = _primaryEmailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email address available for this contact'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
      );
      
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch email app'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send email: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showAddSocialMediaDialog() async {
    final selectedPlatform = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Social Media'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a platform:'),
            const SizedBox(height: 16),
            ..._getSocialMediaPlatforms().map((platform) => 
              ListTile(
                leading: Icon(_getPlatformIcon(platform)),
                title: Text(_getPlatformDisplayName(platform)),
                onTap: () => Navigator.pop(context, platform),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedPlatform != null) {
      _showAddChannelDialog(selectedPlatform);
    }
  }

  Future<void> _showAddChannelDialog(String platform) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $platform'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter the $platform username or URL:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: '$platform username or URL',
                  hintText: _getPlatformHint(platform),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return 'Please enter a $platform username or URL';
                  }
                  return null;
                },
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && widget.contact != null) {
      await _addChannel(platform, controller.text.trim());
    }
  }

  Future<void> _addChannel(String platform, String value) async {
    try {
      // Add the channel using the controller
      await _controller.addChannel(
        contactId: widget.contact!.id,
        kind: platform,
        value: value,
      );
      
      // Reload channels to update the UI
      await _loadChannels(contactId: widget.contact!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$platform added successfully'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add $platform: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteChannel(ContactChannelModel channel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Social Media'),
        content: Text('Are you sure you want to remove ${channel.kind} from this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.deleteChannel(channel.id);
        
        // Reload channels to update the UI
        await _loadChannels(contactId: widget.contact!.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${channel.kind} removed successfully'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove ${channel.kind}: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case ChannelKind.linkedin:
        return Icons.business;
      case ChannelKind.instagram:
        return Icons.camera_alt;
      case ChannelKind.whatsapp:
        return Icons.chat;
      case ChannelKind.messenger:
        return Icons.message;
      default:
        return Icons.link;
    }
  }

  String _getPlatformHint(String platform) {
    switch (platform) {
      case ChannelKind.linkedin:
        return 'e.g., john-doe or linkedin.com/in/john-doe';
      case ChannelKind.instagram:
        return 'e.g., @johndoe or instagram.com/johndoe';
      case ChannelKind.whatsapp:
        return 'e.g., +1234567890 or phone number';
      case ChannelKind.messenger:
        return 'e.g., username or Facebook profile link';
      default:
        return 'Enter username or URL';
    }
  }

  /// Returns true if the platform is a social media platform
  bool _isSocialMediaPlatform(String platform) {
    return [
      ChannelKind.linkedin,
      ChannelKind.instagram,
      ChannelKind.whatsapp,
      ChannelKind.messenger,
      'mobile',
      'email',
    ].contains(platform);
  }

  /// Returns the list of supported social media platforms
  List<String> _getSocialMediaPlatforms() {
    return [
      ChannelKind.linkedin,
      ChannelKind.instagram,
      ChannelKind.whatsapp,
      ChannelKind.messenger, // Using telegram as messenger since there's no specific messenger channel
    ];
  }

  /// Returns the display name for a platform
  String _getPlatformDisplayName(String platform) {
    switch (platform) {
      case ChannelKind.linkedin:
        return 'LinkedIn';
      case ChannelKind.instagram:
        return 'Instagram';
      case ChannelKind.whatsapp:
        return 'WhatsApp';
      case ChannelKind.messenger:
        return 'Messenger';
      default:
        return platform;
    }
  }

  Future<void> _openSocialMediaProfile(ContactChannelModel channel) async {
    if (channel.value?.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No ${_getPlatformDisplayName(channel.kind)} profile available'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      String url;
      final value = channel.value!;

      switch (channel.kind) {
        case ChannelKind.linkedin:
          // Handle different LinkedIn URL formats
          if (value.startsWith('http')) {
            url = value;
          } else if (value.startsWith('linkedin.com')) {
            url = 'https://$value';
          } else {
            // Assume it's a username/profile name
            url = 'https://linkedin.com/in/$value';
          }
          break;
          
        case ChannelKind.instagram:
          // Handle different Instagram URL formats
          if (value.startsWith('http')) {
            url = value;
          } else if (value.startsWith('instagram.com')) {
            url = 'https://$value';
          } else {
            // Remove @ if present and assume it's a username
            final username = value.startsWith('@') ? value.substring(1) : value;
            url = 'https://instagram.com/$username';
          }
          break;
          
        case ChannelKind.whatsapp:
          // Handle phone numbers for WhatsApp
          if (value.startsWith('http')) {
            url = value;
          } else {
            // Clean phone number and create WhatsApp URL
            final phoneNumber = value.replaceAll(RegExp(r'[^\d+]'), '');
            url = 'https://wa.me/$phoneNumber';
          }
          break;
          
        case ChannelKind.messenger:
          // Handle Facebook Messenger URLs
          if (value.startsWith('http')) {
            url = value;
          } else if (value.startsWith('m.me') || value.startsWith('facebook.com/messages')) {
            url = 'https://$value';
          } else {
            // Try to open Facebook Messenger with the contact
            // For Messenger, we can try to open the app or web version
            url = 'https://m.me/$value';
          }
          break;
          
        case 'mobile':
          // Handle mobile phone calls
          if (value.startsWith('tel:')) {
            url = value;
          } else {
            url = 'tel:$value';
          }
          break;
          
        case 'email':
          // Handle email
          if (value.startsWith('mailto:')) {
            url = value;
          } else {
            url = 'mailto:$value';
          }
          break;
          
        default:
          url = value;
      }

      final Uri uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open ${_getPlatformDisplayName(channel.kind)} profile'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening ${_getPlatformDisplayName(channel.kind)}: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildTagSection() {
    return Padding(
      padding: const EdgeInsets.all(OmadaTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tags',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (!_isEditing)
              TextButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Tags'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: OmadaTokens.space8),
        Wrap(
          spacing: OmadaTokens.space8,
          runSpacing: OmadaTokens.space8,
          children: [
            if (_isEditing) ...[
              // Show all tags as editable FilterChips when editing
              ..._allTags.map((tag) {
                final selected = _selectedTagIds.contains(tag.id);
                return FilterChip(
                  label: Text(tag.name),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedTagIds.add(tag.id);
                      } else {
                        _selectedTagIds.remove(tag.id);
                      }
                    });
                  },
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Add tag'),
                onPressed: _promptCreateTag,
              ),
            ] else ...[
              // Show only selected tags as read-only chips when not editing
              ..._allTags
                  .where((tag) => _selectedTagIds.contains(tag.id))
                  .map(
                    (tag) => Chip(
                      label: Text(tag.name),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
            ],
          ],
        ),
        ],
      ),
    );
  }

  Future<void> _promptCreateTag() async {
    final TextEditingController nameController = TextEditingController();
    bool saving = false;

    Future<void> submit(void Function(void Function()) setDialogState) async {
      final name = nameController.text.trim();
      if (name.isEmpty) return;
      setDialogState(() => saving = true);
      try {
        TagModel? tag;
        try {
          tag = await _controller.createTag(name);
        } catch (e) {
          // On conflict, fetch existing and select it
          final existing = await _controller.getTagByName(name);
          if (existing != null) {
            tag = existing;
          } else {
            rethrow;
          }
        }

        if (!mounted) return;
        setState(() {
          final exists = _allTags.any((t) => t.id == tag!.id);
          if (!exists) {
            _allTags = [..._allTags, tag!];
          }
          _selectedTagIds.add(tag!.id);
        });
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add tag: $e')));
      } finally {
        // leave dialog closing to success path
      }
    }

    if (!mounted) return;
    // ignore: use_build_context_synchronously
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New tag'),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tag name',
                  hintText: 'e.g., Family, Work',
                ),
                autofocus: true,
                onSubmitted: (_) => submit(setDialogState),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving ? null : () => submit(setDialogState),
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
