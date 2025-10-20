// import 'package:flutter/material.dart';
// import 'package:omada/core/data/models/share_request_model.dart';
// import 'package:omada/core/data/services/sharing_service.dart';
// import 'package:omada/core/theme/design_tokens.dart';

// class IncomingRequestsSheet extends StatelessWidget {
//   final SharingService sharingService;
//   const IncomingRequestsSheet({super.key, required this.sharingService});

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       expand: false,
//       initialChildSize: 0.7,
//       minChildSize: 0.4,
//       maxChildSize: 0.95,
//       builder: (context, controller) {
//         List<ShareRequestWithProfile> requests = [];
//         bool loading = true;

//         Future<void> load(void Function(void Function()) setSheetState) async {
//           setSheetState(() => loading = true);
//           try {
//             final fetched = await sharingService.getIncomingShareRequests(
//               status: ShareRequestStatus.pending,
//             );
//             setSheetState(() => requests = fetched);
//           } catch (e) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Failed to load requests: $e')),
//             );
//           } finally {
//             setSheetState(() => loading = false);
//           }
//         }

//         return StatefulBuilder(
//           builder: (context, setSheetState) {
//             Future<void> respond(
//               ShareRequestWithProfile item,
//               ShareRequestStatus response,
//             ) async {
//               try {
//                 await sharingService.respondToShareRequestSimple(
//                   item.request.id,
//                   response,
//                 );
//                 setSheetState(() {
//                   requests = requests
//                       .where((r) => r.request.id != item.request.id)
//                       .toList();
//                 });
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text(
//                       response == ShareRequestStatus.accepted
//                           ? 'Request accepted'
//                           : 'Request declined',
//                     ),
//                   ),
//                 );
//               } catch (e) {
//                 ScaffoldMessenger.of(
//                   context,
//                 ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
//               }
//             }

//             if (loading && requests.isEmpty) {
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 load(setSheetState);
//               });
//             }

//             return Padding(
//               padding: const EdgeInsets.all(OmadaTokens.space16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Text(
//                         'Incoming requests',
//                         style: Theme.of(context).textTheme.titleLarge,
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         icon: const Icon(Icons.refresh),
//                         onPressed: () => load(setSheetState),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () => Navigator.of(context).pop(),
//                       ),
//                     ],
//                   ),
//                   if (loading) const LinearProgressIndicator(minHeight: 2),
//                   const SizedBox(height: OmadaTokens.space8),
//                   Expanded(
//                     child: requests.isEmpty
//                         ? const Center(child: Text('No pending requests'))
//                         : ListView.builder(
//                             controller: controller,
//                             itemCount: requests.length,
//                             itemBuilder: (context, index) {
//                               final item = requests[index];
//                               final from =
//                                   item.requesterProfile?.username ?? 'user';
//                               return Card(
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(
//                                     OmadaTokens.space12,
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'From @$from',
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                       if ((item.request.message ?? '')
//                                           .trim()
//                                           .isNotEmpty)
//                                         Padding(
//                                           padding: const EdgeInsets.only(
//                                             top: OmadaTokens.space6,
//                                           ),
//                                           child: Text(
//                                             item.request.message!,
//                                             style: const TextStyle(
//                                               color: Colors.black87,
//                                             ),
//                                           ),
//                                         ),
//                                       const SizedBox(
//                                         height: OmadaTokens.space8,
//                                       ),
//                                       Row(
//                                         children: [
//                                           FilledButton.icon(
//                                             onPressed: () => respond(
//                                               item,
//                                               ShareRequestStatus.accepted,
//                                             ),
//                                             icon: const Icon(
//                                               Icons.check_circle_outline,
//                                             ),
//                                             label: const Text('Accept'),
//                                           ),
//                                           const SizedBox(
//                                             width: OmadaTokens.space8,
//                                           ),
//                                           OutlinedButton.icon(
//                                             onPressed: () => respond(
//                                               item,
//                                               ShareRequestStatus.declined,
//                                             ),
//                                             icon: const Icon(Icons.close),
//                                             label: const Text('Decline'),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
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
import 'package:omada/core/data/models/share_request_model.dart';
import 'package:omada/core/data/repositories/contact_channel_repository.dart';
import 'package:omada/core/data/repositories/contact_repository.dart';
import 'package:omada/core/data/services/sharing_service.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:omada/ui/pages/contacts/channel_selection_sheet.dart';

class IncomingRequestsSheet extends StatefulWidget {
  final SharingService sharingService;
  final ContactRepository contactRepository;
  final ContactChannelRepository contactChannelRepository;
  
  const IncomingRequestsSheet({
    super.key,
    required this.sharingService,
    required this.contactRepository,
    required this.contactChannelRepository,
  });

  @override
  State<IncomingRequestsSheet> createState() => _IncomingRequestsSheetState();
}

class _IncomingRequestsSheetState extends State<IncomingRequestsSheet> {
  List<ShareRequestWithProfile> _requests = [];
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    try {
      final fetched = await widget.sharingService.getIncomingShareRequests(
        status: ShareRequestStatus.pending,
      );
      setState(() => _requests = fetched);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load requests: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refreshRequests() async {
    setState(() => _refreshing = true);
    try {
      final fetched = await widget.sharingService.getIncomingShareRequests(
        status: ShareRequestStatus.pending,
      );
      setState(() => _requests = fetched);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh requests: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _navigateToChannelSelection(
    ShareRequestWithProfile item,
  ) async {
    // Navigate to channel selection sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChannelSelectionSheet(
        request: item,
        sharingService: widget.sharingService,
        contactRepository: widget.contactRepository,
        contactChannelRepository: widget.contactChannelRepository,
      ),
    );

    // Refresh the requests list after returning
    await _refreshRequests();
  }

  Future<void> _respondToRequest(
    ShareRequestWithProfile item,
    ShareRequestStatus response,
  ) async {
    try {
      await widget.sharingService.respondToShareRequestSimple(
        item.request.id,
        response,
      );

      setState(() {
        _requests = _requests
            .where((r) => r.request.id != item.request.id)
            .toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response == ShareRequestStatus.accepted
                  ? 'Request accepted'
                  : 'Request declined',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
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
              child: Padding(
                padding: const EdgeInsets.all(OmadaTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          'Incoming Requests',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: _refreshing
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          onPressed: _refreshing ? null : _refreshRequests,
                          tooltip: 'Refresh',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: OmadaTokens.space16),

                    // Loading Indicator
                    if (_loading && _requests.isEmpty)
                      const LinearProgressIndicator(),

                    const SizedBox(height: OmadaTokens.space8),

                    // Results Header
                    Text(
                      'Pending Requests (${_requests.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: OmadaTokens.space8),

                    // Requests List
                    Expanded(
                      child: _loading && _requests.isEmpty
                          ? _buildLoadingState()
                          : _requests.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _requests.length,
                              itemBuilder: (context, index) {
                                final item = _requests[index];
                                final from =
                                    item.requesterProfile?.username ??
                                    'Unknown User';

                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: OmadaTokens.space12,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      OmadaTokens.space16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Requester Info
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                              child: Text(
                                                from[0].toUpperCase(),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: OmadaTokens.space12,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '@$from',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Sent ${_formatDate(item.request.createdAt)}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.outline,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Message
                                        if ((item.request.message ?? '')
                                            .trim()
                                            .isNotEmpty) ...[
                                          const SizedBox(
                                            height: OmadaTokens.space12,
                                          ),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(
                                              OmadaTokens.space12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.surfaceVariant,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.request.message!,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          ),
                                        ],

                                        // Action Buttons
                                        const SizedBox(
                                          height: OmadaTokens.space16,
                                        ),
                                        Row(
                                          children: [
                                            FilledButton.icon(
                                              onPressed: () =>
                                                  _navigateToChannelSelection(
                                                    item,
                                                  ),
                                              icon: const Icon(
                                                Icons.check_circle_outline,
                                                size: 18,
                                              ),
                                              label: const Text('Accept'),
                                            ),
                                            const SizedBox(
                                              width: OmadaTokens.space8,
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _respondToRequest(
                                                    item,
                                                    ShareRequestStatus.declined,
                                                  ),
                                              icon: const Icon(
                                                Icons.close,
                                                size: 18,
                                              ),
                                              label: const Text('Decline'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: OmadaTokens.space16),
          Text('Loading requests...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: OmadaTokens.space16),
          Text(
            'No pending requests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: OmadaTokens.space8),
          Text(
            'Share requests from other users will appear here',
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
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
