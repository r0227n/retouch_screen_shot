import 'dart:ui';

import 'package:signals/signals.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final Signal<Settings> settings;

class Settings {
  Settings(this.prefs);
  final SharedPreferences prefs;
  final List<EffectCleanup> _cleanup = [];

  /// Retrieves and sets a setting value of type `T` identified by a given key.
  ///
  /// This function creates a signal for the setting value using the provided
  /// `get` function to retrieve the initial value. It also subscribes to changes
  /// in the signal and updates the setting value using the provided `set` function.
  ///
  /// The signal is added to the `_cleanup` list to ensure proper cleanup of
  /// subscriptions.
  ///
  /// - Parameters:
  ///   - key: The key identifying the setting.
  ///   - get: A function that retrieves the setting value as a `String`.
  ///   - set: A function that updates the setting value with a new value of type `T`.
  ///
  /// - Returns: A `Signal<T>` representing the setting value.
  Signal<T> _setting<T>(
    String key, {
    required T Function(String) get,
    required void Function(String, T?) set,
  }) {
    final s = signal<T>(get(key));
    _cleanup.add(s.subscribe((val) => set(key, val)));
    return s;
  }

  late Signal<Locale> locale = _setting(
    'locale',
    get: (key) => Locale(prefs.getString(key) ?? 'en'),
    set: (key, val) {
      if (val == null) {
        prefs.remove(key);
      } else {
        prefs.setString(key, val.languageCode);
      }
    },
  );

  void dispose() {
    for (final cb in _cleanup) {
      cb();
    }
  }
}
