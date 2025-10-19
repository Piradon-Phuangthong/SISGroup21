import 'package:flutter/material.dart';
import 'package:omada/core/data/models/contact_model.dart';
import 'package:omada/core/controllers/contacts_controller.dart';
import 'package:omada/core/supabase/supabase_instance.dart';

class DeletedContactsPage extends StatefulWidget {
  const DeletedContactsPage({super.key});

  @override
  State<DeletedContactsPage> createState() => _DeletedContactsPageState();
}

class _DeletedContactsPageState extends State<DeletedContactsPage> {
  late final ContactsController _controller;
  final _search = TextEditingController();
  List<ContactModel> _deleted = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = ContactsController(supabase);
    _load();
    _search.addListener(() => _load(debounce: true));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  DateTime? _lastChange;
  Future<void> _load({bool debounce = false}) async {
    if (debounce) {
      _lastChange = DateTime.now();
      await Future.delayed(const Duration(milliseconds: 300));
      if (DateTime.now().difference(_lastChange!) <
          const Duration(milliseconds: 300)) {
        return;
      }
    }
    setState(() { _loading = true; _error = null; });
    try {
      final results = await _controller.getDeletedContacts(
        searchTerm: _search.text.trim().isEmpty ? null : _search.text.trim(),
      );
      setState(() { _deleted = results; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore(ContactModel c) async {
    try {
      await _controller.restoreContact(c.id);
      if (!mounted) return;
      setState(() => _deleted.removeWhere((e) => e.id == c.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored ${c.displayName}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore: $e')),
      );
    }
  }

  Future<void> _permanentDelete(ContactModel c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text('This will permanently delete "${c.displayName}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _controller.permanentlyDeleteContact(c.id);
      if (!mounted) return;
      setState(() => _deleted.removeWhere((e) => e.id == c.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permanently deleted ${c.displayName}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted contacts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search deleted...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () { _search.clear(); _load(); },
                      ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _deleted.isEmpty
                        ? const Center(child: Text('Trash is empty'))
                        : ListView.separated(
                            itemCount: _deleted.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final c = _deleted[i];
                              return ListTile(
                                leading: const Icon(Icons.person_off_outlined),
                                title: Text(c.displayName),
                                subtitle: Text(c.primaryEmail ?? c.primaryMobile ?? 'No contact details'),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: () => _restore(c),
                                      child: const Text('Restore'),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete permanently',
                                      icon: const Icon(Icons.delete_forever_outlined),
                                      onPressed: () => _permanentDelete(c),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
