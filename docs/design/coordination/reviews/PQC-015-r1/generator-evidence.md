# SDK generator structure evidence

SDK revision `abaf9c523780a608bd46686fd5e53740a07077f8`, matching the CI-reported revision.
Fetched via GitHub API. These are source excerpts, **not local gen-l10n execution**.
The reviewed repository tracks only `app_localizations.dart` with inline En/Vi classes.
The SDK generator below emits language files and imports them into the base file.

## gen_l10n.dart:1131–1188

[Exact source](https://github.com/flutter/flutter/blob/abaf9c523780a608bd46686fd5e53740a07077f8/packages/flutter_tools/lib/src/localizations/gen_l10n.dart#L1131-L1188)

```dart

    final supportedLanguageCodes = Set<String>.from(
      _allBundles.locales.map<String>((LocaleInfo locale) => "'${locale.languageCode}'"),
    );

    final List<LocaleInfo> allLocales = _allBundles.locales.toList()..sort();
    final int extensionIndex = outputFileName.indexOf('.');
    if (extensionIndex <= 0) {
      throw L10nException(
        "The 'output-localization-file', $outputFileName, is invalid.\n"
        'The base name cannot be empty.',
      );
    }
    final String fileName = outputFileName.substring(0, extensionIndex);
    final String fileExtension = outputFileName.substring(extensionIndex + 1);
    for (final locale in allLocales) {
      if (isBaseClassLocale(locale, locale.languageCode)) {
        final File languageMessageFile = outputDirectory.childFile(
          '${fileName}_$locale.$fileExtension',
        );

        // Generate the template for the base class file. Further string
        // interpolation will be done to determine if there are
        // subclasses that extend the base class.
        final String languageBaseClassFile = _generateBaseClassFile(
          className,
          outputFileName,
          header,
          locale,
        );

        // Every locale for the language except the base class.
        final List<LocaleInfo> localesForLanguage = getLocalesForLanguage(locale.languageCode);

        // Generate every subclass that is needed for the particular language
        final Iterable<String> subclasses = localesForLanguage.map<String>((LocaleInfo locale) {
          return _generateSubclass(className, _allBundles.bundleFor(locale)!);
        });

        _languageFileMap.putIfAbsent(languageMessageFile, () {
          return languageBaseClassFile.replaceAll('@(subclasses)', subclasses.join());
        });
      }
    }

    final List<String> sortedClassImports =
        supportedLocales
            .where((LocaleInfo locale) => isBaseClassLocale(locale, locale.languageCode))
            .map((LocaleInfo locale) {
              final library = '${fileName}_$locale';
              if (useDeferredLoading) {
                return "import '$library.$fileExtension' deferred as $library;";
              } else {
                return "import '$library.$fileExtension';";
              }
            })
            .toList()
          ..sort();
```

## gen_l10n.dart:1443–1451

[Exact source](https://github.com/flutter/flutter/blob/abaf9c523780a608bd46686fd5e53740a07077f8/packages/flutter_tools/lib/src/localizations/gen_l10n.dart#L1443-L1451)

```dart
    // Generate the required files for localizations.
    _languageFileMap.forEach((File file, String contents) {
      file.writeAsStringSync(useCRLF ? contents.replaceAll('\n', '\r\n') : contents);
      _addToFileList(_outputFileList, file.absolute.path);
    });

    baseOutputFile.writeAsStringSync(
      useCRLF ? generatedLocalizationsFile.replaceAll('\n', '\r\n') : generatedLocalizationsFile,
    );
```

## gen_l10n_templates.dart:5–18

[Exact source](https://github.com/flutter/flutter/blob/abaf9c523780a608bd46686fd5e53740a07077f8/packages/flutter_tools/lib/src/localizations/gen_l10n_templates.dart#L5-L18)

```dart
const fileTemplate = '''
@(header)import 'dart:async';

@(requiresFoundationImport)
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

@(messageClassImports)

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of @(class)
/// returned by `@(class).of(context)`.
```

## gen_l10n_templates.dart:169–182

[Exact source](https://github.com/flutter/flutter/blob/abaf9c523780a608bd46686fd5e53740a07077f8/packages/flutter_tools/lib/src/localizations/gen_l10n_templates.dart#L169-L182)

```dart
const classFileTemplate = '''
@(header)// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import '@(fileName)';

// ignore_for_file: type=lint

/// The translations for @(language) (`@(localeName)`).
class @(class) extends @(baseClass) {
  @(class)([String locale = '@(localeName)']) : super(locale);

@(methods)
}
@(subclasses)''';
```
