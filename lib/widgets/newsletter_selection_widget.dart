import 'package:flutter/material.dart';

class NewsletterSelectionWidget extends StatefulWidget {
  final List<String> availableNewsletters;
  final List<String> selectedNewsletters;
  final ValueChanged<List<String>> onChanged;

  const NewsletterSelectionWidget({
    Key? key,
    required this.availableNewsletters,
    required this.selectedNewsletters,
    required this.onChanged,
  }) : super(key: key);

  @override
  _NewsletterSelectionWidgetState createState() => _NewsletterSelectionWidgetState();
}

class _NewsletterSelectionWidgetState extends State<NewsletterSelectionWidget> {
  late List<String> _selectedItems;
  late TextEditingController _searchController;
  List<String> _filteredItems = [];
  String _customItem = '';

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedNewsletters);
    _searchController = TextEditingController();
    _filteredItems = widget.availableNewsletters;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.availableNewsletters
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _customItem = query;
    });
  }

  void _addCustomItem() {
    if (_customItem.isNotEmpty && !_selectedItems.contains(_customItem)) {
      setState(() {
        _selectedItems.add(_customItem);
        widget.onChanged(_selectedItems);
        _searchController.clear();
        _customItem = '';
        _filteredItems = widget.availableNewsletters;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Newsletters or Add Custom Domains',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search or add newsletter/domain',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _filterItems,
                onSubmitted: (_) => _addCustomItem(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addCustomItem,
              child: Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Available Newsletters and Custom Items',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ..._filteredItems.map((item) => FilterChip(
              label: Text(item),
              selected: _selectedItems.contains(item),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedItems.add(item);
                  } else {
                    _selectedItems.remove(item);
                  }
                  widget.onChanged(_selectedItems);
                });
              },
            )),
            if (_customItem.isNotEmpty && !_filteredItems.contains(_customItem))
              FilterChip(
                label: Text(_customItem),
                selected: false,
                onSelected: (_) => _addCustomItem(),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Selected Items',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _selectedItems.map((item) => InputChip(
            label: Text(item),
            onDeleted: () {
              setState(() {
                _selectedItems.remove(item);
                widget.onChanged(_selectedItems);
              });
            },
          )).toList(),
        ),
      ],
    );
  }
}