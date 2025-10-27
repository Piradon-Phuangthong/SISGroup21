import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/services/omada_service.dart';
import 'package:omada/core/data/services/omada_service_extended.dart';
import 'package:omada/core/data/services/contact_service.dart';
import 'package:omada/core/data/models/models.dart';

class OmadasTestPage extends StatefulWidget {
  const OmadasTestPage({super.key});

  @override
  State<OmadasTestPage> createState() => _OmadasTestPageState();
}

class _OmadasTestPageState extends State<OmadasTestPage> {
  late final OmadaService _omadaService;
  late final OmadaServiceExtended _omadaServiceExtended;
  late final ContactService _contactService;

  List<OmadaModel> _omadas = [];
  List<OmadaModel> _publicOmadas = [];
  List<OmadaModel> _debugAllPublic = [];
  List<ContactModel> _contacts = [];
  OmadaModel? _selectedOmada;
  List<String> _selectedOmadaMembers = [];

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String? _status;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _omadaService = OmadaService(client);
    _omadaServiceExtended = OmadaServiceExtended(client);
    _contactService = ContactService(client);
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final omadas = await _omadaService.getOmadas();
      final contacts = await _contactService.getContacts();
      final stats = await _omadaService.getOmadaStats();

      setState(() {
        _omadas = omadas;
        _contacts = contacts;
        _stats = stats;
      });
    } catch (e) {
      setState(() => _status = 'Error loading: $e');
    }
  }

  Future<void> _loadOmadaMembers(OmadaModel omada) async {
    try {
      final members = await _omadaService.getOmadaMembers(omada.id);
      setState(() {
        _selectedOmada = omada;
        _selectedOmadaMembers = members;
      });
    } catch (e) {
      setState(() => _status = 'Error loading members: $e');
    }
  }

  Future<void> _createOmada() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _status = 'Name is required');
      return;
    }

    try {
      await _omadaService.createOmada(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      );

      _clearInputs();
      await _loadData();
      setState(() => _status = 'Omada created successfully');
    } catch (e) {
      setState(() => _status = 'Error creating: $e');
    }
  }

  Future<void> _updateOmada(OmadaModel omada) async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _status = 'Name is required');
      return;
    }

    try {
      await _omadaService.updateOmada(
        omada.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      );

      _clearInputs();
      await _loadData();
      setState(() => _status = 'Omada updated successfully');
    } catch (e) {
      setState(() => _status = 'Error updating: $e');
    }
  }

  Future<void> _deleteOmada(OmadaModel omada) async {
    try {
      await _omadaService.permanentlyDeleteOmada(omada.id);

      if (_selectedOmada?.id == omada.id) {
        setState(() {
          _selectedOmada = null;
          _selectedOmadaMembers = [];
        });
      }

      await _loadData();
      setState(() => _status = 'Omada deleted');
    } catch (e) {
      setState(() => _status = 'Error deleting: $e');
    }
  }

  Future<void> _addContactToOmada(String contactId) async {
    if (_selectedOmada == null) return;

    try {
      await _omadaService.addContactToOmada(_selectedOmada!.id, contactId);
      await _loadOmadaMembers(_selectedOmada!);
      await _loadData(); // Refresh counts
      setState(() => _status = 'Contact added to omada');
    } catch (e) {
      setState(() => _status = 'Error adding contact: $e');
    }
  }

  Future<void> _removeContactFromOmada(String contactId) async {
    if (_selectedOmada == null) return;

    try {
      await _omadaService.removeContactFromOmada(_selectedOmada!.id, contactId);
      await _loadOmadaMembers(_selectedOmada!);
      await _loadData(); // Refresh counts
      setState(() => _status = 'Contact removed from omada');
    } catch (e) {
      setState(() => _status = 'Error removing contact: $e');
    }
  }

  Future<void> _seedSampleOmadas() async {
    setState(() => _status = 'Seeding omadas...');

    try {
      final samples = [
        {
          'name': 'Family',
          'description': 'Family members and close relatives',
          'color': '#FF6B6B',
        },
        {
          'name': 'Work',
          'description': 'Work colleagues and professional contacts',
          'color': '#4ECDC4',
        },
        {
          'name': 'Friends',
          'description': 'Personal friends and social circle',
          'color': '#45B7D1',
        },
        {
          'name': 'University',
          'description': 'University classmates and professors',
          'color': '#96CEB4',
        },
        {
          'name': 'Sports Team',
          'description': 'Team members and coaching staff',
          'color': '#FFEAA7',
        },
      ];

      for (final sample in samples) {
        await _omadaService.createOmada(
          name: sample['name']!,
          description: sample['description']!,
          color: sample['color']!,
        );
      }

      await _loadData();
      setState(() => _status = 'Seeded ${samples.length} omadas');
    } catch (e) {
      setState(() => _status = 'Error seeding: $e');
    }
  }

  Future<void> _testDiscovery() async {
    // Ensure services are initialized (in case of hot reload issues)
    if (!mounted) return;

    setState(() {
      _status = 'Testing discovery...';
      _publicOmadas = [];
    });

    try {
      print('🔍 Starting discovery test...');

      // Reinitialize service if needed (hot reload safety)
      final service = _omadaServiceExtended;

      final discoverable = await service.getPublicOmadas();
      print('✅ Discovery returned ${discoverable.length} omadas');

      if (!mounted) return;
      setState(() {
        _publicOmadas = discoverable;
        _status =
            'Discovery: Found ${discoverable.length} public omadas from other users';
      });
    } catch (e, stackTrace) {
      print('❌ Discovery failed: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _status = 'Discovery error: $e');
    }
  }

  Future<void> _debugLoadAllPublic() async {
    final service = _omadaServiceExtended;
    setState(() {
      _debugAllPublic = [];
    });
    try {
      final allPublic = await service.getDebugPublicOmadasAll();
      if (!mounted) return;
      setState(() {
        _debugAllPublic = allPublic;
      });
      // ignore: avoid_print
      print(
        '🧪 Debug: Loaded ${allPublic.length} public omadas (including my own)',
      );
      if (allPublic.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debug: No public omadas exist at all.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug fetch failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearInputs() {
    _nameCtrl.clear();
    _descCtrl.clear();
    _colorCtrl.clear();
  }

  void _fillForEdit(OmadaModel omada) {
    _nameCtrl.text = omada.name;
    _descCtrl.text = omada.description ?? '';
    _colorCtrl.text = omada.color ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Omadas (Groups) Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            if (_status != null)
              Card(
                color: _status!.contains('Error')
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _status!.contains('Error')
                            ? Icons.error
                            : Icons.check_circle,
                        color: _status!.contains('Error')
                            ? Colors.red
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_status!)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _status = null),
                      ),
                    ],
                  ),
                ),
              ),

            if (_debugAllPublic.isNotEmpty) ...[
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Debug: ALL public omadas (including your own) — ${_debugAllPublic.length} found',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._debugAllPublic.map(
                      (o) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(o.name),
                        subtitle: Text(
                          'Owner: ${o.ownerId.substring(0, 8)}… • Members: ${o.memberCount ?? 0} • ${o.isPublic ? 'Public' : 'Private'}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Statistics
            if (_stats != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Omada Statistics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Total Omadas: ${_stats!['total_omadas']}'),
                      Text(
                        'Total Memberships: ${_stats!['total_memberships']}',
                      ),
                      Text('Empty Omadas: ${_stats!['empty_omadas']}'),
                      Text('Avg Members: ${_stats!['avg_members_per_omada']}'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Create/Update form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create/Update Omada',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _colorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Color (hex)',
                        hintText: '#FF6B6B',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _createOmada,
                          icon: const Icon(Icons.add),
                          label: const Text('Create'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _clearInputs,
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: _seedSampleOmadas,
                          icon: const Icon(Icons.eco),
                          label: const Text('Seed Sample'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Discovery Test Section
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.explore, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Discovery Test (Public Omadas from Other Users)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _testDiscovery,
                      icon: const Icon(Icons.search),
                      label: const Text('Test Discovery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Tip: Discovery excludes your own groups and ones you\'re a member of. Use Debug to see if any public omadas exist at all.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _debugLoadAllPublic,
                          child: const Text('Debug: All Public'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_publicOmadas.isEmpty)
                      const Text(
                        'No results yet. Click "Test Discovery" to find public omadas.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Found ${_publicOmadas.length} public omadas:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._publicOmadas.map(
                            (omada) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: omada.color != null
                                    ? _parseColor(omada.color!)
                                    : Colors.grey,
                                child: const Icon(
                                  Icons.group,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(omada.name),
                              subtitle: Text(
                                omada.description ?? 'No description',
                              ),
                              trailing: Text(
                                '${omada.memberCount ?? 0} members',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_debugAllPublic.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      Text(
                        'Debug: ALL public omadas (including yours) — ${_debugAllPublic.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._debugAllPublic.map(
                        (omada) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: omada.color != null
                                ? _parseColor(omada.color!)
                                : Colors.grey,
                            child: const Icon(
                              Icons.group,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(omada.name),
                          subtitle: Text(omada.description ?? 'No description'),
                          trailing: Text(
                            'Owner: ${omada.ownerId.substring(0, 8)}…',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Omadas list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Omadas (${_omadas.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_omadas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text('No omadas yet. Create one above!'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _omadas.length,
                        itemBuilder: (context, index) {
                          final omada = _omadas[index];
                          final isSelected = _selectedOmada?.id == omada.id;

                          return Card(
                            color: isSelected ? Colors.blue.shade50 : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: omada.color != null
                                    ? _parseColor(omada.color!)
                                    : Colors.grey,
                                child: Text(
                                  omada.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(omada.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (omada.description != null)
                                    Text(omada.description!),
                                  Text(
                                    '${omada.memberCount ?? 0} members',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _fillForEdit(omada),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _deleteOmada(omada),
                                  ),
                                ],
                              ),
                              onTap: () => _loadOmadaMembers(omada),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Selected omada members
            if (_selectedOmada != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Members of "${_selectedOmada!.name}" (${_selectedOmadaMembers.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _selectedOmada = null;
                              _selectedOmadaMembers = [];
                            }),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (_selectedOmadaMembers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text('No members in this omada'),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedOmadaMembers.length,
                          itemBuilder: (context, index) {
                            final contactId = _selectedOmadaMembers[index];
                            final contact = _contacts.firstWhere(
                              (c) => c.id == contactId,
                              orElse: () => ContactModel(
                                id: contactId,
                                ownerId: '',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            );

                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  (contact.fullName ?? '?')[0].toUpperCase(),
                                ),
                              ),
                              title: Text(contact.fullName ?? 'Unknown'),
                              subtitle: Text(
                                contact.primaryEmail ??
                                    contact.primaryMobile ??
                                    '',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () =>
                                    _removeContactFromOmada(contactId),
                              ),
                            );
                          },
                        ),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Add Contacts:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
                            final isMember = _selectedOmadaMembers.contains(
                              contact.id,
                            );

                            if (isMember) return const SizedBox.shrink();

                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                child: Text(
                                  (contact.fullName ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              title: Text(contact.fullName ?? 'Unknown'),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _addContactToOmada(contact.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
