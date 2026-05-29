import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Link Compressor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Link Compressor'),
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
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _shortLink;
  String? _errorText;
  bool _copied = false;
  final List<LinkItem> _allLinks = [];
  String _searchQuery = '';

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

    setState(() {
      _shortLink = shortLink;
      _allLinks.insert(
          0,
          LinkItem(
            originalUrl: validated.toString(),
            shortLink: shortLink,
            createdAt: DateTime.now(),
          ));
    });
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

  @override
  Widget build(BuildContext context) {
    final filteredLinks = _getFilteredLinks();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Link Generator Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Shorten any long URL instantly',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter a long link below and press Shorten to generate a frontend mock short URL.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _urlController,
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Long URL',
                              hintText:
                                  'https://example.com/your/very/long/path',
                              errorText: _errorText,
                              border: const OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Text('Shorten'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
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
                            ],
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    link.originalUrl,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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
                                    onTap: () =>
                                        _copyLinkToClipboard(link.shortLink),
                                  ),
                                  PopupMenuItem(
                                    child: const Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 18, color: Colors.red),
                                        SizedBox(width: 12),
                                        Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red)),
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
          ),
        ),
      ),
    );
  }
}
