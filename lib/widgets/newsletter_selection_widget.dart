import 'package:flutter/material.dart';
import 'dart:async';

class NewsletterSelectionWidget extends StatefulWidget {
  final List<String> availableNewsletters;
  final List<String> selectedNewsletters;
  final ValueChanged<List<String>> onChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final ValueChanged<String?> onToEmailChanged;

  const NewsletterSelectionWidget({
    Key? key,
    required this.availableNewsletters,
    required this.selectedNewsletters,
    required this.onChanged,
    required this.onDateRangeChanged,
    required this.onToEmailChanged,
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
  late TextEditingController _toEmailController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedNewsletters);
    _searchController = TextEditingController();
    _filteredItems = widget.availableNewsletters;
    _toEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _toEmailController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _filterItems(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _filteredItems = widget.availableNewsletters
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _customItem = query;
      });
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
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search newsletters...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: _filterItems,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _filteredItems.map((item) => InputChip(
            label: Text(item),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedItems.add(item);
                } else {
                  _selectedItems.remove(item);
                }
                widget.onChanged(_selectedItems);
              });
            },
            selected: _selectedItems.contains(item),
          )).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'Date Range',
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
          'Filter by "To" Email',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _toEmailController,
          decoration: InputDecoration(
            hintText: 'e.g., podcast+arnoldas@otrion.io',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: widget.onToEmailChanged,
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

  void _updateDateRange() {
    if (_selectedDateOption == 'Custom range') {
      widget.onDateRangeChanged(_customDateRange);
    } else {
      DateTime now = DateTime.now();
      DateTime startDate;
      if (_selectedDateOption == 'Today') {
        startDate = now;
      } else if (_selectedDateOption == 'Last 7 days') {
        startDate = now.subtract(Duration(days: 7));
      } else {
        startDate = now.subtract(Duration(days: 30));
      }
      widget.onDateRangeChanged(DateTimeRange(start: startDate, end: now));
    }
  }
}