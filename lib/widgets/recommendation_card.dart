import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';
import 'package:jaga_tani/data/models/ai_recommendation.dart';
import 'package:jaga_tani/widgets/neu_badge.dart';
import 'package:jaga_tani/widgets/neu_button.dart';

/// A Neubrutalism card that renders a single [AiRecommendation].
///
/// Features a left-side priority color border, category emoji header,
/// priority badge, title, description, reason chip, and a tappable
/// action button. Actioned recommendations are shown with muted styling.
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onActionTap,
    this.onCardTap,
  });

  final AiRecommendation recommendation;

  /// Called when the user presses the action button.
  final VoidCallback? onActionTap;

  /// Called when the user taps the card itself (e.g. to open detail).
  final VoidCallback? onCardTap;

  // ─────────────────────── Priority helpers ────────────────────────────────

  Color get _priorityColor {
    switch (recommendation.priority) {
      case RecommendationPriority.urgent:
        return AppColors.danger;
      case RecommendationPriority.attention:
        return AppColors.warning;
      case RecommendationPriority.safe:
        return AppColors.success;
    }
  }

  Color get _priorityBackground {
    switch (recommendation.priority) {
      case RecommendationPriority.urgent:
        return AppColors.danger.withOpacity(0.07);
      case RecommendationPriority.attention:
        return AppColors.warning.withOpacity(0.07);
      case RecommendationPriority.safe:
        return AppColors.success.withOpacity(0.07);
    }
  }

  NeuBadge get _badge {
    switch (recommendation.priority) {
      case RecommendationPriority.urgent:
        return NeuBadge.urgent(label: recommendation.priorityLabel);
      case RecommendationPriority.attention:
        return NeuBadge.attention(label: recommendation.priorityLabel);
      case RecommendationPriority.safe:
        return NeuBadge.safe(label: recommendation.priorityLabel);
    }
  }

  /// Returns the [IconData] for the recommendation's [RecommendationCategory].
  IconData get _categoryIcon {
    switch (recommendation.category) {
      case RecommendationCategory.irrigation:
        return Iconsax.drop;
      case RecommendationCategory.fertilizer:
        return Iconsax.tree;
      case RecommendationCategory.pest:
        return Icons.pest_control;
      case RecommendationCategory.climate:
        return Iconsax.cloud;
      case RecommendationCategory.harvest:
        return Iconsax.sun_1;
    }
  }

  String get _formattedTime {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
        .format(recommendation.generatedAt);
  }

  @override
  Widget build(BuildContext context) {
    final bool actioned = recommendation.isActioned;

    return GestureDetector(
      onTap: onCardTap,
      child: Opacity(
        opacity: actioned ? 0.65 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: actioned ? AppColors.surfaceAlt : _priorityBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left priority stripe ──────────────────────────────────
                  Container(
                    width: 5,
                    color: _priorityColor,
                  ),

                  // ── Card content ──────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row: category icon + badge + timestamp
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Category icon bubble
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _priorityColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _priorityColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    _categoryIcon,
                                    size: 18,
                                    color: _priorityColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Category label
                              Text(
                                recommendation.categoryLabel,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),

                              const Spacer(),

                              // Priority badge
                              _badge,
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Title
                          Text(
                            recommendation.title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Description
                          Text(
                            recommendation.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Reason chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Iconsax.info_circle,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    recommendation.reason,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Footer: timestamp + action button
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Actioned checkmark or timestamp
                              if (actioned) ...[
                                const Icon(
                                  Iconsax.tick_circle5,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Sudah dilaksanakan',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ] else ...[
                                const Icon(
                                  Iconsax.clock,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formattedTime,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],

                              const Spacer(),

                              // Action button
                              if (!actioned)
                                NeuButton(
                                  label: 'Lakukan',
                                  onPressed: onActionTap,
                                  backgroundColor: _priorityColor,
                                  textColor: Colors.white,
                                  icon: Iconsax.tick_circle,
                                  size: NeuButtonSize.small,
                                )
                              else
                                NeuButton(
                                  label: 'Selesai',
                                  onPressed: null,
                                  backgroundColor: AppColors.surfaceAlt,
                                  textColor: AppColors.textSecondary,
                                  icon: Iconsax.tick_circle5,
                                  size: NeuButtonSize.small,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
