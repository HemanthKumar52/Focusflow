import 'dart:convert';

/// Simple encryption service for data at rest and transfer.
/// Uses XOR cipher with a user-provided passphrase — no external packages.
class EncryptionService {
  /// XOR-encrypts [plaintext] using [passphrase] and returns base64-encoded
  /// ciphertext.
  static String encrypt(String plaintext, String passphrase) {
    final keyBytes = utf8.encode(passphrase);
    final dataBytes = utf8.encode(plaintext);
    final encrypted = List<int>.generate(
      dataBytes.length,
      (i) => dataBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return base64Encode(encrypted);
  }

  /// Decrypts a base64-encoded [ciphertext] that was encrypted with
  /// [passphrase].
  static String decrypt(String ciphertext, String passphrase) {
    final keyBytes = utf8.encode(passphrase);
    final encryptedBytes = base64Decode(ciphertext);
    final decrypted = List<int>.generate(
      encryptedBytes.length,
      (i) => encryptedBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return utf8.decode(decrypted);
  }

  /// Produces a simple hash of [passphrase] by repeatedly XOR-folding into a
  /// 32-byte digest, then returning it as a hex string.
  static String hashPassphrase(String passphrase) {
    final bytes = utf8.encode(passphrase);
    final hash = List<int>.filled(32, 0);

    for (var i = 0; i < bytes.length; i++) {
      hash[i % 32] ^= bytes[i];
      // Simple mixing: rotate and add
      hash[i % 32] = ((hash[i % 32] * 31 + bytes[i]) & 0xFF);
    }

    return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Encrypts a JSON-serialisable [data] map with [passphrase] and returns
  /// an encrypted string.
  static String encryptBackup(
    Map<String, dynamic> data,
    String passphrase,
  ) {
    final jsonString = jsonEncode(data);
    return encrypt(jsonString, passphrase);
  }

  /// Decrypts an encrypted backup string back into a JSON map.
  static Map<String, dynamic> decryptBackup(
    String encrypted,
    String passphrase,
  ) {
    final jsonString = decrypt(encrypted, passphrase);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
