import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/utils/channel_presets.dart';
import '../data/repositories/contact_channel_repository.dart';

class AddChannelSheet extends StatefulWidget {
  final String contactId;
  const AddChannelSheet({super.key, required this.contactId});

  @override
  State<AddChannelSheet> createState() => _AddChannelSheetState();
}

class _AddChannelSheetState extends State<AddChannelSheet> {
  String _selectedKind = 'mobile';
  final TextEditingController _labelCtrl = TextEditingController(
    text: 'Mobile',
  );
  final TextEditingController _valueCtrl = TextEditingController();
  final TextEditingController _urlPreviewCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _updateUrlPreview();
  }

  void _updateUrlPreview() {
    _urlPreviewCtrl.text = ChannelPresets.computeUrl(
      _selectedKind,
      _valueCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final presets = ChannelPresets.presets;
    final hint = presets[_selectedKind]!;
    final valueLabel = _selectedKind == 'instagram'
        ? 'Username'
        : _selectedKind == 'linkedin'
        ? 'Handle'
        : 'Value';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Channel',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              DropdownButton<String>(
                value: _selectedKind,
                items: presets.keys
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (k) {
                  if (k == null) return;
                  setState(() {
                    _selectedKind = k;
                    _labelCtrl.text = presets[k]!['label']!;
                    _updateUrlPreview();
                  });
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Label'),
                  controller: _labelCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: valueLabel,
              hintText: hint['valueHint'],
            ),
            controller: _valueCtrl,
            onChanged: (_) => setState(_updateUrlPreview),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: 'URL (auto)',
              hintText: ChannelPresets.computeUrl(
                _selectedKind,
                hint['valueHint']!,
              ),
            ),
            controller: _urlPreviewCtrl,
            readOnly: true,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ContactChannelRepository(Supabase.instance.client);
      final value = _valueCtrl.text.trim();
      final url = ChannelPresets.computeUrl(_selectedKind, value);
      await repo.createChannel(
        contactId: widget.contactId,
        kind: _selectedKind,
        label: _labelCtrl.text.trim().isEmpty
            ? ChannelPresets.presets[_selectedKind]!['label']
            : _labelCtrl.text.trim(),
        value: value.isEmpty ? null : value,
        url: url.isEmpty ? null : url,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add channel: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
