import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/data/services/omada_service_extended.dart';

/// E9 User Story: Debug Omada Members
/// Shows all members of an omada with their roles for debugging purposes
class OmadaMembersDebugPage extends StatefulWidget {
  const OmadaMembersDebugPage({super.key});

  @override
  State<OmadaMembersDebugPage> createState() => _OmadaMembersDebugPageState();
}

class _OmadaMembersDebugPageState extends State<OmadaMembersDebugPage> {
  late final OmadaServiceExtended _service;

  List<OmadaModel> _omadas = [];
  OmadaModel? _selectedOmada;
  List<OmadaMembershipModel> _members = [];
  bool _isLoading = false;
  String _status = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = OmadaServiceExtended(Supabase.instance.client);
    _loadOmadas();
  }

  Future<void> _loadOmadas() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _status = 'Loading omadas...';
    });

    try {
      final omadas = await _service.getMyOmadas();
      setState(() {
        _omadas = omadas;
        _isLoading = false;
        _status = 'Loaded ${omadas.length} omadas';
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
        _status = 'Error loading omadas';
      });
    }
  }

  Future<void> _loadMembers(OmadaModel omada) async {
    setState(() {
      _isLoading = true;
      _selectedOmada = omada;
      _status = 'Loading members for ${omada.name}...';
    });

    try {
      final members = await _service.getOmadaMemberships(omada.id);
      setState(() {
        _members = members;
        _isLoading = false;
        _status = 'Loaded ${members.length} members';
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
        _status = 'Error loading members';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E9 - Debug Omada Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _selectedOmada = null;
              _members = [];
              _loadOmadas();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _error != null ? Colors.red.shade100 : Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _error != null
                        ? Colors.red.shade900
                        : Colors.blue.shade900,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error: $_error',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
                ],
              ],
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),

          // Omadas list
          if (!_isLoading && _selectedOmada == null)
            Expanded(child: _buildOmadasList()),

          // Members list
          if (!_isLoading && _selectedOmada != null)
            Expanded(child: _buildMembersList()),
        ],
      ),
    );
  }

  Widget _buildOmadasList() {
    if (_omadas.isEmpty) {
      return const Center(
        child: Text('No omadas found. Create some omadas first.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _omadas.length,
      itemBuilder: (context, index) {
        final omada = _omadas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: omada.color != null
                  ? _parseColor(omada.color!)
                  : Colors.purple,
              child: Text(
                omada.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              omada.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (omada.description != null) Text(omada.description!),
                const SizedBox(height: 4),
                Text(
                  '${omada.memberCount ?? 0} members • ${omada.isPublic ? 'Public' : 'Private'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _loadMembers(omada),
          ),
        );
      },
    );
  }

  Widget _buildMembersList() {
    return Column(
      children: [
        // Header with omada info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedOmada = null;
                    _members = [];
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedOmada!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_members.length} members',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Members list
        Expanded(
          child: _members.isEmpty
              ? const Center(child: Text('No members found in this omada.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: member.userAvatar != null
                              ? NetworkImage(member.userAvatar!)
                              : null,
                          child: member.userAvatar == null
                              ? Text(
                                  (member.userName ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          member.userName ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User ID: ${member.userId}'),
                            Text(
                              'Joined: ${_formatDate(member.joinedAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        trailing: _buildRoleBadge(member.role),
                      ),
                    );
                  },
                ),
        ),

        // Debug info section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Debug Info',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Omada ID: ${_selectedOmada!.id}',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.white70,
                ),
              ),
              Text(
                'Owner ID: ${_selectedOmada!.ownerId}',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Roles Distribution:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ..._getRoleStats().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(OmadaRole role) {
    Color color;
    IconData icon;

    switch (role) {
      case OmadaRole.owner:
        color = Colors.purple;
        icon = Icons.star;
        break;
      case OmadaRole.admin:
        color = Colors.red;
        icon = Icons.shield;
        break;
      case OmadaRole.moderator:
        color = Colors.orange;
        icon = Icons.gavel;
        break;
      case OmadaRole.member:
        color = Colors.blue;
        icon = Icons.person;
        break;
      case OmadaRole.guest:
        color = Colors.grey;
        icon = Icons.visibility;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        role.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  Map<String, int> _getRoleStats() {
    final stats = <String, int>{};
    for (final member in _members) {
      final roleName = member.role.displayName;
      stats[roleName] = (stats[roleName] ?? 0) + 1;
    }
    return stats;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }
      return Colors.purple;
    } catch (_) {
      return Colors.purple;
    }
  }
}
