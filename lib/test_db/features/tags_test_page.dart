import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/tag_service.dart';
import '../../data/models/models.dart';

class TagsTestPage extends StatefulWidget {
  const TagsTestPage({super.key});

  @override
  State<TagsTestPage> createState() => _TagsTestPageState();
}

class _TagsTestPageState extends State<TagsTestPage> {
  late final TagService _service;
  List<TagModel> _tags = [];
  final _tagNameCtrl = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    _service = TagService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    try {
      _tags = await _service.getTags();
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _create() async {
    try {
      final name = _tagNameCtrl.text.trim();
      if (name.isEmpty) return;
      await _service.createTag(name);
      _tagNameCtrl.clear();
      await _load();
      setState(() => _status = 'Created');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _rename(TagModel t) async {
    try {
      final newName = await _promptRename(context, current: t.name);
      if (newName == null || newName.trim().isEmpty) return;
      await _service.renameTag(t.id, newName.trim());
      await _load();
      setState(() => _status = 'Renamed');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _delete(TagModel t) async {
    try {
      await _service.deleteTag(t.id);
      await _load();
      setState(() => _status = 'Deleted');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tags Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagNameCtrl,
                    decoration: const InputDecoration(labelText: 'Tag name'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _create, child: const Text('Create')),
              ],
            ),
            const SizedBox(height: 12),
            if (_status != null)
              Align(alignment: Alignment.centerLeft, child: Text(_status!)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _tags.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final t = _tags[index];
                  return ListTile(
                    title: Text(t.name),
                    subtitle: Text(t.id),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          onPressed: () => _rename(t),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          onPressed: () => _delete(t),
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _promptRename(
    BuildContext context, {
    required String current,
  }) async {
    final ctrl = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Tag'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
