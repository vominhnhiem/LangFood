import 'package:intl/intl.dart';

String money(num? value) => value == null
    ? 'Chưa có dữ liệu'
    : NumberFormat.currency(
        locale: 'vi_VN',
        symbol: 'đ',
        decimalDigits: 0,
      ).format(value);
String errorText(Object error) =>
    error.toString().replaceFirst(RegExp(r'^(Exception|Bad state): '), '');
String dateText(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null
      ? 'Chưa có thời gian'
      : DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
}
