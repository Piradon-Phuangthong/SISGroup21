import 'package:flutter/material.dart';
import 'package:omada/core/data/models/shared_contact_data.dart';
import 'package:omada/core/data/models/tag_model.dart';
import 'package:omada/core/theme/design_tokens.dart';

/// A tile widget for displaying a shared contact in the contacts list
/// Shows a badge indicating the contact is shared and who shared it
class SharedContactTile extends StatelessWidget {
  final SharedContactData sharedContact;
  final List<TagModel> tags;
  final VoidCallback? onTap;

  const SharedContactTile({
    super.key,
    required this.sharedContact,
    this.tags = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contact = sharedContact.contact;
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: OmadaTokens.space16,
        vertical: OmadaTokens.space8,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: OmadaTokens.radius12,
        child: Padding(
          padding: const EdgeInsets.all(OmadaTokens.space12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: contact.avatarUrl != null
                    ? NetworkImage(contact.avatarUrl!)
                    : null,
                child: contact.avatarUrl == null
                    ? Text(
                        contact.initials,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: OmadaTokens.space12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and shared badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contact.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Shared indicator chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: OmadaTokens.space8,
                            vertical: OmadaTokens.space4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: OmadaTokens.radius12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 14,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Shared',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OmadaTokens.space4),
                    
                    // Shared by info
                    Text(
                      'Shared by @${sharedContact.sharedBy}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    // Contact info if available
                    if (sharedContact.includesField('primary_mobile') &&
                        contact.primaryMobile != null) ...[
                      const SizedBox(height: OmadaTokens.space4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            contact.primaryMobile!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (sharedContact.includesField('primary_email') &&
                        contact.primaryEmail != null) ...[
                      const SizedBox(height: OmadaTokens.space4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              contact.primaryEmail!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Tags if any
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: OmadaTokens.space8),
                      Wrap(
                        spacing: OmadaTokens.space4,
                        runSpacing: OmadaTokens.space4,
                        children: tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: OmadaTokens.space8,
                              vertical: OmadaTokens.space2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: OmadaTokens.radius8,
                            ),
                            child: Text(
                              tag.name,
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Chevron
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
