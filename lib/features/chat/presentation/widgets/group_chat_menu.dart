import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// ChatGPT-style group chat options menu
/// Shows when tapping the user icon in top-right of group chat
class GroupChatMenu extends StatelessWidget {
  final String groupId;
  final String groupName;
  final VoidCallback? onViewMembers;
  final VoidCallback? onAddMembers;
  final VoidCallback? onManageLink;
  final VoidCallback? onRenameGroup;
  final VoidCallback? onCustomizeChatGPT;
  final VoidCallback? onMuteNotifications;
  final VoidCallback? onReport;
  final VoidCallback? onLeaveGroup;
  final VoidCallback? onDeleteGroup;
  final bool isMuted;

  const GroupChatMenu({
    super.key,
    required this.groupId,
    this.groupName = 'New group chat',
    this.onViewMembers,
    this.onAddMembers,
    this.onManageLink,
    this.onRenameGroup,
    this.onCustomizeChatGPT,
    this.onMuteNotifications,
    this.onReport,
    this.onLeaveGroup,
    this.onDeleteGroup,
    this.isMuted = false,
  });

  /// Show the menu as a popup from anchor
  static void show(
    BuildContext context, {
    required String groupId,
    String groupName = 'New group chat',
    VoidCallback? onViewMembers,
    VoidCallback? onAddMembers,
    VoidCallback? onManageLink,
    VoidCallback? onRenameGroup,
    VoidCallback? onCustomizeChatGPT,
    VoidCallback? onMuteNotifications,
    VoidCallback? onReport,
    VoidCallback? onLeaveGroup,
    VoidCallback? onDeleteGroup,
    bool isMuted = false,
  }) {
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GroupChatMenu(
        groupId: groupId,
        groupName: groupName,
        onViewMembers: onViewMembers,
        onAddMembers: onAddMembers,
        onManageLink: onManageLink,
        onRenameGroup: onRenameGroup,
        onCustomizeChatGPT: onCustomizeChatGPT,
        onMuteNotifications: onMuteNotifications,
        onReport: onReport,
        onLeaveGroup: onLeaveGroup,
        onDeleteGroup: onDeleteGroup,
        isMuted: isMuted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header with group name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              groupName,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const Divider(height: 1),
          
          // Menu items
          _buildMenuItem(
            context,
            icon: HugeIcons.strokeRoundedUserMultiple,
            label: 'View members',
            onTap: () {
              Navigator.pop(context);
              onViewMembers?.call();
            },
          ),
          
          _buildMenuItem(
            context,
            icon: HugeIcons.strokeRoundedUserAdd01,
            label: 'Add members',
            onTap: () {
              Navigator.pop(context);
              onAddMembers?.call();
            },
          ),
          
          _buildMenuItem(
            context,
            icon: HugeIcons.strokeRoundedLink01,
            label: 'Manage link',
            onTap: () {
              Navigator.pop(context);
              onManageLink?.call();
            },
          ),
          
          _buildMenuItem(
            context,
            icon: HugeIcons.strokeRoundedEdit02,
            label: 'Rename group',
            onTap: () {
              Navigator.pop(context);
              onRenameGroup?.call();
            },
          ),
          
          _buildMenuItem(
            context,
            icon: HugeIcons.strokeRoundedSettings02,
            label: 'Customize ChatGPT',
            onTap: () {
              Navigator.pop(context);
              onCustomizeChatGPT?.call();
            },
          ),
          
          _buildMenuItem(
            context,
            icon: isMuted 
                ? HugeIcons.strokeRoundedNotification03 
                : HugeIcons.strokeRoundedNotificationOff01,
            label: isMuted ? 'Unmute notifications' : 'Mute notifications',
            onTap: () {
              Navigator.pop(context);
              onMuteNotifications?.call();
            },
          ),
          
          const Divider(height: 1),
          
          // Danger zone - Red text items
          _buildMenuItem(
            context,
            icon: HugeIcons.strokeRoundedFlag02,
            label: 'Report',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              onReport?.call();
            },
          ),
          
          _buildMenuItem(
            context,
            icon: HugeIcons.strokeRoundedLogout01,
            label: 'Leave group',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              onLeaveGroup?.call();
            },
          ),
          
          _buildMenuItem(
            context,
            icon: HugeIcons.strokeRoundedDelete02,
            label: 'Delete group',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              onDeleteGroup?.call();
            },
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required dynamic icon,
    required String label,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive 
        ? Colors.red 
        : (isDark ? Colors.white : Colors.black87);
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              size: 22,
              color: color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
