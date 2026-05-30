import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:link_compressor/stores/link_store.dart';

class LinkForm extends StatefulWidget {
  const LinkForm({super.key});

  @override
  State<LinkForm> createState() => _LinkFormState();
}

class _LinkFormState extends State<LinkForm> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;
  bool _copied = false;
  String? _shortLink;
  String _selectedExpireLabel = 'No expiry';
  Duration? _selectedExpireDuration;

  @override
  void dispose() {
    _urlController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<LinkStore>();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Original URL', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'https://example.com/your/very/long/path',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            const Text('Expire Date (optional)',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Builder(
              builder: (buttonContext) {
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () async {
                    await _showExpireOptions(buttonContext);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedExpireLabel),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Custom Keywords', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _keywordsController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Enter keywords separated by spaces or commas',
                border: OutlineInputBorder(),
                helperText:
                    'Keywords are used to build the generated short URL',
              ),
              onSubmitted: (_) => _submit(store),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submit(store),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red[400]),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Compressing...',
                              style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : const Text('Compress',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            if (_shortLink != null) ...[
              Text('Generated short link',
                  style: Theme.of(context).textTheme.bodyLarge),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SelectableText(
                      _shortLink!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _copyToClipboard(_shortLink!),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text('Copy'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: QrImageView(
                    data: _shortLink!,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedExpireLabel == 'No expiry'
                    ? 'No expiration configured.'
                    : 'Expires in $_selectedExpireLabel.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
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
    );
  }

  void _submit(LinkStore store) async {
    setState(() {
      _errorText = null;
      _copied = false;
      _shortLink = null;
    });

    final input = _urlController.text.trim();
    final validated = _validateUrl(input);
    if (validated == null) {
      setState(() {
        _errorText =
            'Please enter a valid URL starting with http:// or https://';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final keywordsText = _keywordsController.text.trim();
    final newLink = await store.addLink(
      originalUrl: validated.toString(),
      keywords: keywordsText,
      selectedExpireLabel: _selectedExpireLabel,
      selectedExpireDuration: _selectedExpireDuration,
    );

    setState(() {
      _isSubmitting = false;
      _shortLink = newLink.shortLink;
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

  Future<void> _copyToClipboard(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    setState(() {
      _copied = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Short link copied to clipboard')),
      );
    }
  }

  Future<void> _showExpireOptions(BuildContext context) async {
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final topRight = button.localToGlobal(button.size.topRight(Offset.zero),
        ancestor: overlay);
    final position = RelativeRect.fromLTRB(
      topRight.dx,
      topRight.dy,
      overlay.size.width - topRight.dx,
      overlay.size.height -
          button.localToGlobal(Offset.zero, ancestor: overlay).dy,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: [
        ...LinkStore.expireOptions.map((option) {
          return PopupMenuItem<String>(
            value: option['label'] as String,
            child: Text(option['label'] as String),
          );
        }),
        const PopupMenuItem<String>(
          value: 'No expiry',
          child: Text('No expiry'),
        ),
      ],
    );

    if (selected == null) return;

    setState(() {
      _selectedExpireLabel = selected;
      if (selected == 'No expiry') {
        _selectedExpireDuration = null;
      } else {
        final option = LinkStore.expireOptions.firstWhere(
          (option) => option['label'] == selected,
          orElse: () => LinkStore.expireOptions[0],
        );
        _selectedExpireDuration = option['duration'] as Duration;
      }
    });
  }
}
