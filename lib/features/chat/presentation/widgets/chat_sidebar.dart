import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/auth_service.dart' show User;
import '../../../auth/providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

/// Collapsible sidebar for chat navigation
class ChatSidebar extends ConsumerStatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;
  final VoidCallback onNewChat;
  
  const ChatSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
    required this.onNewChat,
  });

  @override
  ConsumerState<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends ConsumerState<ChatSidebar> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedFolder;
  
  final List<String> _folders = ['All', 'Pinned', 'Work', 'Personal', 'Archived'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = ref.watch(chatSessionsProvider);
    final chatState = ref.watch(chatProvider);
    final user = ref.watch(currentUserProvider);
    
    // Filter sessions based on search
    final filteredSessions = sessions.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    
    // Group by folder/filter
    final displaySessions = _filterByFolder(filteredSessions);

    if (widget.isCollapsed) {
      return _buildCollapsedSidebar(theme, user);
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with user info
          _buildHeader(theme, user),
          
          // New chat button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onNewChat,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('New Chat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Folder tabs
          _buildFolderTabs(theme),
          
          const Divider(height: 1),
          
          // Chat list
          Expanded(
            child: displaySessions.isEmpty
                ? _buildEmptyState(theme)
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: displaySessions.length,
                    onReorder: (oldIndex, newIndex) {
                      // Handle reorder
                    },
                    itemBuilder: (context, index) {
                      final session = displaySessions[index];
                      return _buildChatItem(
                        key: Key(session.id),
                        context: context,
                        session: session,
                        isActive: chatState.currentSessionId == session.id,
                      );
                    },
                  ),
          ),
          
          const Divider(height: 1),
          
          // Bottom actions
          _buildBottomActions(theme),
        ],
      ),
    );
  }

  Widget _buildCollapsedSidebar(ThemeData theme, User? user) {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          
          // Expand button
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: widget.onToggle,
            tooltip: 'Expand sidebar',
          ),
          
          const SizedBox(height: 8),
          
          // New chat
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: widget.onNewChat,
            tooltip: 'New chat',
          ),
          
          const SizedBox(height: 8),
          
          // Search
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              widget.onToggle();
            },
            tooltip: 'Search',
          ),
          
          const Spacer(),
          
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
            tooltip: 'Settings',
          ),
          
          const SizedBox(height: 8),
          
          // User avatar
          Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                user?.username.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, User? user) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              user?.username.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? 'User',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Pro Plan',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: widget.onToggle,
            tooltip: 'Collapse sidebar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderTabs(ThemeData theme) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _folders.map((folder) {
          final isSelected = _selectedFolder == folder || 
              (_selectedFolder == null && folder == 'All');
          
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ChoiceChip(
              label: Text(folder),
              selected: isSelected,
              onSelected: (_) => setState(() {
                _selectedFolder = folder == 'All' ? null : folder;
              }),
              labelStyle: TextStyle(fontSize: 12),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatItem({
    required Key key,
    required BuildContext context,
    required ChatSession session,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive 
            ? theme.colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            ref.read(chatProvider.notifier).loadMessages(session.id);
            context.go('/chat/${session.id}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  session.isPinned ? Icons.push_pin : Icons.chat_bubble_outline,
                  size: 18,
                  color: session.isPinned 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : null,
                        ),
                      ),
                      Text(
                        _formatDate(session.updatedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildChatContextMenu(session),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatContextMenu(ChatSession session) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              Icon(session.isPinned ? Icons.push_pin_outlined : Icons.push_pin, size: 18),
              const SizedBox(width: 8),
              Text(session.isPinned ? 'Unpin' : 'Pin'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'move',
          child: Row(
            children: [
              Icon(Icons.folder_open, size: 18),
              SizedBox(width: 8),
              Text('Move to folder'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive, size: 18),
              SizedBox(width: 8),
              Text('Archive'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 18),
              SizedBox(width: 8),
              Text('Share'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) => _handleContextAction(value, session),
    );
  }

  void _handleContextAction(String action, ChatSession session) {
    switch (action) {
      case 'rename':
        _showRenameDialog(session);
        break;
      case 'pin':
        // Toggle pin
        break;
      case 'move':
        _showMoveToFolderDialog(session);
        break;
      case 'archive':
        // Archive chat
        break;
      case 'share':
        // Share chat
        break;
      case 'delete':
        _showDeleteDialog(session);
        break;
    }
  }

  void _showRenameDialog(ChatSession session) {
    final controller = TextEditingController(text: session.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(chatProvider.notifier).renameSession(
                session.id,
                controller.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMoveToFolderDialog(ChatSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _folders.where((f) => f != 'All').map((folder) {
            return ListTile(
              leading: const Icon(Icons.folder),
              title: Text(folder),
              onTap: () => Navigator.pop(context),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDeleteDialog(ChatSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('This chat will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(chatProvider.notifier).deleteSession(session.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No chats found'
                : 'No chats yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onNewChat,
            child: const Text('Start a conversation'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Settings'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ChatSession> _filterByFolder(List<ChatSession> sessions) {
    if (_selectedFolder == null || _selectedFolder == 'All') {
      return sessions.where((s) => !s.isArchived).toList();
    }
    
    switch (_selectedFolder) {
      case 'Pinned':
        return sessions.where((s) => s.isPinned).toList();
      case 'Archived':
        return sessions.where((s) => s.isArchived).toList();
      default:
        return sessions.where((s) => !s.isArchived).toList();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
