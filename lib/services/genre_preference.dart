import 'package:shared_preferences/shared_preferences.dart';

class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const selectedGenreKey = 'selected_genre';
  final SharedPreferencesAsync _preferences;

  Future<String> read() async {
    return await _preferences.getString(selectedGenreKey) ?? '전체';
  }

  Future<void> save(String genre) async {
    await _preferences.setString(selectedGenreKey, genre);
  }

  Future<void> clear() async {
    await _preferences.remove(selectedGenreKey);
  }
}
