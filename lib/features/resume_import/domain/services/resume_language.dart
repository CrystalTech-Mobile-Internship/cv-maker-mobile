/// Guesses whether a CV is written in Vietnamese or English.
///
/// Vietnamese text uses many letters with tone marks (ă, â, đ, ơ, ư, ạ...);
/// English CVs have almost none — at most a few in names or city names.
String detectResumeLanguage(String text) {
  final letters = RegExp(r'[A-Za-zÀ-ỹđĐ]').allMatches(text).length;
  if (letters == 0) return 'vi';
  final vietnamese = RegExp(
    r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
    caseSensitive: false,
  ).allMatches(text).length;
  return vietnamese / letters >= 0.02 ? 'vi' : 'en';
}
