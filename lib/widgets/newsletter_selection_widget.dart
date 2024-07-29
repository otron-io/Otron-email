import 'package:flutter/material.dart';

class NewsletterSelectionWidget extends StatefulWidget {
  final List<String> availableNewsletters;
  final List<String> selectedNewsletters;
  final ValueChanged<List<String>> onChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;

  const NewsletterSelectionWidget({
    Key? key,
    required this.availableNewsletters,
    required this.selectedNewsletters,
    required this.onChanged,
    required this.onDateRangeChanged,
  }) : super(key: key);

  @override
  _NewsletterSelectionWidgetState createState() => _NewsletterSelectionWidgetState();
}

class _NewsletterSelectionWidgetState extends State<NewsletterSelectionWidget> {
  late List<String> _selectedItems;
  late TextEditingController _searchController;
  List<String> _filteredItems = [];
  String _customItem = '';
  String _selectedDateOption = 'Last 7 days';
  DateTimeRange? _customDateRange;

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

  void _updateDateRange() {
    DateTimeRange? newRange;
    switch (_selectedDateOption) {
      case 'Today':
        final now = DateTime.now();
        newRange = DateTimeRange(start: now, end: now);
        break;
      case 'Last 7 days':
        final now = DateTime.now();
        newRange = DateTimeRange(start: now.subtract(Duration(days: 7)), end: now);
        break;
      case 'Last 30 days':
        final now = DateTime.now();
        newRange = DateTimeRange(start: now.subtract(Duration(days: 30)), end: now);
        break;
      case 'Custom range':
        newRange = _customDateRange;
        break;
    }
    widget.onDateRangeChanged(newRange);
  }

  Widget _buildNewsletterChip(String newsletter) {
    String label = newsletter == '*@*' ? 'All Newsletters' : newsletter;
    return FilterChip(
      label: Text(label),
      selected: _selectedItems.contains(newsletter),
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            if (newsletter == '*@*') {
              _selectedItems = ['*@*'];
            } else {
              _selectedItems.remove('*@*');
              _selectedItems.add(newsletter);
            }
          } else {
            _selectedItems.remove(newsletter);
          }
          widget.onChanged(_selectedItems);
        });
      },
    );
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
            ..._filteredItems.map((item) => _buildNewsletterChip(item)),
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
          'Select Date Range',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: _selectedDateOption,
          onChanged: (String? newValue) {
            setState(() {
              _selectedDateOption = newValue!;
              _updateDateRange();
            });
          },
          items: <String>['Today', 'Last 7 days', 'Last 30 days', 'Custom range']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        if (_selectedDateOption == 'Custom range')
          ElevatedButton(
            onPressed: () async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                initialDateRange: _customDateRange,
              );
              if (picked != null && picked != _customDateRange) {
                setState(() {
                  _customDateRange = picked;
                  _updateDateRange();
                });
              }
            },
            child: Text(_customDateRange == null
                ? 'Select Custom Range'
                : '${_customDateRange!.start.toLocal().toString().split(' ')[0]} - ${_customDateRange!.end.toLocal().toString().split(' ')[0]}'),
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