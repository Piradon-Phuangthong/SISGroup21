import 'package:flutter/material.dart';
import 'package:omada/core/data/models/profile_model.dart';
import 'package:omada/core/data/services/sharing_service.dart';

class UserDiscoverySheet extends StatelessWidget {
  final SharingService sharingService;
  const UserDiscoverySheet({super.key, required this.sharingService});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) {
        final TextEditingController usernameController =
            TextEditingController();
        final TextEditingController messageController = TextEditingController();
        List<ProfileModel> results = [];
        bool isSearching = false;
        final Set<String> requestedUsernames = <String>{};
        DateTime? lastChangeAt;

        Future<void> runSearch(
          String term,
          void Function(void Function()) setSheetState,
        ) async {
          final q = term.trim();
          if (q.isEmpty) {
            setSheetState(() => results = []);
            return;
          }
          setSheetState(() => isSearching = true);
          try {
            final fetched = await sharingService.searchUsersForSharing(q);
            setSheetState(() => results = fetched);
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
          } finally {
            setSheetState(() => isSearching = false);
          }
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void onUsernameChanged() {
              lastChangeAt = DateTime.now();
              Future.delayed(const Duration(milliseconds: 300)).then((_) {
                final ts = lastChangeAt;
                if (ts == null) return;
                if (DateTime.now().difference(ts) >=
                    const Duration(milliseconds: 290)) {
                  runSearch(usernameController.text, setSheetState);
                }
              });
            }

            Future<void> sendRequest(String username) async {
              if (requestedUsernames.contains(username)) return;
              setSheetState(() => requestedUsernames.add(username));
              try {
                await sharingService.sendShareRequest(
                  recipientUsername: username,
                  message: messageController.text.trim().isEmpty
                      ? null
                      : messageController.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Request sent to @$username')),
                );
              } catch (e) {
                setSheetState(() => requestedUsernames.remove(username));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send request: $e')),
                );
              }
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Discover users',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Search username',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => onUsernameChanged(),
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Optional message',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isSearching) const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final profile = results[index];
                        final already = requestedUsernames.contains(
                          profile.username,
                        );
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text('@${profile.username}'),
                          subtitle: Text(
                            'Joined ${profile.createdAt.toLocal().toIso8601String().substring(0, 10)}',
                          ),
                          trailing: FilledButton(
                            onPressed: already
                                ? null
                                : () => sendRequest(profile.username),
                            child: Text(already ? 'Requested' : 'Request'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
