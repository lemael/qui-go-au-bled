import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StarRatingWidget extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final bool showLabel;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 20,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxStars, (index) {
          final starValue = index + 1;
          IconData icon;
          if (rating >= starValue) {
            icon = Icons.star_rounded;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_outline_rounded;
          }
          return Icon(
            icon,
            size: size,
            color: rating >= starValue - 0.5
                ? AppColors.starActive
                : AppColors.starInactive,
          );
        }),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveStarRating extends StatefulWidget {
  final double initialRating;
  final void Function(double) onRatingChanged;
  final double size;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 36,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() => _rating = index + 1.0);
            widget.onRatingChanged(_rating);
          },
          child: Icon(
            _rating > index ? Icons.star_rounded : Icons.star_outline_rounded,
            size: widget.size,
            color: _rating > index ? AppColors.starActive : AppColors.grey300,
          ),
        );
      }),
    );
  }
}
