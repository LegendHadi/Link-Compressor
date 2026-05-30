import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:link_compressor/models/link_item.dart';

class StorageService {
  static const _prefsKey = 'saved_links';

  Future<List<LinkItem>> loadLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_prefsKey);
    if (savedValue == null || savedValue.isEmpty) return [];

    try {
      final decoded = jsonDecode(savedValue) as List<dynamic>;
      final loadedLinks = decoded
          .map((item) => LinkItem.fromJson(item as Map<String, dynamic>))
          .toList();
      return loadedLinks;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLinks(List<LinkItem> links) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(links.map((l) => l.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }
}
