import 'dart:convert';

class LinkItem {
  final String originalUrl;
  final String shortLink;
  final DateTime createdTime;
  final String? expiresLabel;
  final DateTime? remainingTime;

  LinkItem({
    required this.originalUrl,
    required this.shortLink,
    required this.createdTime,
    this.expiresLabel,
    this.remainingTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalUrl': originalUrl,
      'shortLink': shortLink,
      'createdTime': createdTime.toIso8601String(),
      'expiresLabel': expiresLabel,
      'remainingTime': remainingTime?.toIso8601String(),
    };
  }

  factory LinkItem.fromJson(Map<String, dynamic> json) {
    return LinkItem(
      originalUrl: json['originalUrl'] as String,
      shortLink: json['shortLink'] as String,
      createdTime: DateTime.parse(json['createdTime'] as String),
      expiresLabel: json['expiresLabel'] as String?,
      remainingTime: json['remainingTime'] != null
          ? DateTime.parse(json['remainingTime'] as String)
          : null,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
