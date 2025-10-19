import 'package:flutter/material.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/utils/color_utils.dart';

class OmadaCard extends StatelessWidget {
  final OmadaModel omada;
  final VoidCallback onTap;

  const OmadaCard({super.key, required this.omada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Use stored color, or generate a consistent color based on the name
    final colorValue = omada.color != null
        ? ColorUtils.parseColor(
            omada.color,
            fallback: ColorUtils.getColorForString(omada.name),
          )
        : ColorUtils.getColorForString(omada.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorValue,
                child: Text(
                  omada.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ColorUtils.getContrastingTextColor(colorValue),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      omada.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (omada.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        omada.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${omada.memberCount ?? 0} members',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (omada.pendingRequestsCount != null &&
                            omada.pendingRequestsCount! > 0) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.pending,
                            size: 16,
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${omada.pendingRequestsCount} pending',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.orange[600]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
