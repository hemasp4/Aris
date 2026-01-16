import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/auth_service.dart' show User;
import '../../../auth/providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/group_chat_provider.dart';

/// ChatGPT-EXACT sidebar
/// - Search bar at top (rounded pill)
/// - New chat with pen-in-square icon
/// - Chat history (plain text, date grouped)
/// - Personal Space section
/// - User profile at bottom
class ChatSidebar extends ConsumerStatefulWidget {
  const ChatSidebar({super.key});

  @override
  ConsumerState<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends ConsumerState<ChatSidebar> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Group sessions by date
  Map<String, List<ChatSession>> _groupSessionsByDate(List<ChatSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    final Map<String, List<ChatSession>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Previous 7 Days': [],
      'Previous 30 Days': [],
      'Older': [],
    };

    for (final session in sessions) {
      final sessionDate = DateTime(
        session.updatedAt.year,
        session.updatedAt.month,
        session.updatedAt.day,
      );

      if (sessionDate.isAtSameMomentAs(today) || sessionDate.isAfter(today)) {
        grouped['Today']!.add(session);
      } else if (sessionDate.isAtSameMomentAs(yesterday)) {
        grouped['Yesterday']!.add(session);
      } else if (sessionDate.isAfter(weekAgo)) {
        grouped['Previous 7 Days']!.add(session);
      } else if (sessionDate.isAfter(monthAgo)) {
        grouped['Previous 30 Days']!.add(session);
      } else {
        grouped['Older']!.add(session);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(chatSessionsProvider);
    final chatState = ref.watch(chatProvider);
    final user = ref.watch(currentUserProvider);
    
    // Filter sessions based on search
    final filteredSessions = sessions.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    
    // Sort by updated date (newest first)
    filteredSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    // Group by date
    final groupedSessions = _groupSessionsByDate(filteredSessions);
    // Check if search is focused to expand sidebar
    final isFocused = _searchFocusNode.hasFocus || _searchQuery.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      backgroundColor: AppColors.background,
      width: isFocused ? screenWidth * 1 : 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Search bar + New Chat button
            _buildHeader(context),
            
            const SizedBox(height: 8),
            
            // New chat item
            _buildNewChatItem(),
            
            const SizedBox(height: 8),
            
            // Chat history with date grouping
            Expanded(
              child: groupedSessions.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final entry in groupedSessions.entries) ...[
                          _buildDateHeader(entry.key),
                          ...entry.value.map((session) => _buildChatItem(
                            context: context,
                            session: session,
                            isActive: chatState.currentSessionId == session.id,
                          )),
                        ],
                      ],
                    ),
            ),
            
            // Personal Space section
            _buildPersonalSpaceItem(context),
            
            const SizedBox(height: 8),
            
            // User profile at bottom
            _buildUserProfile(context, user),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: _buildSearchBar(),
          ),
          const SizedBox(width: 8),
          // New chat button - always visible
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              ref.read(chatProvider.notifier).clearCurrentSession();
              ref.read(groupChatProvider.notifier).setCurrentGroup(null);
            },
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedPencilEdit02,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isFocused = _searchFocusNode.hasFocus || _searchQuery.isNotEmpty;
    
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface, // Subtle dark gray matching ChatGPT
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // Back arrow when focused, search icon when not
          GestureDetector(
            onTap: isFocused
                ? () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                    setState(() => _searchQuery = '');
                  }
                : null,
            child: HugeIcon(
              icon: isFocused
                  ? HugeIcons.strokeRoundedArrowLeft02
                  : HugeIcons.strokeRoundedSearch01,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) => setState(() => _searchQuery = value),
              onTap: () => setState(() {}), // Trigger rebuild for focus state
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: const InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
                filled: true,
                fillColor: AppColors.surface, 
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,  
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewChatItem() {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        ref.read(chatProvider.notifier).clearCurrentSession();
        ref.read(groupChatProvider.notifier).setCurrentGroup(null);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Edit icon (no border, just the icon)
            HugeIcon(
              icon: HugeIcons.strokeRoundedPencilEdit02,
              size: 22,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            const Text(
              'New chat',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildChatItem({
    required BuildContext context,
    required ChatSession session,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        ref.read(groupChatProvider.notifier).setCurrentGroup(null);
        ref.read(chatProvider.notifier).loadMessages(session.id);
        context.go('/chat/${session.id}');
      },
      onLongPress: () => _showChatContextMenu(context, session),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: isActive ? AppColors.sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  void _showChatContextMenu(BuildContext context, ChatSession session) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              session.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedPin,
                size: 22,
                color: AppColors.textPrimary,
              ),
              title: Text(
                session.isPinned ? 'Unpin chat' : 'Pin chat',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(chatProvider.notifier).togglePinSession(session.id);
              },
            ),
            ListTile(
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                size: 22,
                color: AppColors.error,
              ),
              title: const Text(
                'Delete chat',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(chatProvider.notifier).deleteSession(session.id);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _searchQuery.isEmpty ? 'No chats yet' : 'No chats found',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPersonalSpaceItem(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        context.go('/vault');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedConstellation,
              size: 20,
              color: AppColors.privateSpace,
            ),
            const SizedBox(width: 12),
            const Text(
              'Personal Space',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, User? user) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        context.go('/settings');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Orange avatar with initials
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.avatarOrange,
              child: Text(
                user != null && user.username.length >= 2 
                    ? user.username.substring(0, 2).toUpperCase() 
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user?.username ?? 'User',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
