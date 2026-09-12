import 'package:flutter/material.dart';

/// An interactive or read-only 5-star rating bar for Navidrome songs and albums.
///
/// Tapping a star (1-5) sets that rating. Tapping the active star resets the rating to 0 (unrated).
class NavidromeRatingBar extends StatelessWidget {
  const NavidromeRatingBar({
    required this.rating,
    this.onRatingChanged,
    this.starSize = 22,
    this.spacing = 2,
    this.activeColor = const Color(0xFFFFB300), // Amber
    this.inactiveColor,
    super.key,
  });

  /// The current rating value between 0 and 5.
  final int rating;

  /// Callback when user selects a rating. If null, the rating bar is read-only.
  final ValueChanged<int>? onRatingChanged;

  /// Diameter of each star icon.
  final double starSize;

  /// Spacing between star icons.
  final double spacing;

  /// Color for filled stars.
  final Color activeColor;

  /// Color for unfilled stars. Defaults to onSurfaceVariant with low opacity.
  final Color? inactiveColor;

  bool get isInteractive => onRatingChanged != null;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color defaultInactive = cs.onSurfaceVariant.withValues(alpha: 0.35);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (int index) {
        final int starValue = index + 1;
        final bool isFilled = starValue <= rating;
        final Color color = isFilled ? activeColor : (inactiveColor ?? defaultInactive);
        final IconData icon =
            isFilled ? Icons.star_rounded : Icons.star_outline_rounded;

        if (!isInteractive) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: Icon(icon, size: starSize, color: color),
          );
        }

        return InkResponse(
          onTap: () {
            // Tapping currently selected star clears rating to 0
            final int newRating = starValue == rating ? 0 : starValue;
            onRatingChanged!(newRating);
          },
          radius: starSize * 0.9,
          splashColor: activeColor.withValues(alpha: 0.2),
          highlightColor: activeColor.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2, vertical: 2),
            child: Icon(icon, size: starSize, color: color),
          ),
        );
      }),
    );
  }
}
