import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';

/// ChatGPT-style "Use Aris together" bottom sheet modal
/// With integrated profile edit mode (Save/Cancel returns to main modal)
class GroupChatModal extends StatefulWidget {
  final VoidCallback? onStartGroupChat;
  final String userName;
  final String userInitials;
  final String? userAvatarUrl;

  const GroupChatModal({
    super.key,
    this.onStartGroupChat,
    this.userName = 'User',
    this.userInitials = 'U',
    this.userAvatarUrl,
  });

  static void show(BuildContext context, {
    VoidCallback? onStartGroupChat,
    String userName = 'User',
    String userInitials = 'U',
    String? userAvatarUrl,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GroupChatModal(
        onStartGroupChat: onStartGroupChat,
        userName: userName,
        userInitials: userInitials,
        userAvatarUrl: userAvatarUrl,
      ),
    );
  }

  @override
  State<GroupChatModal> createState() => _GroupChatModalState();
}

class _GroupChatModalState extends State<GroupChatModal> {
  bool _isEditMode = false;
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _usernameController = TextEditingController(text: widget.userInitials.toLowerCase());
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }
  
  void _saveProfile() {
    // TODO: Save profile to backend
    setState(() {
      _isEditMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: _isEditMode ? _buildEditMode(isDark) : _buildMainMode(isDark),
    );
  }
  
  /// Main mode - "Use Aris together" view
  Widget _buildMainMode(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Title - Changed from ChatGPT to Aris
        Text(
          'Use Aris together',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        // Description
        Text(
          'Add people to your chats to plan, share ideas, and get creative.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Start group chat button
        SizedBox(
          width: 175,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onStartGroupChat?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Start group chat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Profile card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.avatarOrange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.userInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Name and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose a username and photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Edit icon
              GestureDetector(
                onTap: _toggleEditMode,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedEdit02,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Edit mode - Profile edit view (matching ChatGPT Image 2)
  Widget _buildEditMode(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Large Avatar with camera icon
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.avatarOrange,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _nameController.text.isNotEmpty 
                      ? _nameController.text.substring(0, 2).toUpperCase()
                      : widget.userInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Name field
        _buildTextField(
          label: 'Name',
          controller: _nameController,
          isDark: isDark,
        ),
        
        const SizedBox(height: 16),
        
        // Username field
        _buildTextField(
          label: 'Username',
          controller: _usernameController,
          isDark: isDark,
        ),
        
        const SizedBox(height: 16),
        
        // Helper text
        Text(
          'Your profile helps people recognize you. Your name and username are also used in the Sora app.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Save profile button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Save profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Cancel button - Returns to main modal, NOT dismiss
        TextButton(
          onPressed: _toggleEditMode,
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
