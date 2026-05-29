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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _urlController = TextEditingController();
  String? _shortLink;
  String? _errorText;
  bool _copied = false;

  @override
  void dispose() {
    _urlController.dispose();
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
        _errorText = 'Please enter a valid URL starting with http:// or https://';
      });
      return;
    }

    final token = _generateToken(validated);
    setState(() {
      _shortLink = 'https://tamin.to/$token';
    });
  }

  Uri? _validateUrl(String text) {
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !(uri.hasScheme && (uri.isScheme('http') || uri.isScheme('https')))) {
      return null;
    }
    if (!uri.hasAuthority) return null;
    return uri;
  }

  String _generateToken(Uri uri) {
    final normalized = uri.toString();
    final hash = normalized.codeUnits.fold<int>(0, (acc, code) => (acc * 31 + code) & 0x7fffffff);
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
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

  @override
  Widget build(BuildContext context) {
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
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          hintText: 'https://example.com/your/very/long/path',
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
                            onPressed: _shortLink != null ? _copyToClipboard : null,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _copied ? 'Copied!' : 'Tap copy to save the link.',
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
            ),
          ),
        ),
      ),
    );
  }
}
