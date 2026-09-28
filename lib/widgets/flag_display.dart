import 'package:flutter/material.dart';

/// Displays a country flag image with loading and error states.
class FlagDisplay extends StatelessWidget {
  /// URL of the flag image.
  final String flagUrl;

  const FlagDisplay({super.key, required this.flagUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Image.network(
          flagUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildContainer(
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildContainer(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load flag',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey.shade100,
      child: child,
    );
  }
}
