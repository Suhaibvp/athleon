import 'package:shared_preferences/shared_preferences.dart';

class SavedTimes {
  static const prepKey = 'finals_prep';
  static const changeKey = 'finals_change';
  static const setKey = 'finals_set';
  static const rapidKey = 'rapid_times';
  static const standardKey = 'standard_times';

  static Future<({String? prep, String? change, String? setTime})> finals() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      prep: prefs.getString(prepKey),
      change: prefs.getString(changeKey),
      setTime: prefs.getString(setKey),
    );
  }

  static Future<void> saveFinals({
    String? prep,
    String? change,
    String? setTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prep != null) await prefs.setString(prepKey, prep);
    if (change != null) await prefs.setString(changeKey, change);
    if (setTime != null) await prefs.setString(setKey, setTime);
  }

  static Future<List<int>> ints(String key, List<int> fallback) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key);
    if (raw == null || raw.length != fallback.length) return List.of(fallback);
    return raw.map((value) => int.tryParse(value) ?? 0).toList();
  }

  static Future<void> saveInts(String key, List<int> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, values.map((value) => '$value').toList());
  }
}
