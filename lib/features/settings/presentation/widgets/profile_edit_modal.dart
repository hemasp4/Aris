import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileEditModal extends ConsumerStatefulWidget {
  final String? initialName;
  final String? initialEmail;

  const ProfileEditModal({
    super.key,
    this.initialName,
    this.initialEmail,
  });

  static Future<void> show(BuildContext context, {String? name, String? email}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileEditModal(
        initialName: name,
        initialEmail: email,
      ),
    );
  }

  @override
  ConsumerState<ProfileEditModal> createState() => _ProfileEditModalState();
}

class _ProfileEditModalState extends ConsumerState<ProfileEditModal> {
  late TextEditingController _nameController;
  late TextEditingController _emailController; // Usually read-only but shown
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      // Mock save delay
      await Future.delayed(const Duration(seconds: 1));
      
      // TODO: Implement actual update via AuthProvider
      // await ref.read(authProvider.notifier).updateProfile(name: _nameController.text);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  'Edit Profile',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Avatar Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: AppColors.avatarOrange,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (widget.initialName?.isNotEmpty == true)
                                ? widget.initialName!.substring(0, 2).toUpperCase()
                                : 'U',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceElevated : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.surface : Colors.white,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Name Field
                _buildTextField(
                  label: 'Name',
                  controller: _nameController,
                  isDark: isDark,
                ),
                
                const SizedBox(height: 24),
                
                // Email Field (Read-only)
                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  isDark: isDark,
                  readOnly: true,
                  hint: 'Verified',
                ),
                
                const SizedBox(height: 24),
                
                // Phone Field (Static for now)
                _buildTextField(
                  label: 'Phone number',
                  controller: TextEditingController(text: '+91 63799 22559'),
                  isDark: isDark,
                  readOnly: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    bool readOnly = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: readOnly 
                ? AppColors.textMuted 
                : AppColors.primaryText,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
