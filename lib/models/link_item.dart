import 'dart:convert';

class LinkItem {
  final String originalUrl;
  final String shortLink;
  final DateTime createdAt;
  final String? expiresLabel;
  final DateTime? expiresAt;

  LinkItem({
    required this.originalUrl,
    required this.shortLink,
    required this.createdAt,
    this.expiresLabel,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalUrl': originalUrl,
      'shortLink': shortLink,
      'createdAt': createdAt.toIso8601String(),
      'expiresLabel': expiresLabel,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory LinkItem.fromJson(Map<String, dynamic> json) {
    return LinkItem(
      originalUrl: json['originalUrl'] as String,
      shortLink: json['shortLink'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresLabel: json['expiresLabel'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
