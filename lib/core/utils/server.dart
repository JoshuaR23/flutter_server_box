import 'dart:async';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:toolbox/data/model/app/error.dart';
import 'package:toolbox/data/res/store.dart';

import '../../data/model/server/server_private_info.dart';

/// Must put this func out of any Class.
///
/// Because of this function is called by [compute].
///
/// https://stackoverflow.com/questions/51998995/invalid-arguments-illegal-argument-in-isolate-message-object-is-a-closure
List<SSHKeyPair> loadIndentity(String key) {
  return SSHKeyPair.fromPem(key);
}

/// [args] : [key, pwd]
String decyptPem(List<String> args) {
  /// skip when the key is not encrypted, or will throw exception
  if (!SSHKeyPair.isEncryptedPem(args[0])) return args[0];
  final sshKey = SSHKeyPair.fromPem(args[0], args[1]);
  return sshKey.first.toPem();
}

enum GenSSHClientStatus {
  socket,
  key,
  pwd,
}

String getPrivateKey(String id) {
  final pki = Stores.key.get(id);
  if (pki == null) {
    throw SSHErr(
      type: SSHErrType.noPrivateKey,
      message: 'key [$id] not found',
    );
  }
  return pki.key;
}

Future<SSHClient> genClient(
  ServerPrivateInfo spi, {
  void Function(GenSSHClientStatus)? onStatus,
  String? privateKey,
  Duration timeout = const Duration(seconds: 5),

  /// [ServerPrivateInfo] of the jump server
  ServerPrivateInfo? jumpSpi,
}) async {
  onStatus?.call(GenSSHClientStatus.socket);
  SSHSocket? socket;
  try {
    socket = await SSHSocket.connect(
      spi.ip,
      spi.port,
      timeout: timeout,
    );
  } catch (e) {
    if (spi.alterUrl == null) rethrow;
    try {
      final ipPort = spi.fromStringUrl();
      socket = await SSHSocket.connect(
        ipPort.ip,
        ipPort.port,
        timeout: timeout,
      );
    } catch (e) {
      rethrow;
    }
  }

  final forward = await () async {
    if (jumpSpi != null) {
      final jumpClient = await genClient(
        jumpSpi,
        privateKey: privateKey,
        timeout: timeout,
      );
      // Use `0.0.0.0` as localhost to use all interfaces.
      return await jumpClient.forwardLocal(
        spi.ip,
        spi.port,
        localHost: '0.0.0.0',
      );
    }
  }();

  if (spi.pubKeyId == null) {
    onStatus?.call(GenSSHClientStatus.pwd);
    return SSHClient(
      forward ?? socket,
      username: spi.user,
      onPasswordRequest: () => spi.pwd,
    );
  }
  privateKey ??= getPrivateKey(spi.pubKeyId!);

  onStatus?.call(GenSSHClientStatus.key);
  return SSHClient(
    forward ?? socket,
    username: spi.user,
    identities: await compute(loadIndentity, privateKey),
  );
}
