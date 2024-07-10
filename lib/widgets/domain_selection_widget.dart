import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class DomainSelectionWidget extends StatelessWidget {
  final List<String> availableDomains;
  final List<String> selectedDomains;
  final ValueChanged<List<String>> onChanged;

  const DomainSelectionWidget({
    Key? key,
    required this.availableDomains,
    required this.selectedDomains,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<String>.multiSelection(
      items: availableDomains,
      selectedItems: selectedDomains,
      onChanged: onChanged,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Select Newsletters",
          hintText: "Choose newsletter domains",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}