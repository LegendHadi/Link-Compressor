import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class LinkItem {
  final String originalUrl;
  final String shortLink;
  final DateTime createdAt;

  LinkItem({
    required this.originalUrl,
    required this.shortLink,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalUrl': originalUrl,
      'shortLink': shortLink,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LinkItem.fromJson(Map<String, dynamic> json) {
    return LinkItem(
      originalUrl: json['originalUrl'] as String,
      shortLink: json['shortLink'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _prefsKey = 'saved_links';

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _shortLink;
  String? _errorText;
  bool _copied = false;
  final List<LinkItem> _allLinks = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSavedLinks();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _submit() {
    final input = _urlController.text.trim();
    final validated = _validateUrl(input);

    setState(() {
      _copied = false;
      _shortLink = null;
      _errorText = null;
    });

    if (validated == null) {
      setState(() {
        _errorText =
            'Please enter a valid URL starting with http:// or https://';
      });
      return;
    }

    final token = _generateToken(validated);
    final shortLink = 'https://tamin.to/$token';

    final newLink = LinkItem(
      originalUrl: validated.toString(),
      shortLink: shortLink,
      createdAt: DateTime.now(),
    );

    setState(() {
      _shortLink = shortLink;
      _allLinks.insert(0, newLink);
    });

    _saveLinks();
  }

  Uri? _validateUrl(String text) {
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !(uri.hasScheme && (uri.isScheme('http') || uri.isScheme('https')))) {
      return null;
    }
    if (!uri.hasAuthority) return null;
    return uri;
  }

  String _generateToken(Uri uri) {
    final normalized = uri.toString();
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

  Future<void> _copyToClipboard() async {
    if (_shortLink == null) return;
    await Clipboard.setData(ClipboardData(text: _shortLink!));
    setState(() {
      _copied = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Short link copied to clipboard')),
      );
    }
  }

  List<LinkItem> _getFilteredLinks() {
    if (_searchQuery.isEmpty) {
      return _allLinks;
    }
    return _allLinks.where((link) {
      return link.originalUrl
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          link.shortLink.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _deleteLink(int index) {
    setState(() {
      _allLinks.removeAt(index);
    });
    _saveLinks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link deleted')),
    );
  }

  Future<void> _copyLinkToClipboard(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }

  Future<void> _loadSavedLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_prefsKey);
    if (savedValue == null || savedValue.isEmpty) return;

    try {
      final decoded = jsonDecode(savedValue) as List<dynamic>;
      final loadedLinks = decoded
          .map((item) => LinkItem.fromJson(item as Map<String, dynamic>))
          .toList();
      setState(() {
        _allLinks
          ..clear()
          ..addAll(loadedLinks);
      });
    } catch (_) {
      // If stored data is invalid, ignore it and start fresh.
    }
  }

  Future<void> _saveLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_allLinks.map((link) => link.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  @override
  Widget build(BuildContext context) {
    final filteredLinks = _getFilteredLinks();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[200],
        centerTitle: true,
        title: const Text('Link Compressor'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Column(
              children: [
                const Text(
                  'In this free website, you can compress and customize any links to a shorter version.\nAlso you can set expire date for links',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Original URL',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _urlController,
                                      keyboardType: TextInputType.url,
                                      textInputAction: TextInputAction.done,
                                      decoration: InputDecoration(
                                        // labelText: 'Long URL',
                                        hintText:
                                            'https://example.com/your/very/long/path',
                                        errorText: _errorText,
                                        border: const OutlineInputBorder(),
                                      ),
                                      onSubmitted: (_) => _submit(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: _submit,
                                    style: ButtonStyle(
                                      backgroundColor:
                                          WidgetStateProperty.all(Colors.red[400]),
                                    ),
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
                                      child: Text(
                                        'Compress',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: _shortLink != null
                                    ? _copyToClipboard
                                    : null,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 4),
                                  child: Text('Copy'),
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_shortLink != null) ...[
                                Text(
                                  'Generated short link',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 12),
                                SelectableText(
                                  _shortLink!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _copied
                                      ? 'Copied!'
                                      : 'Tap copy to save the link.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ] else ...[
                                Text(
                                  'Your short link will appear here when a valid URL is submitted.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Link History Section
                      if (_allLinks.isNotEmpty) ...[
                        Text(
                          'Link History (${_allLinks.length})',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        // Search Field
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search links',
                            hintText: 'Search by URL or short link',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Links List
                        if (filteredLinks.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredLinks.length,
                            itemBuilder: (context, index) {
                              final link = filteredLinks[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: SelectableText(
                                    link.shortLink,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      SelectableText(
                                        link.originalUrl,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        maxLines: 2,
                                        // overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Created: ${link.createdAt.toString().split('.')[0]}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey,
                                            ),
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Row(
                                          children: [
                                            Icon(Icons.copy, size: 18),
                                            SizedBox(width: 12),
                                            Text('Copy'),
                                          ],
                                        ),
                                        onTap: () => _copyLinkToClipboard(
                                            link.shortLink),
                                      ),
                                      PopupMenuItem(
                                        child: const Row(
                                          children: [
                                            Icon(Icons.delete,
                                                size: 18, color: Colors.red),
                                            SizedBox(width: 12),
                                            Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ],
                                        ),
                                        onTap: () {
                                          final actualIndex =
                                              _allLinks.indexOf(link);
                                          _deleteLink(actualIndex);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No links match your search',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                      ] else ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No links created yet. Create one above to get started!',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
