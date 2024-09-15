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

  Future<void> setIdentifier(String value)async{
    await _sharedPreferences.setString('mllwtl_flutter_identifier', value);
  }

  String? getIdentifier() => _sharedPreferences.getString('mllwtl_flutter_identifier');
}
