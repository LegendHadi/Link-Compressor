import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:link_compressor/stores/expiry_notifier.dart';
import 'package:link_compressor/stores/link_store.dart';
import 'package:link_compressor/models/link_item.dart';

class LinkHistory extends StatefulWidget {
  const LinkHistory({super.key});

  @override
  State<LinkHistory> createState() => _LinkHistoryState();
}

class _LinkHistoryState extends State<LinkHistory> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LinkStore>();
    context.watch<ExpiryNotifier>();
    final filteredLinks = store.filteredLinks;

    if (store.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (store.links.isNotEmpty) ...[
          Text('Link History (${store.links.length})',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search links',
              hintText: 'Search by URL or short link',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: store.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<LinkStore>().setSearchQuery('');
                      },
                    )
                  : null,
            ),
            onChanged: context.read<LinkStore>().setSearchQuery,
          ),
          const SizedBox(height: 16),
          if (filteredLinks.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredLinks.length,
              itemBuilder: (context, index) {
                final link = filteredLinks[index];
                final actualIndex = store.links
                    .indexWhere((l) => l.shortLink == link.shortLink);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: SelectableText(
                      link.shortLink,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        SelectableText(
                          link.originalUrl,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${link.createdTime.toString().split('.')[0]}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                        if (link.remainingTime != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            store.formatTimeLeft(link.remainingTime!),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                          ),
                        ],
                      ],
                    ),
                    trailing: PopupMenuButton<_LinkMenuAction>(
                      onSelected: (action) =>
                          _handleMenuAction(action, actualIndex, link, store),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: _LinkMenuAction.copy,
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 18),
                              SizedBox(width: 12),
                              Text('Copy'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: _LinkMenuAction.delete,
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
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
    );
  }

  void _handleMenuAction(_LinkMenuAction action, int actualIndex, LinkItem link,
      LinkStore store) async {
    if (action == _LinkMenuAction.copy) {
      await Clipboard.setData(ClipboardData(text: link.shortLink));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
      return;
    }

    if (action == _LinkMenuAction.delete) {
      await store.deleteAt(actualIndex);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Link deleted'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              store.insertAt(actualIndex, link);
            },
          ),
        ),
      );
    }
  }
}

enum _LinkMenuAction { copy, delete }
