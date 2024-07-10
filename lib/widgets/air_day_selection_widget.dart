import 'package:flutter/material.dart';

class AirDaySelectionWidget extends StatelessWidget {
  final String airDay;
  final ValueChanged<String?> onChanged;

  const AirDaySelectionWidget({
    Key? key,
    required this.airDay,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: airDay,
      decoration: InputDecoration(
        labelText: 'Air Day',
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
      items: <String>['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}