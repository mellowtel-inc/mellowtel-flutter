import 'package:shared_preferences/shared_preferences.dart';

class LocalSharedPrefsService {
  final SharedPreferences _sharedPreferences;

  LocalSharedPrefsService(this._sharedPreferences);

  Future<void> setConsent(bool value) async {
    _sharedPreferences.setBool('consent', value);
  }

  bool? getConsent() {
    return _sharedPreferences.getBool('consent');
  }
}
