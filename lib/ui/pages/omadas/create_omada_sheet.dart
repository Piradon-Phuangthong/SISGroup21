import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/data/services/omada_service_extended.dart';

class CreateOmadaSheet extends StatefulWidget {
  final Function(OmadaModel) onCreated;

  const CreateOmadaSheet({super.key, required this.onCreated});

  @override
  State<CreateOmadaSheet> createState() => _CreateOmadaSheetState();
}

class _CreateOmadaSheetState extends State<CreateOmadaSheet> {
  late final OmadaServiceExtended _service;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  JoinPolicy _joinPolicy = JoinPolicy.approval;
  bool _isPublic = true;
  bool _isLoading = false;
  String? _selectedColor;

  final List<String> _colors = [
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#96CEB4', // Green
    '#FFEAA7', // Yellow
    '#DFE6E9', // Gray
    '#A29BFE', // Purple
    '#FD79A8', // Pink
  ];

  @override
  void initState() {
    super.initState();
    _service = OmadaServiceExtended(Supabase.instance.client);
    _selectedColor = _colors[0];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _createOmada() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final omada = await _service.createOmada(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        color: _selectedColor,
        joinPolicy: _joinPolicy,
        isPublic: _isPublic,
      );

      widget.onCreated(omada);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Omada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g., Family, Work, Friends',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this group about?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _colors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<JoinPolicy>(
              value: _joinPolicy,
              decoration: const InputDecoration(
                labelText: 'Join Policy',
                border: OutlineInputBorder(),
              ),
              items: JoinPolicy.values.map((policy) {
                return DropdownMenuItem(
                  value: policy,
                  child: Text(policy.displayName),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (value) => setState(() => _joinPolicy = value!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Public'),
              subtitle: const Text('Allow others to discover this Omada'),
              value: _isPublic,
              onChanged: _isLoading
                  ? null
                  : (value) => setState(() => _isPublic = value),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createOmada,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Omada'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
