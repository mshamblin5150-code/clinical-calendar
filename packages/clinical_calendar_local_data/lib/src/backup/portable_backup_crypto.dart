import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'portable_backup_models.dart';

final class PortableBackupCrypto {
  PortableBackupCrypto({
    this.policy = const PortableBackupCryptoPolicy(),
    Random? secureRandom,
  }) : _random = secureRandom ?? Random.secure();

  static const containerVersion = 1;
  static const magic = 'clinical-calendar-portable-backup';

  final PortableBackupCryptoPolicy policy;
  final Random _random;
  final AesGcm _cipher = AesGcm.with256bits();

  Future<List<int>> encrypt({
    required List<int> plaintext,
    required String passphrase,
  }) async {
    _checkPassphrase(passphrase);
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final header = <String, Object?>{
      'magic': magic,
      'container_version': containerVersion,
      'kdf': 'argon2id',
      'memory_kib': policy.memoryKib,
      'iterations': policy.iterations,
      'parallelism': policy.parallelism,
      'salt': base64Url.encode(salt),
      'cipher': 'aes-256-gcm',
      'nonce': base64Url.encode(nonce),
    };
    final aad = utf8.encode(canonicalJson(header));
    final key = await _deriveKey(passphrase, salt, policy);
    try {
      final box = await _cipher.encrypt(
        plaintext,
        secretKey: key,
        nonce: nonce,
        aad: aad,
      );
      return utf8.encode(
        canonicalJson({
          ...header,
          'ciphertext': base64Url.encode(box.cipherText),
          'authentication_tag': base64Url.encode(box.mac.bytes),
        }),
      );
    } finally {
      if (key case final SecretKeyData data) data.destroy();
    }
  }

  Future<List<int>> decrypt({
    required List<int> containerBytes,
    required String passphrase,
  }) async {
    _checkPassphrase(passphrase);
    Map<String, Object?> container;
    try {
      final decoded = jsonDecode(utf8.decode(containerBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      container = Map<String, Object?>.from(decoded);
    } on Object catch (error) {
      throw PortableBackupException(
        PortableBackupFailureKind.invalidContainer,
        'The selected file is not a Clinical Calendar backup.',
        cause: error,
      );
    }
    final version = container['container_version'];
    if (version is int && version > containerVersion) {
      throw const PortableBackupException(
        PortableBackupFailureKind.unsupportedNewerVersion,
        'This backup uses a newer unsupported container version.',
      );
    }
    try {
      if (container['magic'] != magic ||
          version != containerVersion ||
          container['kdf'] != 'argon2id' ||
          container['cipher'] != 'aes-256-gcm') {
        throw const FormatException();
      }
      final parameters = PortableBackupCryptoPolicy(
        memoryKib: container['memory_kib'] as int,
        iterations: container['iterations'] as int,
        parallelism: container['parallelism'] as int,
        minimumPassphraseCharacters: policy.minimumPassphraseCharacters,
      );
      if (parameters.memoryKib < policy.memoryKib ||
          parameters.iterations < policy.iterations ||
          parameters.parallelism < 1 ||
          parameters.memoryKib > 1024 * 1024 ||
          parameters.iterations > 20 ||
          parameters.parallelism > 16) {
        throw const FormatException();
      }
      final salt = base64Url.decode(container['salt'] as String);
      final nonce = base64Url.decode(container['nonce'] as String);
      final ciphertext = base64Url.decode(container['ciphertext'] as String);
      final tag = base64Url.decode(container['authentication_tag'] as String);
      if (salt.length != 16 || nonce.length != 12 || tag.length != 16) {
        throw const FormatException();
      }
      final header = Map<String, Object?>.from(container)
        ..remove('ciphertext')
        ..remove('authentication_tag');
      final key = await _deriveKey(passphrase, salt, parameters);
      try {
        return await _cipher.decrypt(
          SecretBox(ciphertext, nonce: nonce, mac: Mac(tag)),
          secretKey: key,
          aad: utf8.encode(canonicalJson(header)),
        );
      } finally {
        if (key case final SecretKeyData data) data.destroy();
      }
    } on PortableBackupException {
      rethrow;
    } on SecretBoxAuthenticationError catch (error) {
      throw PortableBackupException(
        PortableBackupFailureKind.wrongPassphraseOrDamaged,
        'The passphrase is incorrect or the backup is damaged.',
        cause: error,
      );
    } on Object catch (error) {
      throw PortableBackupException(
        PortableBackupFailureKind.invalidContainer,
        'The backup encryption metadata is invalid.',
        cause: error,
      );
    }
  }

  Future<SecretKey> _deriveKey(
    String passphrase,
    List<int> salt,
    PortableBackupCryptoPolicy parameters,
  ) => Argon2id(
    memory: parameters.memoryKib,
    iterations: parameters.iterations,
    parallelism: parameters.parallelism,
    hashLength: 32,
  ).deriveKeyFromPassword(password: passphrase, nonce: salt);

  void _checkPassphrase(String value) {
    if (value.length < policy.minimumPassphraseCharacters) {
      throw PortableBackupException(
        PortableBackupFailureKind.weakPassphrase,
        'The backup passphrase must contain at least '
        '${policy.minimumPassphraseCharacters} characters.',
      );
    }
  }

  Uint8List _randomBytes(int length) => Uint8List.fromList(
    List<int>.generate(length, (_) => _random.nextInt(256)),
  );
}

String canonicalJson(Object? value) => jsonEncode(_canonical(value));

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonical(value[key]),
    };
  }
  if (value is Iterable) return value.map(_canonical).toList(growable: false);
  return value;
}
