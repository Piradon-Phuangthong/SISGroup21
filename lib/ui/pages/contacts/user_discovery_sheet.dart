// import 'package:flutter/material.dart';
// import 'package:omada/core/data/models/profile_model.dart';
// import 'package:omada/core/data/services/sharing_service.dart';
// import 'package:omada/core/theme/design_tokens.dart';

// class UserDiscoverySheet extends StatelessWidget {
//   final SharingService sharingService;
//   const UserDiscoverySheet({super.key, required this.sharingService});

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       expand: false,
//       initialChildSize: 0.7,
//       minChildSize: 0.4,
//       maxChildSize: 0.95,
//       builder: (context, controller) {
//         final TextEditingController usernameController =
//             TextEditingController();
//         final TextEditingController messageController = TextEditingController();
//         List<ProfileModel> results = [];
//         bool isSearching = false;
//         final Set<String> requestedUsernames = <String>{};
//         DateTime? lastChangeAt;

//         Future<void> runSearch(
//           String term,
//           void Function(void Function()) setSheetState,
//         ) async {
//           final q = term.trim();
//           if (q.isEmpty) {
//             setSheetState(() => results = []);
//             return;
//           }
//           setSheetState(() => isSearching = true);
//           try {
//             final fetched = await sharingService.searchUsersForSharing(q);
//             setSheetState(() => results = fetched);
//           } catch (e) {
//             ScaffoldMessenger.of(
//               context,
//             ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
//           } finally {
//             setSheetState(() => isSearching = false);
//           }
//         }

//         return StatefulBuilder(
//           builder: (context, setSheetState) {
//             void onUsernameChanged() {
//               lastChangeAt = DateTime.now();
//               Future.delayed(const Duration(milliseconds: 300)).then((_) {
//                 final ts = lastChangeAt;
//                 if (ts == null) return;
//                 if (DateTime.now().difference(ts) >=
//                     const Duration(milliseconds: 290)) {
//                   runSearch(usernameController.text, setSheetState);
//                 }
//               });
//             }

//             Future<void> sendRequest(String username) async {
//               if (requestedUsernames.contains(username)) return;
//               setSheetState(() => requestedUsernames.add(username));
//               try {
//                 await sharingService.sendShareRequest(
//                   recipientUsername: username,
//                   message: messageController.text.trim().isEmpty
//                       ? null
//                       : messageController.text.trim(),
//                 );
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Request sent to @$username')),
//                 );
//               } catch (e) {
//                 setSheetState(() => requestedUsernames.remove(username));
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Failed to send request: $e')),
//                 );
//               }
//             }

//             return Padding(
//               padding: const EdgeInsets.all(OmadaTokens.space16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Text(
//                         'Discover users',
//                         style: Theme.of(context).textTheme.titleLarge,
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () => Navigator.of(context).pop(),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: OmadaTokens.space8),
//                   TextField(
//                     controller: usernameController,
//                     decoration: const InputDecoration(
//                       labelText: 'Search username',
//                       prefixIcon: Icon(Icons.search),
//                     ),
//                     onChanged: (_) => onUsernameChanged(),
//                     autofocus: true,
//                   ),
//                   const SizedBox(height: OmadaTokens.space8),
//                   TextField(
//                     controller: messageController,
//                     decoration: const InputDecoration(
//                       labelText: 'Optional message',
//                     ),
//                   ),
//                   const SizedBox(height: OmadaTokens.space12),
//                   if (isSearching) const LinearProgressIndicator(minHeight: 2),
//                   const SizedBox(height: OmadaTokens.space8),
//                   Expanded(
//                     child: ListView.builder(
//                       controller: controller,
//                       itemCount: results.length,
//                       itemBuilder: (context, index) {
//                         final profile = results[index];
//                         final already = requestedUsernames.contains(
//                           profile.username,
//                         );
//                         return ListTile(
//                           leading: const CircleAvatar(
//                             child: Icon(Icons.person_outline),
//                           ),
//                           title: Text('@${profile.username}'),
//                           subtitle: Text(
//                             'Joined ${profile.createdAt.toLocal().toIso8601String().substring(0, 10)}',
//                           ),
//                           trailing: FilledButton(
//                             onPressed: already
//                                 ? null
//                                 : () => sendRequest(profile.username),
//                             child: Text(already ? 'Requested' : 'Request'),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:omada/core/data/models/profile_model.dart';
import 'package:omada/core/data/services/sharing_service.dart';
import 'package:omada/core/theme/design_tokens.dart';

class UserDiscoverySheet extends StatefulWidget {
  final SharingService sharingService;
  const UserDiscoverySheet({super.key, required this.sharingService});

  @override
  State<UserDiscoverySheet> createState() => _UserDiscoverySheetState();
}

class _UserDiscoverySheetState extends State<UserDiscoverySheet> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<ProfileModel> _searchResults = [];
  bool _isSearching = false;
  final Set<String> _requestedUsernames = <String>{};
  DateTime? _lastChangeAt;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _messageController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String term) async {
    final query = term.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await widget.sharingService.searchUsersForSharing(query);
      setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    _lastChangeAt = DateTime.now();
    Future.delayed(const Duration(milliseconds: 300)).then((_) {
      if (_lastChangeAt == null) return;
      if (DateTime.now().difference(_lastChangeAt!) >=
          const Duration(milliseconds: 290)) {
        _runSearch(value);
      }
    });
  }

  Future<void> _sendRequest(String username) async {
    if (_requestedUsernames.contains(username)) return;

    setState(() => _requestedUsernames.add(username));
    try {
      await widget.sharingService.sendShareRequest(
        recipientUsername: username,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Request sent to @$username')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _requestedUsernames.remove(username));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          snap: true,
          snapSizes: const [0.5, 0.7, 0.9],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // Gradient Header
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF5733), // Red-orange
                          Color(0xFF4A00B0), // Deep purple
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
                      padding: const EdgeInsets.only(
                        left: OmadaTokens.space16,
                        right: OmadaTokens.space16,
                        bottom: OmadaTokens.space16,
                      ),
                      child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Discover Users',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(OmadaTokens.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                    // Search Field
                    TextField(
                      controller: _usernameController,
                      focusNode: _searchFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Search by username',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                    ),
                    const SizedBox(height: OmadaTokens.space12),

                    // Optional Message Field
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Optional message (include in request)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: OmadaTokens.space16),

                    // Search Progress
                    if (_isSearching) const LinearProgressIndicator(),

                    const SizedBox(height: OmadaTokens.space8),

                    // Results Header
                    Text(
                      'Search Results',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: OmadaTokens.space8),

                    // Results List
                    Expanded(
                      child: _searchResults.isEmpty && !_isSearching
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final profile = _searchResults[index];
                                final isRequested = _requestedUsernames
                                    .contains(profile.username);

                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: OmadaTokens.space8,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      child: Text(
                                        profile.username[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '@${profile.username}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Joined ${_formatDate(profile.createdAt)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    trailing: FilledButton.tonal(
                                      onPressed: isRequested
                                          ? null
                                          : () =>
                                                _sendRequest(profile.username),
                                      child: Text(
                                        isRequested
                                            ? 'Requested'
                                            : 'Send Request',
                                      ),
                                    ),
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: OmadaTokens.space16),
          Text(
            'No users found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: OmadaTokens.space8),
          Text(
            'Try searching for a username',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
