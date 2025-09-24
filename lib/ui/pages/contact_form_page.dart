import 'package:flutter/material.dart';
import 'package:omada/core/data/models/contact_model.dart';
import 'package:omada/core/data/services/contact_service.dart';
import 'package:omada/core/data/utils/validation_utils.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'package:omada/core/data/services/tag_service.dart';
import 'package:omada/core/data/models/tag_model.dart';

class ContactFormPage extends StatefulWidget {
  final ContactModel? contact;

  const ContactFormPage({super.key, this.contact});

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final ContactService _contactService;
  late final TagService _tagService;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _givenNameController = TextEditingController();
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _primaryMobileController =
      TextEditingController();
  final TextEditingController _primaryEmailController = TextEditingController();

  bool _submitting = false;
  List<TagModel> _allTags = [];
  final Set<String> _selectedTagIds = <String>{};

  @override
  void initState() {
    super.initState();
    _contactService = ContactService(supabase);
    _tagService = TagService(supabase);

    final contact = widget.contact;
    if (contact != null) {
      _fullNameController.text = contact.fullName ?? '';
      _givenNameController.text = contact.givenName ?? '';
      _familyNameController.text = contact.familyName ?? '';
      _primaryMobileController.text = contact.primaryMobile ?? '';
      _primaryEmailController.text = contact.primaryEmail ?? '';
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
        : ValidationUtils.sanitizeString(_fullNameController.text);
    final givenName = _givenNameController.text.trim().isEmpty
        ? null
        : ValidationUtils.sanitizeString(_givenNameController.text);
    final familyName = _familyNameController.text.trim().isEmpty
        ? null
        : ValidationUtils.sanitizeString(_familyNameController.text);
    final primaryMobile = _primaryMobileController.text.trim();
    final primaryEmail = _primaryEmailController.text.trim().isEmpty
        ? null
        : ValidationUtils.normalizeEmail(_primaryEmailController.text);

    try {
      if (widget.contact == null) {
        await _contactService.createContact(
          fullName: fullName,
          givenName: givenName,
          familyName: familyName,
          primaryMobile: primaryMobile,
          primaryEmail: primaryEmail,
          tagIds: _selectedTagIds.toList(),
        );
      } else {
        await _contactService.updateContact(
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
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Contact' : 'New Contact')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                textCapitalization: TextCapitalization.words,
                validator: (_) => _validateNameFields(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _givenNameController,
                      decoration: const InputDecoration(
                        labelText: 'Given name',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (_) => _validateNameFields(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _familyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Family name',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (_) => _validateNameFields(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _primaryMobileController,
                decoration: const InputDecoration(
                  labelText: 'Primary mobile',
                  hintText: '+1 555 123 4567',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Mobile number is required';
                  if (!ValidationUtils.isValidPhoneNumber(v)) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _primaryEmailController,
                decoration: const InputDecoration(
                  labelText: 'Primary email (optional)',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return null;
                  if (!ValidationUtils.isValidEmail(v)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildTagSection(),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting ? null : _save,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isEditing ? 'Save changes' : 'Create contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateNameFields() {
    final full = _fullNameController.text.trim();
    final given = _givenNameController.text.trim();
    final family = _familyNameController.text.trim();

    if (full.isEmpty && given.isEmpty && family.isEmpty) {
      return 'Provide full name or given/family name';
    }
    if (full.isNotEmpty && !ValidationUtils.isValidContactName(full)) {
      return 'Invalid full name';
    }
    if (given.isNotEmpty && !ValidationUtils.isValidContactName(given)) {
      return 'Invalid given name';
    }
    if (family.isNotEmpty && !ValidationUtils.isValidContactName(family)) {
      return 'Invalid family name';
    }
    return null;
  }

  Future<void> _loadTags({String? contactId}) async {
    try {
      final tags = await _tagService.getTags();
      if (!mounted) return;
      setState(() => _allTags = tags);

      if (contactId != null) {
        final existing = await _tagService.getTagsForContact(contactId);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
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
          ],
        ),
      ],
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
          tag = await _tagService.createTag(name);
        } catch (e) {
          // On conflict, fetch existing and select it
          final existing = await _tagService.getTagByName(name);
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
