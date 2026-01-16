import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Group chat model
class GroupChat {
  final String id;
  final String title;
  final String? link;
  final List<String> members;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupChat({
    required this.id,
    required this.title,
    this.link,
    this.members = const [],
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  GroupChat copyWith({
    String? id,
    String? title,
    String? link,
    List<String>? members,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupChat(
      id: id ?? this.id,
      title: title ?? this.title,
      link: link ?? this.link,
      members: members ?? this.members,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Generate a random group link
  static String generateLink() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final linkId = List.generate(24, (_) => chars[random.nextInt(chars.length)]).join();
    return 'https://aris.app/gg/$linkId';
  }
}

/// Group chat state
class GroupChatState {
  final List<GroupChat> groups;
  final String? currentGroupId;
  final bool isLoading;

  const GroupChatState({
    this.groups = const [],
    this.currentGroupId,
    this.isLoading = false,
  });

  GroupChatState copyWith({
    List<GroupChat>? groups,
    String? currentGroupId,
    bool? isLoading,
  }) {
    return GroupChatState(
      groups: groups ?? this.groups,
      currentGroupId: currentGroupId ?? this.currentGroupId,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  GroupChat? get currentGroup {
    if (currentGroupId == null) return null;
    try {
      return groups.firstWhere((g) => g.id == currentGroupId);
    } catch (_) {
      return null;
    }
  }
}

/// Group chat notifier
class GroupChatNotifier extends StateNotifier<GroupChatState> {
  GroupChatNotifier() : super(const GroupChatState());

  /// Start a group chat from current conversation
  Future<GroupChat> startGroupChat({
    required String title,
    required String ownerId,
  }) async {
    state = state.copyWith(isLoading: true);
    
    final group = GroupChat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      link: GroupChat.generateLink(),
      members: [ownerId],
      ownerId: ownerId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      groups: [...state.groups, group],
      currentGroupId: group.id,
      isLoading: false,
    );

    return group;
  }

  /// Join a group via link
  Future<bool> joinViaLink(String link, String userId) async {
    // In real app, this would validate the link and join the group
    // For now, we simulate finding the group
    final group = state.groups.where((g) => g.link == link).firstOrNull;
    if (group != null && !group.members.contains(userId)) {
      final updated = group.copyWith(
        members: [...group.members, userId],
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        groups: state.groups.map((g) => g.id == group.id ? updated : g).toList(),
        currentGroupId: group.id,
      );
      return true;
    }
    return false;
  }

  /// Rename a group
  void renameGroup(String groupId, String newTitle) {
    state = state.copyWith(
      groups: state.groups.map((g) {
        if (g.id == groupId) {
          return g.copyWith(title: newTitle, updatedAt: DateTime.now());
        }
        return g;
      }).toList(),
    );
  }

  /// Delete a group
  void deleteGroup(String groupId) {
    state = state.copyWith(
      groups: state.groups.where((g) => g.id != groupId).toList(),
      currentGroupId: state.currentGroupId == groupId ? null : state.currentGroupId,
    );
  }

  /// Set current group
  void setCurrentGroup(String? groupId) {
    state = state.copyWith(currentGroupId: groupId);
  }

  /// Regenerate group link
  void regenerateLink(String groupId) {
    state = state.copyWith(
      groups: state.groups.map((g) {
        if (g.id == groupId) {
          return g.copyWith(link: GroupChat.generateLink(), updatedAt: DateTime.now());
        }
        return g;
      }).toList(),
    );
  }
}

/// Providers
final groupChatProvider = StateNotifierProvider<GroupChatNotifier, GroupChatState>((ref) {
  return GroupChatNotifier();
});

/// List of group chats
final groupChatsProvider = Provider<List<GroupChat>>((ref) {
  return ref.watch(groupChatProvider).groups;
});

/// Current group chat
final currentGroupProvider = Provider<GroupChat?>((ref) {
  return ref.watch(groupChatProvider).currentGroup;
});

/// Check if user has any group chats
final hasGroupChatsProvider = Provider<bool>((ref) {
  return ref.watch(groupChatProvider).groups.isNotEmpty;
});
