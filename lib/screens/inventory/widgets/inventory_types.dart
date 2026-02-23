import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryColumn {
  const InventoryColumn(this.label, this.key, {this.flex = 2});

  final String label;
  final String key;
  final int flex;
}

String displayValue(dynamic value) {
  if (value == null) {
    return '-';
  }
  if (value is Timestamp) {
    final d = value.toDate();
    return '${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';
  }
  if (value is num) {
    return value.toString();
  }
  return value.toString();
}

String _month(int m) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[m - 1];
}
