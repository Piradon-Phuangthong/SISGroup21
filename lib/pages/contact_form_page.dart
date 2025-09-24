import 'package:flutter/material.dart';
import '../data/models/contact_model.dart';
import '../data/services/contact_service.dart';
import '../data/utils/validation_utils.dart';
import '../supabase/supabase_instance.dart';

class ContactFormPage extends StatefulWidget {
  final ContactModel? contact;

  const ContactFormPage({super.key, this.contact});

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final ContactService _contactService;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _givenNameController = TextEditingController();
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _primaryMobileController =
      TextEditingController();
  final TextEditingController _primaryEmailController = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _contactService = ContactService(supabase);

    final contact = widget.contact;
    if (contact != null) {
      _fullNameController.text = contact.fullName ?? '';
      _givenNameController.text = contact.givenName ?? '';
      _familyNameController.text = contact.familyName ?? '';
      _primaryMobileController.text = contact.primaryMobile ?? '';
      _primaryEmailController.text = contact.primaryEmail ?? '';
    }
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
        );
      } else {
        await _contactService.updateContact(
          widget.contact!.id,
          fullName: fullName,
          givenName: givenName,
          familyName: familyName,
          primaryMobile: primaryMobile,
          primaryEmail: primaryEmail,
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
}
