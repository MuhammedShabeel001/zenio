import 'package:app/shared/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension StringX on String {
  String get displayCase => split('_')
      .map(
        (word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');

  String get sentenceCase {
    final words = split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1);
      } else {
        return word;
      }
    }).toList();

    return capitalizedWords.join(' ');
  }
}

extension ProviderContext on BuildContext {
  // Custom call a provider for reading method only
  // It will be helpful for us for calling the read function
  // without Consumer,ConsumerWidget or ConsumerStatefulWidget
  // Incase if you face any issue using this then please wrap your widget
  // with consumer and then call your provider

  T read<T>(ProviderBase<T> provider) {
    return ProviderScope.containerOf(this, listen: false).read(provider);
  }

  T watch<T>(ProviderBase<T> provider) {
    return ProviderScope.containerOf(this).read(provider);
  }
}

extension IterableExtensions<E> on Iterable<E> {
  List<T> mapIndexed<T>(T Function(int index, E item) f) {
    var index = 0;
    return map((e) => f(index++, e)).toList();
  }
}

extension Doublex on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

extension SpacingExtension on Flex {
  Flex withSpacing({
    double spacing = 0.0,
    Widget? seperator,
  }) {
    final spacedChildren = children
        .expand(
          (widget) =>
              [widget, seperator ?? SizedBox.square(dimension: spacing)],
        )
        .toList();

    if (spacedChildren.isNotEmpty) spacedChildren.removeLast();

    return Flex(
      direction: direction,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      key: key,
      clipBehavior: clipBehavior,
      children: spacedChildren,
    );
  }
}
