import 'package:flutter/material.dart';
import 'package:omada/core/data/models/share_request_model.dart';
import 'package:omada/core/data/services/sharing_service.dart';
import 'package:omada/core/theme/design_tokens.dart';

class IncomingRequestsSheet extends StatelessWidget {
  final SharingService sharingService;
  const IncomingRequestsSheet({super.key, required this.sharingService});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) {
        List<ShareRequestWithProfile> requests = [];
        bool loading = true;

        Future<void> load(void Function(void Function()) setSheetState) async {
          setSheetState(() => loading = true);
          try {
            final fetched = await sharingService.getIncomingShareRequests(
              status: ShareRequestStatus.pending,
            );
            setSheetState(() => requests = fetched);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load requests: $e')),
            );
          } finally {
            setSheetState(() => loading = false);
          }
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> respond(
              ShareRequestWithProfile item,
              ShareRequestStatus response,
            ) async {
              try {
                await sharingService.respondToShareRequestSimple(
                  item.request.id,
                  response,
                );
                setSheetState(() {
                  requests = requests
                      .where((r) => r.request.id != item.request.id)
                      .toList();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      response == ShareRequestStatus.accepted
                          ? 'Request accepted'
                          : 'Request declined',
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
              }
            }

            if (loading && requests.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                load(setSheetState);
              });
            }

            return Padding(
              padding: const EdgeInsets.all(OmadaTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Incoming requests',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => load(setSheetState),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  if (loading) const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: OmadaTokens.space8),
                  Expanded(
                    child: requests.isEmpty
                        ? const Center(child: Text('No pending requests'))
                        : ListView.builder(
                            controller: controller,
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              final item = requests[index];
                              final from =
                                  item.requesterProfile?.username ?? 'user';
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    OmadaTokens.space12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'From @$from',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if ((item.request.message ?? '')
                                          .trim()
                                          .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: OmadaTokens.space6,
                                          ),
                                          child: Text(
                                            item.request.message!,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(
                                        height: OmadaTokens.space8,
                                      ),
                                      Row(
                                        children: [
                                          FilledButton.icon(
                                            onPressed: () => respond(
                                              item,
                                              ShareRequestStatus.accepted,
                                            ),
                                            icon: const Icon(
                                              Icons.check_circle_outline,
                                            ),
                                            label: const Text('Accept'),
                                          ),
                                          const SizedBox(
                                            width: OmadaTokens.space8,
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => respond(
                                              item,
                                              ShareRequestStatus.declined,
                                            ),
                                            icon: const Icon(Icons.close),
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
            );
          },
        );
      },
    );
  }
}
