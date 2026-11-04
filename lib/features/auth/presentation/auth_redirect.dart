const _allowedAuthRedirects = {'/upgrade-pro'};

String? safeAuthRedirect(String? value) {
  if (value == null || !_allowedAuthRedirects.contains(value)) return null;
  return value;
}

String authEntryLocation(String path, String? redirectPath) {
  final safeRedirect = safeAuthRedirect(redirectPath);
  if (safeRedirect == null) return path;
  return Uri(
    path: path,
    queryParameters: {'redirect': safeRedirect},
  ).toString();
}
