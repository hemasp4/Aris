import 'package:dio/dio.dart';
import '../../../core/services/dio_client.dart';
import '../../../core/constants/api_constants.dart';

/// Vault service for secure storage operations
class VaultService {
  final DioClient _client = DioClient();

  /// Get vault status
  Future<VaultStatus> getStatus() async {
    try {
      final response = await _client.dio.get('/vault/status');
      return VaultStatus.fromJson(response.data);
    } catch (e) {
      return VaultStatus(enabled: false, unlocked: false, hasPin: false);
    }
  }

  /// Setup vault with PIN
  Future<bool> setupVault(String pin) async {
    try {
      await _client.dio.post('/vault/setup', data: {'pin': pin});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Unlock vault with PIN
  Future<bool> unlockWithPin(String pin) async {
    try {
      await _client.dio.post('/vault/unlock', data: {'pin': pin});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Unlock vault with biometric (frontend verified)
  Future<bool> unlockWithBiometric() async {
    try {
      await _client.dio.post('/vault/unlock-biometric');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Lock vault
  Future<void> lock() async {
    try {
      await _client.dio.post('/vault/lock');
    } catch (e) {
      // Ignore
    }
  }

  /// Get vault items
  Future<List<VaultItem>> getItems() async {
    try {
      final response = await _client.dio.get('/vault/items');
      final List items = response.data;
      return items.map((json) => VaultItem.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add vault item
  Future<VaultItem?> addItem({
    required String title,
    required String content,
    String type = 'note',
    List<String>? tags,
  }) async {
    try {
      final response = await _client.dio.post('/vault/items', data: {
        'title': title,
        'content': content,
        'item_type': type,
        'tags': tags,
      });
      return VaultItem.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Delete vault item
  Future<bool> deleteItem(String itemId) async {
    try {
      await _client.dio.delete('/vault/items/$itemId');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Change vault PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      await _client.dio.post('/vault/change-pin', queryParameters: {
        'old_pin': oldPin,
        'new_pin': newPin,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Vault status
class VaultStatus {
  final bool enabled;
  final bool unlocked;
  final bool hasPin;

  VaultStatus({
    required this.enabled,
    required this.unlocked,
    required this.hasPin,
  });

  factory VaultStatus.fromJson(Map<String, dynamic> json) {
    return VaultStatus(
      enabled: json['enabled'] ?? false,
      unlocked: json['unlocked'] ?? false,
      hasPin: json['has_pin'] ?? false,
    );
  }
}

/// Vault item
class VaultItem {
  final String id;
  final String title;
  final String content;
  final String itemType;
  final String createdAt;
  final String updatedAt;
  final List<String> tags;

  VaultItem({
    required this.id,
    required this.title,
    required this.content,
    required this.itemType,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      itemType: json['item_type'] ?? 'note',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

/// Global vault service
final vaultService = VaultService();
