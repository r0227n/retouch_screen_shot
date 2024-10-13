import 'package:flutter/widgets.dart' show BuildContext, Locale;
import 'l10n.dart';

export 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension LocaleX on Locale {
  String toLabel(BuildContext context) => switch (languageCode) {
        'ja' => '日本語',
        'en' => 'English',
        _ => 'English',
      };
}
