import 'package:flutter/material.dart';
import 'package:invera_mobile/core/ui/mise_en_page.dart';

Future<bool?> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  Color confirmColor = const Color(0xFFDC2626),
  String cancelLabel = 'Annuler',
  Color accentColor = const Color(0xFF2553D4),
  IconData icon = Icons.help_outline_rounded,
  String? helper,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final compact = AdaptiveSurface.isCompact(dialogContext, breakpoint: 430);
      final radius = compact ? 24.0 : 28.0;
      final sidePadding = compact ? 18.0 : 22.0;
      final verticalPadding = compact ? 18.0 : 22.0;
      final gap = compact ? 12.0 : 14.0;

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 24,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AdaptiveLayout.dialogWidth(
              dialogContext,
              max: 420,
              sideMargin: compact ? 18 : 24,
            ),
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              verticalPadding,
              sidePadding,
              sidePadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: const Color(0xFFE6EAF2)),
              boxShadow: AdaptiveSurface.shadow(
                dialogContext,
                breakpoint: 520,
                compactBlur: 18,
                compactOffsetY: 8,
                regularBlur: 24,
                regularOffsetY: 10,
                compactColor: const Color(0x120D1B2A),
                regularColor: const Color(0x180D1B2A),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 44 : 48,
                      height: compact ? 44 : 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.18),
                            confirmColor.withValues(alpha: 0.12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(compact ? 14 : 16),
                      ),
                      child: Icon(
                        icon,
                        color: confirmColor,
                        size: compact ? 21 : 23,
                      ),
                    ),
                    SizedBox(width: compact ? 12 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: const Color(0xFF10203A),
                              fontSize: compact ? 22 : 24,
                              fontWeight: FontWeight.w800,
                              height: 1.08,
                            ),
                          ),
                          SizedBox(height: compact ? 7 : 8),
                          Text(
                            message,
                            style: TextStyle(
                              color: const Color(0xFF516079),
                              fontSize: compact ? 14.2 : 15,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    InkWell(
                      onTap: () => Navigator.pop(dialogContext, false),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: compact ? 34 : 36,
                        height: compact ? 34 : 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFE6EAF2)),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF607089),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                if (helper != null) ...[
                  SizedBox(height: gap),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 14,
                      vertical: compact ? 11 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(compact ? 14 : 16),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: compact ? 17 : 18,
                          color: accentColor,
                        ),
                        SizedBox(width: compact ? 9 : 10),
                        Expanded(
                          child: Text(
                            helper,
                            style: TextStyle(
                              color: const Color(0xFF45556F),
                              fontSize: compact ? 12.6 : 13,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: gap + 2),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stackActions = constraints.maxWidth < 320;
                    final cancelButton = OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3F4E68),
                        side: const BorderSide(color: Color(0xFFD4DDEA)),
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 16 : 18,
                          vertical: compact ? 12 : 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        cancelLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                    final confirmButton = FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 16 : 18,
                          vertical: compact ? 12 : 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    );

                    if (stackActions) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          confirmButton,
                          const SizedBox(height: 10),
                          cancelButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: cancelButton),
                        const SizedBox(width: 10),
                        Expanded(child: confirmButton),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
