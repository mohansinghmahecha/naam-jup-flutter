import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class MyProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    debugPrint(
      '[‼️‼️‼️Provider Change‼️‼️🔻] ${provider.name ?? provider.runtimeType} '
      'from $previousValue → $newValue',
    );
  }
}
