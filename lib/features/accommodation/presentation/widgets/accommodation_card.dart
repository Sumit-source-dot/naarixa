import 'package:flutter/material.dart';
import '../providers/accommodation_provider.dart';

class AccommodationCard extends StatelessWidget {
  const AccommodationCard({
    required this.property,
    this.showLowTrust = false,
    this.onTap,
    this.onEdit,
    this.onVerify,
    this.onDelete,
    super.key,
  });

  final OwnerProperty property;
  final bool showLowTrust;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onVerify;
  final VoidCallback? onDelete;

  // ── Theme colors (matches hero section) ──────────────────────────
  static const Color _rosePrimary   = Color(0xFFE91E8C);
  static const Color _roseSoft      = Color(0xFFF48FB1);
  static const Color _peachBg       = Color(0xFFFCE4EC);
  static const Color _textDark      = Color(0xFF37003C);
  static const Color _textMid       = Color(0xFF880E4F);

  @override
  Widget build(BuildContext context) {
    final rawImage = property.images.isNotEmpty ? property.images.first : '';
    final imageUrl = rawImage.trim().replaceAll('"', '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _roseSoft.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ─────────────────────────────────────────────────
          InkWell(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Property image
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),

                  // Gradient scrim at bottom for badge legibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Verified / Unverified badge — top right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _statusBadge(
                      property.verificationStatus == 1,
                    ),
                  ),

                  // Low trust badge — top left
                  if (showLowTrust)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _badge(
                        icon: Icons.warning_amber_rounded,
                        label: 'Low Trust',
                        color: const Color(0xFFE53935),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Info ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                InkWell(
                  onTap: onTap,
                  child: Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),

                // Price
                Text(
                  '₹${property.budget.toStringAsFixed(0)} / mo',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _rosePrimary,
                  ),
                ),
                const SizedBox(height: 4),

                // Location + Safety Score row
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 12, color: _textMid),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        property.location,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (property.safetyScore > 0) ...[
                      const SizedBox(width: 6),
                      _safetyScoreBadge(property.safetyScore),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Edit / Verify (if pending) / Delete buttons
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        onPressed: onEdit,
                        bg: _peachBg,
                        fg: _rosePrimary,
                      ),
                    ),
                    if (property.verificationStatus != 1) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          label: 'Verify',
                          icon: Icons.verified_user_outlined,
                          onPressed: onVerify,
                          bg: const Color(0xFFE8F5E9),
                          fg: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        label: 'Delete',
                        icon: Icons.delete_outline,
                        onPressed: onDelete,
                        bg: const Color(0xFFFFEBEE),
                        fg: const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _imagePlaceholder() {
    return Container(
      color: _peachBg,
      alignment: Alignment.center,
      child: const Icon(Icons.home_outlined, size: 32, color: _roseSoft),
    );
  }

  Widget _statusBadge(bool verified) {
    return _badge(
      icon: verified ? Icons.verified_rounded : Icons.info_outline_rounded,
      label: verified ? 'Approved' : 'Pending',
      color: verified ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
    );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyScoreBadge(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _peachBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 11, color: _rosePrimary),
          const SizedBox(width: 3),
          Text(
            score.toString(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _rosePrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color bg,
    required Color fg,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 13),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 6),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}