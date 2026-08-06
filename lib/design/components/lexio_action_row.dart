import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

class LexioActionRow extends StatelessWidget {
  const LexioActionRow({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: LexioSpacing.screenHorizontal,
            ),
            child: Divider(height: 1, color: LexioColors.divider),
          ),
          InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LexioSpacing.screenHorizontal,
                vertical: LexioSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: LexioTextStyles.headingMedium.copyWith(
                          color: LexioColors.textPrimary,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'NoticiaText',
                        ),
                    ),
                  ),
                  const SizedBox(width: LexioSpacing.lg),
                  const Icon(
                    Icons.arrow_forward,
                    color: LexioColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
