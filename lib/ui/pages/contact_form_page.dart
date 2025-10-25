import 'package:flutter/material.dart';
import 'package:omada/core/data/models/contact_model.dart';
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

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _givenNameController = TextEditingController();
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _primaryMobileController =
      TextEditingController();
  final TextEditingController _primaryEmailController = TextEditingController();

  bool _submitting = false;
  bool _isEditing = false;
  List<TagModel> _allTags = [];
  final Set<String> _selectedTagIds = <String>{};

  @override
  void initState() {
    super.initState();
    _controller = ContactFormController(supabase);

    final contact = widget.contact;
    if (contact != null) {
      // If editing an existing contact, start in read-only mode
      _isEditing = false;
      _fullNameController.text = contact.fullName ?? '';
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
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _givenNameController.dispose();
    _familyNameController.dispose();
    _primaryMobileController.dispose();
    _primaryEmailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final fullName = _fullNameController.text.trim().isEmpty
        ? null
        : _fullNameController.text.trim();
    final givenName = _givenNameController.text.trim().isEmpty
        ? null
        : _givenNameController.text.trim();
    final familyName = _familyNameController.text.trim().isEmpty
        ? null
        : _familyNameController.text.trim();
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
                                  onTap: () {
                                    // TODO: Implement call functionality
                                  },
                                ),
                                _buildQuickActionButton(
                                  icon: Icons.message,
                                  label: 'Message',
                                  onTap: () {
                                    // TODO: Implement message functionality
                                  },
                                ),
                                _buildQuickActionButton(
                                  icon: Icons.email,
                                  label: 'Email',
                                  onTap: () {
                                    // TODO: Implement email functionality
                                  },
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
                            // Full Name Field
                            _buildFormFieldWithIcon(
                              icon: Icons.person,
                              label: 'Full Name',
                              controller: _fullNameController,
                              validator: _isEditing
                                  ? (_) => _validateNameFields()
                                  : null,
                              textCapitalization: TextCapitalization.words,
                              enabled: _isEditing,
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
                            // Social Media Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSocialMediaButton(
                                  icon: Icons.business,
                                  label: 'LinkedIn',
                                  backgroundColor: const Color(0xFF0A66C2),
                                  onTap: () {
                                    // TODO: Implement LinkedIn functionality
                                  },
                                ),
                                _buildSocialMediaButton(
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
                                  onTap: () {
                                    // TODO: Implement Instagram functionality
                                  },
                                ),
                                _buildSocialMediaButton(
                                  icon: Icons.alternate_email,
                                  label: 'Twitter',
                                  backgroundColor: const Color(0xFF1DA1F2),
                                  onTap: () {
                                    // TODO: Implement Twitter functionality
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
        _fullNameController.text = contact.fullName ?? '';
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
    return _controller.validateNameTriplet(
      full: _fullNameController.text.trim(),
      given: _givenNameController.text.trim(),
      family: _familyNameController.text.trim(),
    );
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
