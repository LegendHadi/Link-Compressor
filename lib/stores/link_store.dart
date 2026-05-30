import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:link_compressor/models/link_item.dart';
import 'package:link_compressor/services/storage_service.dart';

class LinkStore extends ChangeNotifier {
  final StorageService storage;

  LinkStore({StorageService? storage}) : storage = storage ?? StorageService();

  final List<LinkItem> _links = [];
  List<LinkItem> get links => List.unmodifiable(_links);

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  static final List<Map<String, dynamic>> expireOptions = [
    {'label': '1 hour', 'duration': const Duration(hours: 1)},
    {'label': '1 day', 'duration': const Duration(days: 1)},
    {'label': '3 days', 'duration': const Duration(days: 3)},
    {'label': '1 week', 'duration': const Duration(days: 7)},
    {'label': '1 month', 'duration': const Duration(days: 30)},
  ];

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final loaded = await storage.loadLinks();
    _links
      ..clear()
      ..addAll(loaded);
    _isLoading = false;
    notifyListeners();
  }

  Future<LinkItem> addLink({
    required String originalUrl,
    String keywords = '',
    String selectedExpireLabel = 'No expiry',
    Duration? selectedExpireDuration,
  }) async {
    final token = _generateToken(originalUrl, keywords);
    final short = _buildUniqueShortLink(token, keywords);
    final expiresAt = selectedExpireDuration == null
        ? null
        : DateTime.now().add(selectedExpireDuration);

    final link = LinkItem(
      originalUrl: originalUrl,
      shortLink: short,
      createdAt: DateTime.now(),
      expiresLabel:
          selectedExpireLabel == 'No expiry' ? null : selectedExpireLabel,
      expiresAt: expiresAt,
    );

    _links.insert(0, link);
    await storage.saveLinks(_links);
    notifyListeners();
    return link;
  }

  Future<void> deleteAt(int index) async {
    if (index < 0 || index >= _links.length) return;
    _links.removeAt(index);
    await storage.saveLinks(_links);
    notifyListeners();
  }

  Future<void> insertAt(int index, LinkItem link) async {
    var position = index;
    if (position < 0) position = 0;
    if (position > _links.length) position = _links.length;
    _links.insert(position, link);
    await storage.saveLinks(_links);
    notifyListeners();
  }

  List<LinkItem> get filteredLinks {
    if (_searchQuery.isEmpty) return List.unmodifiable(_links);
    final q = _searchQuery.toLowerCase();
    return _links.where((link) {
      return link.originalUrl.toLowerCase().contains(q) ||
          link.shortLink.toLowerCase().contains(q);
    }).toList();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  String _generateToken(String url, String keywords) {
    final normalized = keywords.isEmpty ? url : '$url|$keywords';
    final hash = normalized.codeUnits
        .fold<int>(0, (acc, code) => (acc * 31 + code) & 0x7fffffff);
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer();
    var value = hash;
    for (var i = 0; i < 7; i++) {
      buffer.write(chars[value % chars.length]);
      value = value ~/ chars.length;
    }
    if (buffer.length < 7) {
      final random = Random(hash);
      while (buffer.length < 7) {
        buffer.write(chars[random.nextInt(chars.length)]);
      }
    }
    return buffer.toString();
  }

  String _buildShortLink(String token, String keywords) {
    if (keywords.isEmpty) return 'https://tamin.to/$token';

    final sanitizedKeywords = keywords
        .split(RegExp(r'[\s,]+'))
        .map((keyword) =>
            keyword.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), ''))
        .where((keyword) => keyword.isNotEmpty)
        .toList();

    if (sanitizedKeywords.isEmpty) return 'https://tamin.to/$token';

    final joinedKeywords = sanitizedKeywords.join('-');
    return 'https://tamin.to/$joinedKeywords-$token';
  }

  bool _shortLinkExists(String shortLink) {
    return _links.any((link) => link.shortLink == shortLink);
  }

  String _buildUniqueShortLink(String token, String keywords) {
    var candidate = _buildShortLink(token, keywords);
    var attempt = 1;

    while (_shortLinkExists(candidate)) {
      candidate = '${_buildShortLink(token, keywords)}-$attempt';
      attempt++;
    }

    return candidate;
  }

  String formatTimeLeft(DateTime expiresAt) {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 'Expired';
    final duration = expiresAt.difference(now);
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (parts.isEmpty) parts.add('${seconds}s');
    return 'Expires in ${parts.join(' ')}';
  }
}
