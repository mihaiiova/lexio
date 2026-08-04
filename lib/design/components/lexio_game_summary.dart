import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';
import 'lexio_action_row.dart';

final class LexioReviewItem {
  const LexioReviewItem({
    required this.wrongAnswer,
    required this.correctAnswer,
    required this.explanation,
  });

  final String wrongAnswer;
  final String correctAnswer;
  final String explanation;
}

class LexioGameSummary extends StatelessWidget {
  const LexioGameSummary({
    super.key,
    required this.gameNumber,
    required this.gameTitle,
    required this.accentColor,
    required this.correctCount,
    required this.totalCount,
    required this.reviewItems,
    required this.onPlayAgain,
    required this.onBack,
  });

  final String gameNumber;
  final String gameTitle;
  final Color accentColor;
  final int correctCount;
  final int totalCount;
  final List<LexioReviewItem> reviewItems;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildResult(),
          if (reviewItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LexioSpacing.screenHorizontal,
                LexioSpacing.xxl,
                LexioSpacing.screenHorizontal,
                LexioSpacing.lg,
              ),
              child: Text(
                'DE REVĂZUT',
                style: LexioTextStyles.labelSmall.copyWith(
                  color: LexioColors.textSecondary,
                ),
              ),
            ),
            Expanded(child: _buildReviewList()),
          ] else
            const Spacer(),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LexioSpacing.screenHorizontal,
        LexioSpacing.xl,
        LexioSpacing.screenHorizontal,
        LexioSpacing.lg,
      ),
      child: Row(
        children: [
          Text(
            'Slove',
            style: GoogleFonts.noticiaText(
              textStyle: LexioTextStyles.headingSmall.copyWith(
                color: LexioColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          Text(
            gameNumber,
            style: LexioTextStyles.labelLarge.copyWith(color: accentColor),
          ),
          const SizedBox(width: LexioSpacing.md),
          Flexible(
            child: Text(
              gameTitle,
              style: GoogleFonts.noticiaText(
                textStyle: LexioTextStyles.bodyMedium.copyWith(
                  color: LexioColors.textPrimary,
                ),
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LexioSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: LexioSpacing.xxl),
          Text(
            'RUNDĂ ÎNCHEIATĂ',
            style: LexioTextStyles.labelSmall.copyWith(color: accentColor),
          ),
          const SizedBox(height: LexioSpacing.md),
          Text(
            '$correctCount din $totalCount',
            style: GoogleFonts.noticiaText(
              textStyle: LexioTextStyles.displayMedium.copyWith(
                color: LexioColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    return ListView.separated(
      key: const ValueKey('summary_review_list'),
      padding: const EdgeInsets.fromLTRB(
        LexioSpacing.screenHorizontal,
        0,
        LexioSpacing.screenHorizontal,
        LexioSpacing.lg,
      ),
      itemCount: reviewItems.length,
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: LexioSpacing.xl),
        child: Divider(height: 1),
      ),
      itemBuilder: (context, index) =>
          _ReviewItem(index: index, item: reviewItems[index]),
    );
  }

  Widget _buildActions() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: LexioColors.surface,
        border: Border(top: BorderSide(color: LexioColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LexioActionRow(label: 'Joacă din nou', onPressed: onPlayAgain),
          LexioActionRow(label: 'Înapoi la jocuri', onPressed: onBack),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.index, required this.item});

  final int index;
  final LexioReviewItem item;

  @override
  Widget build(BuildContext context) {
    final itemNumber = (index + 1).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          itemNumber,
          style: LexioTextStyles.labelMedium.copyWith(color: LexioColors.error),
        ),
        const SizedBox(height: LexioSpacing.md),
        Text(
          item.wrongAnswer,
          style: GoogleFonts.noticiaText(
            textStyle: LexioTextStyles.bodyLarge.copyWith(
              color: LexioColors.error,
            ),
          ),
        ),
        const SizedBox(height: LexioSpacing.sm),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Corect: ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: item.correctAnswer),
            ],
          ),
          style: GoogleFonts.noticiaText(
            textStyle: LexioTextStyles.bodyMedium.copyWith(
              color: LexioColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: LexioSpacing.sm),
        Text(
          item.explanation,
          style: LexioTextStyles.bodySmall.copyWith(
            color: LexioColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
