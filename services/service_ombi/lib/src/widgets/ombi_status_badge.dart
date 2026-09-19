import 'package:flutter/material.dart';

import '../models/ombi_models.dart';

/// Where a request stands, as a small filled pill.
class OmbiStatusBadge extends StatelessWidget {
  const OmbiStatusBadge({required this.status, super.key});

  final OmbiRequestStatus status;

  static String labelFor(OmbiRequestStatus status) => switch (status) {
        OmbiRequestStatus.pending => 'Pending',
        OmbiRequestStatus.processing => 'Processing',
        OmbiRequestStatus.available => 'Available',
        OmbiRequestStatus.denied => 'Denied',
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color color = switch (status) {
      OmbiRequestStatus.pending => cs.primary,
      OmbiRequestStatus.processing => cs.secondary,
      OmbiRequestStatus.available => cs.tertiary,
      OmbiRequestStatus.denied => cs.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        labelFor(status),
        style: theme.textTheme.labelSmall
            ?.copyWith(fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
