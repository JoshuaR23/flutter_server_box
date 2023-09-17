import 'dart:io';

import 'package:flutter/foundation.dart';

enum PlatformType {
  android,
  ios,
  linux,
  macos,
  windows,
  web,
  fuchsia,
  unknown;

  String get prettyName {
    switch (this) {
      case PlatformType.android:
        return 'Android';
      case PlatformType.ios:
        return 'iOS';
      case PlatformType.linux:
        return 'Linux';
      case PlatformType.macos:
        return 'macOS';
      case PlatformType.windows:
        return 'Windows';
      case PlatformType.web:
        return 'Web';
      case PlatformType.fuchsia:
        return 'Fuchsia';
      case PlatformType.unknown:
        return 'Unknown';
    }
  }

  /// Whether has platform specific settings.
  bool get hasSettings {
    switch (this) {
      case PlatformType.android:
      case PlatformType.ios:
        return true;
      default:
        return false;
    }
  }
}

final _p = () {
  if (kIsWeb) {
    return PlatformType.web;
  }
  if (Platform.isAndroid) {
    return PlatformType.android;
  }
  if (Platform.isIOS) {
    return PlatformType.ios;
  }
  if (Platform.isLinux) {
    return PlatformType.linux;
  }
  if (Platform.isMacOS) {
    return PlatformType.macos;
  }
  if (Platform.isWindows) {
    return PlatformType.windows;
  }
  if (Platform.isFuchsia) {
    return PlatformType.fuchsia;
  }
  return PlatformType.unknown;
}();

PlatformType get platform => _p;

bool get isAndroid => _p == PlatformType.android;
bool get isIOS => _p == PlatformType.ios;
bool get isLinux => _p == PlatformType.linux;
bool get isMacOS => _p == PlatformType.macos;
bool get isWindows => _p == PlatformType.windows;
bool get isWeb => _p == PlatformType.web;
bool get isMobile => _p == PlatformType.ios || _p == PlatformType.android;
bool get isDesktop =>
    _p == PlatformType.linux ||
    _p == PlatformType.macos ||
    _p == PlatformType.windows;