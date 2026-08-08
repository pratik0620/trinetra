import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/connection_request_model.dart';

class LocalConnectionItem {
  final String userId;
  final String phoneNumber;
  final String displayName;
  final DateTime? createdAt;
  final String syncStatus; // 'synced', 'pendingDelete'

  const LocalConnectionItem({
    required this.userId,
    required this.phoneNumber,
    required this.displayName,
    this.createdAt,
    this.syncStatus = 'synced',
  });

  factory LocalConnectionItem.fromJson(Map<String, dynamic> json) {
    return LocalConnectionItem(
      userId: json['userId'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? (json['phoneNumber'] ?? json['phone'] ?? ''),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      syncStatus: json['syncStatus'] ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'createdAt': createdAt?.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  UserConnectionItem toUserConnectionItem() {
    return UserConnectionItem(
      userId: userId,
      phoneNumber: phoneNumber,
      displayName: displayName,
      createdAt: createdAt,
    );
  }

  LocalConnectionItem copyWith({
    String? syncStatus,
  }) {
    return LocalConnectionItem(
      userId: userId,
      phoneNumber: phoneNumber,
      displayName: displayName,
      createdAt: createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class ConnectionLocalStorage {
  static const String _storageKeyPrefix = 'raksha_local_connections_';
  static const String _pendingDeletePrefix = 'raksha_pending_deletions_';

  /// Saves local connections list to SharedPreferences for a given user.
  Future<void> saveConnections(
      String currentUid, List<LocalConnectionItem> connections) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = connections.map((c) => c.toJson()).toList();
    await prefs.setString('$_storageKeyPrefix$currentUid', jsonEncode(jsonList));
  }

  /// Gets local connections for a given user.
  Future<List<LocalConnectionItem>> getConnections(String currentUid) async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString('$_storageKeyPrefix$currentUid');
    if (rawJson == null || rawJson.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(rawJson);
      return decoded.map((item) => LocalConnectionItem.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Adds or updates a single local connection.
  Future<void> upsertConnection(
      String currentUid, LocalConnectionItem newItem) async {
    final current = await getConnections(currentUid);
    final updated = current.where((c) => c.userId != newItem.userId).toList();
    updated.add(newItem);
    await saveConnections(currentUid, updated);
  }

  /// Removes a local connection completely.
  Future<void> removeConnection(String currentUid, String targetUserId) async {
    final current = await getConnections(currentUid);
    final updated = current.where((c) => c.userId != targetUserId).toList();
    await saveConnections(currentUid, updated);
  }

  /// Marks a connection as pending deletion locally.
  Future<void> markPendingDelete(String currentUid, String targetUserId) async {
    final current = await getConnections(currentUid);
    final updated = current.map((item) {
      if (item.userId == targetUserId) {
        return item.copyWith(syncStatus: 'pendingDelete');
      }
      return item;
    }).toList();
    await saveConnections(currentUid, updated);

    // Track pending deletion ID
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('$_pendingDeletePrefix$currentUid') ?? [];
    if (!pending.contains(targetUserId)) {
      pending.add(targetUserId);
      await prefs.setStringList('$_pendingDeletePrefix$currentUid', pending);
    }
  }

  /// Retrieves list of pending deletion target user IDs.
  Future<List<String>> getPendingDeletions(String currentUid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_pendingDeletePrefix$currentUid') ?? [];
  }

  /// Clears pending deletion status for a target user ID after cloud sync.
  Future<void> clearPendingDelete(String currentUid, String targetUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('$_pendingDeletePrefix$currentUid') ?? [];
    pending.remove(targetUserId);
    await prefs.setStringList('$_pendingDeletePrefix$currentUid', pending);
    await removeConnection(currentUid, targetUserId);
  }
}
