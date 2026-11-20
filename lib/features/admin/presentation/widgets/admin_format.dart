/// `13:37 20/11` in local time.
String adminStamp(DateTime time) {
  final local = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)} ${local.day}/${local.month}';
}
