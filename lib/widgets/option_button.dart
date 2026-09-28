import 'package:flutter/material.dart';

/// Button displaying a country name as a quiz answer option.
///
/// Supports visual states for default, correct, wrong, and disabled.
class OptionButton extends StatelessWidget {
  /// The country name to display.
  final String label;

  /// Callback when the button is tapped.
  final VoidCallback? onTap;

  /// Whether this option is the correct answer.
  final bool isCorrect;

  /// Whether this option has been selected.
  final bool isSelected;

  /// Whether the button is disabled (after answer revealed).
  final bool isDisabled;

  const OptionButton({
    super.key,
    required this.label,
    this.onTap,
    this.isCorrect = false,
    this.isSelected = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScale(
      scale: isSelected ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Material(
        elevation: isSelected ? 2 : 4,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: _getBackgroundColor(theme),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getBorderColor(theme),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getTextColor(theme),
                    ),
                  ),
                ),
                if (isSelected) _buildStatusIcon(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (isSelected && isCorrect) return Colors.green.shade50;
    if (isSelected && !isCorrect) return Colors.red.shade50;
    if (isDisabled) return Colors.grey.shade100;
    return theme.colorScheme.surface;
  }

  Color _getBorderColor(ThemeData theme) {
    if (isSelected && isCorrect) return Colors.green.shade400;
    if (isSelected && !isCorrect) return Colors.red.shade400;
    if (isDisabled) return Colors.grey.shade300;
    return theme.colorScheme.outline.withValues(alpha: 0.3);
  }

  Color _getTextColor(ThemeData theme) {
    if (isSelected && isCorrect) return Colors.green.shade700;
    if (isSelected && !isCorrect) return Colors.red.shade700;
    if (isDisabled) return Colors.grey.shade500;
    return theme.colorScheme.onSurface;
  }

  Widget _buildStatusIcon() {
    if (isCorrect) {
      return Icon(Icons.check_circle, color: Colors.green.shade600, size: 28);
    }
    return Icon(Icons.cancel, color: Colors.red.shade600, size: 28);
  }
}
