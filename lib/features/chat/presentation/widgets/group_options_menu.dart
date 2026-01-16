import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// ChatGPT-style Group Options dropdown menu
class GroupOptionsMenu extends StatelessWidget {
  final VoidCallback? onViewMembers;
  final VoidCallback? onAddMembers;
  final VoidCallback? onManageLink;
  final VoidCallback? onRename;
  final VoidCallback? onCustomize;
  final VoidCallback? onMute;
  final VoidCallback? onReport;
  final VoidCallback? onLeave;
  final VoidCallback? onDelete;

  const GroupOptionsMenu({
    super.key,
    this.onViewMembers,
    this.onAddMembers,
    this.onManageLink,
    this.onRename,
    this.onCustomize,
    this.onMute,
    this.onReport,
    this.onLeave,
    this.onDelete,
  });

  static void show(BuildContext context, {
    required Offset position,
    VoidCallback? onViewMembers,
    VoidCallback? onAddMembers,
    VoidCallback? onManageLink,
    VoidCallback? onRename,
    VoidCallback? onCustomize,
    VoidCallback? onMute,
    VoidCallback? onReport,
    VoidCallback? onLeave,
    VoidCallback? onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx - 200, position.dy, position.dx, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
      elevation: 8,
      items: <PopupMenuEntry<void>>[
        // Header
        PopupMenuItem(
          enabled: false,
          height: 32,
          child: Text(
            'New group chat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        const PopupMenuDivider(),
        // Normal items
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedUserGroup,
          label: 'View members',
          onTap: onViewMembers,
          isDark: isDark,
        ),
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedUserAdd01,
          label: 'Add members',
          onTap: onAddMembers,
          isDark: isDark,
        ),
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedLink01,
          label: 'Manage link',
          onTap: onManageLink,
          isDark: isDark,
        ),
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedEdit02,
          label: 'Rename group',
          onTap: onRename,
          isDark: isDark,
        ),
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedSettings02,
          label: 'Customize ChatGPT',
          onTap: onCustomize,
          isDark: isDark,
        ),
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedNotificationOff01,
          label: 'Mute notifications',
          onTap: onMute,
          isDark: isDark,
        ),
        const PopupMenuDivider(),
        // Destructive items (red)
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedFlag01,
          label: 'Report',
          onTap: onReport,
          isDark: isDark,
          isDestructive: true,
        ),
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedLogout01,
          label: 'Leave group',
          onTap: onLeave,
          isDark: isDark,
          isDestructive: true,
        ),
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedDelete02,
          label: 'Delete group',
          onTap: onDelete,
          isDark: isDark,
          isDestructive: true,
        ),
      ],
    );
  }

  static PopupMenuItem _buildMenuItem({
    required dynamic icon,
    required String label,
    required VoidCallback? onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    final color = isDestructive 
        ? const Color(0xFFEF4444) 
        : (isDark ? Colors.white : Colors.black);
    
    return PopupMenuItem(
      onTap: onTap,
      height: 48,
      child: Row(
        children: [
          HugeIcon(
            icon: icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget is used via show() static method
    return const SizedBox.shrink();
  }
}
