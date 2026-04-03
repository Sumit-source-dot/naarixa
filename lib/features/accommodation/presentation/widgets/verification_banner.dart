import 'package:flutter/material.dart';

class VerificationBanner extends StatelessWidget {
  final bool isVerified;
  final int progressPercent;
  final int completedItems;
  final int totalItems;
  final bool emailVerified;
  final bool personalPhoneVerified;
  final bool emergencyPhoneVerified;
  final bool governmentIdVerified;
  final VoidCallback onVerifyPressed;
  final VoidCallback? onClose;

  const VerificationBanner({
    Key? key,
    required this.isVerified,
    required this.progressPercent,
    required this.completedItems,
    required this.totalItems,
    required this.emailVerified,
    required this.personalPhoneVerified,
    required this.emergencyPhoneVerified,
    required this.governmentIdVerified,
    required this.onVerifyPressed,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show different banner based on verification status
    if (isVerified) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9), // light green background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.shade300,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.verified_user_rounded,
              color: Colors.green.shade800,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your account is verified",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "You are eligible to receive 3x more tenant requests!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Verification progress: $progressPercent% ($completedItems/$totalItems)",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onClose != null)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
          ],
        ),
      );
    } else {
      // Not verified - show original banner
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5), // light orange background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.shade300,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade800,
              size: 28,
            ),
            const SizedBox(width: 12),

            /// Text Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your account is not verified",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Verified owners get 3x more tenant requests.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progressPercent / 100,
                      backgroundColor: Colors.orange.shade100,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Verification progress: $progressPercent% ($completedItems/$totalItems)",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _statusRow('Email', emailVerified),
                  _statusRow('Personal Number', personalPhoneVerified),
                  _statusRow('Emergency Number', emergencyPhoneVerified),
                  _statusRow('Government ID', governmentIdVerified),
                  const SizedBox(height: 12),

                  /// Button
                  ElevatedButton(
                    onPressed: onVerifyPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Complete Verification",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            /// Optional Close Button
            if (onClose != null)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
          ],
        ),
      );
    }
  }

  Widget _statusRow(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: done ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            done ? 'Verified' : 'Pending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: done ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}