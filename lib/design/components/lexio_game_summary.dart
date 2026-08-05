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
    required this.accentColor,
    required this.correctCount,
    required this.totalCount,
    required this.reviewItems,
    required this.onPlayAgain,
    required this.onClose,
  });

  final Color accentColor;
  final int correctCount;
  final int totalCount;
  final List<LexioReviewItem> reviewItems;
  final VoidCallback onPlayAgain;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        key: const ValueKey('summary_scroll_view'),
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
            ..._buildReviewItems(),
          ] else
            const SizedBox(height: LexioSpacing.xxl),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(
        top: LexioSpacing.sm,
        right: LexioSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          onPressed: onClose,
          tooltip: 'Închide',
          icon: const Icon(
            Icons.close,
            color: LexioColors.textPrimary,
            size: LexioSpacing.xl,
          ),
        ),
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
              textStyle: LexioTextStyles.displayLarge.copyWith(
                color: LexioColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReviewItems() {
    final children = <Widget>[];
    for (var index = 0; index < reviewItems.length; index++) {
      if (index > 0) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: LexioSpacing.xl),
            child: Divider(height: 1),
          ),
        );
      }
      children.add(_ReviewItem(index: index, item: reviewItems[index]));
    }

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          LexioSpacing.screenHorizontal,
          0,
          LexioSpacing.screenHorizontal,
          LexioSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ];
  }

  Widget _buildActions() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: LexioColors.surface,
        border: Border(top: BorderSide(color: LexioColors.divider)),
      ),
      child: LexioActionRow(label: 'Joacă din nou', onPressed: onPlayAgain),
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
