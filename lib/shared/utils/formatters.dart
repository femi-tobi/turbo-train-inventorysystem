import 'package:intl/intl.dart';

final _naira = NumberFormat('#,##0.00', 'en_NG');
final _number = NumberFormat('#,##0.##', 'en_NG');
final _dateFormat = DateFormat('dd MMM yyyy');
final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');
final _monthFormat = DateFormat('MMMM yyyy');
final _dbDateFormat = DateFormat('yyyy-MM-dd');

String formatNaira(num amount) => '₦${_naira.format(amount)}';

String formatNumber(num value) => _number.format(value);

String formatDate(DateTime date) => _dateFormat.format(date);

String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt);

String formatMonth(String yyyyMM) {
  try {
    final dt = DateTime.parse('$yyyyMM-01');
    return _monthFormat.format(dt);
  } catch (_) {
    return yyyyMM;
  }
}

String toDbDate(DateTime dt) => _dbDateFormat.format(dt);

DateTime fromDbDate(String s) => DateTime.parse(s);
