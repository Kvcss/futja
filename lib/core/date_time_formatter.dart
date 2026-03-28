class AppDateTimeFormatter {
  AppDateTimeFormatter._();

  static String shortDateTime(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');

    return '$dd/$mm às $hh:$min';
  }
}