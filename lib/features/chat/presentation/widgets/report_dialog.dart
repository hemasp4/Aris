import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class ReportDialog extends StatefulWidget {
  final VoidCallback? onSubmit;

  const ReportDialog({super.key, this.onSubmit});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ReportDialog(),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final TextEditingController _otherController = TextEditingController();

  final List<String> _reasons = [
    'Harmful or unsafe',
    'Spam or misleading',
    'Inappropriate content',
    'Other',
  ];

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Report this chat?',
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a reason for reporting:',
              style: GoogleFonts.inter(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ..._reasons.map((reason) => _buildRadioOption(reason, isDark)),
            
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _otherController,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Please describe...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.black12 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null 
              ? null 
              : () {
                  // Handle submit
                  widget.onSubmit?.call();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted')),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: Text(
            'Submit', 
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String value, bool isDark) {
    return RadioListTile<String>(
      title: Text(
        value,
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 15,
        ),
      ),
      value: value,
      groupValue: _selectedReason,
      onChanged: (newValue) {
        setState(() => _selectedReason = newValue);
      },
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}
