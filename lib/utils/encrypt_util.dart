import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:pointycastle/asymmetric/api.dart'; // For RSA key parsing
import 'dart:convert';
import 'package:crypto/crypto.dart';

// String exampleDecode() {
//   String jwtToken =
//       '''eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiJaSDdEcmhUMnpMcmpkX3dyamQtVUNlUDZteWsxdlBmQ0c1V2d2aU1IWlREUXRvdEpjNzFYeDR6V25YSzEzeTU5b1VpZkM1TGFUeFQwVEtQMG9WVDZVejFDeEdMM2tmTzlfajdZY2pEOTFZNDVHWG1SZVU2M0ZOX3dDa0lYUllIVFhUUzdpVm9nTVdJUEhrVU1xYk1aNWRpVU5kaDVwMUY0UE1WSUFXU2pua1BoWF81VTFLemtrdWdEMnJodk84TVBWbWhQYWp0ZXU5N2hwUlZ6MnpmMERQVm5tWGZBdWJSRGVBX1dNUGRlUEMxOWxpdHlHWlFsOXQ0aDNaVVFQMmNxUW1uZGZYM2hjTEpVQlZjRG9LdHJQMGFHanIzMDRxeGlLQlRqanFKYW9pWGdCZ215RnhCaURPZmF1WVJ0U3NuX0pEcHFzV2xKMnBMb0VZN3BYVi1pRFE9PSIsImNyZWF0ZWRfYXQiOiIyMDI1LTA4LTE1VDE1OjA1OjQxLjQxODExMCIsImV4cCI6MTc1NTI3NzU0MX0.FerZGzgN20ElCP83mnigI1F1HMKq_jhj4vTvwr1VUjk''';

//   final uid = decodeJwtAndGetUid(jwtToken);

//   debugPrint('uid: $uid');

//   const publicKeyPem = '''-----BEGIN PUBLIC KEY-----
// MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyyrCsTYxVOAspPqg/9Ua
// I6kCheAik1yXIKUblBaHkdRqGtpuQac1IOfkiZF5GrNdPtTpc+UhPpZpnpaBzYz3
// AWzvNSp1VdK+nvj2sfWfmQjeLmB+ugFQGy2TTpVr5+MakHoDqm8fLHdBSF0NWasB
// PNcOIXieVLi0WnabCXD5PSK5SSRsAejrx2LWZ8Y+wB3kQTj3MurhLDPypoMd2pIi
// TNhMBRuCYNmaOB+XkmqLu0iE9Syh022AO1waC7gciNn0n7JjNwPJfT579q+p9ERw
// pFYsV+OphYR7yULX3m5Pboe8A1AWdtg/Uba3k2XdhUviq9z3S55vzxZ1Mf4Ma5tz
// 8wIDAQAB
// -----END PUBLIC KEY-----''';

//   const privateKeyPem = '''-----BEGIN RSA PRIVATE KEY-----
// MIIEowIBAAKCAQEAn9EcL1e+WAeOFlcIqvPlWKJPrGKINx5Iop3VEG33iZOWIO0+
// Q3O3KGTDA1hi833mXyxhM978FAMbqvPOmWv0OZeURFdUf9KhGmBV/yY9fKsroSHt
// 2dW3IwjXGvmrFLi6hUfxJrgP5tzaErYGpSUyZWUxIKmMGwd5wO9wzVEyFSE0+Kd7
// +GwE+gBBS6CUMPHtNd4ReYVTYFsy0f7QWsEdWpvT3gaYxan9Z67rHyon4ZLEzQlk
// 3HawJM+uedJdwr/lsWD6VbG1mf2VrUKVTVjXFAR28vuCATchJs8PGvao0c2tKsQS
// LykKayNOJ6HPC/gLc5QYDAXhTPnTkgDnCX7QswIDAQABAoIBAC79d4mOBYfxlLwJ
// 1CEbvEv+0WlQwVdffqDdwmdlxfo8HFDLINsJW4mzcsl5hAKu+nzyWhQ71Kd3sHtn
// 20+t9621XWFowg4hWsAcIjz2u+57j8T9amd52LKi50hlr4FUvXbxy7yEMxzAxBfr
// UHHfSX2ZrsO5RlouLQTnAiZEYPLoDQQXLdqNXzColLGP9ZVHlOIFkB6fbWGsusHc
// ZM58ti1com1kFPtVFbMgGoEYhMgc+Jr87KspJjPlu12kcAypDky6El5wq0Nq0dDw
// wXrz6PwqxyhB8n0zsmE24lfDFOXoZFuBNQSYUfV0xMu1AQ+m8tT5xJiLSSPGMtdm
// IEf8iCUCgYEA1TaM3fjphUwzMs9Y3eHPocFyL9U9o2sgWxbFmkJ5D0QY0jF7uTnA
// T9K4uQ0O7lXQFpwxSigkgbF3F+xiN+Ag4Gia0AEauDIELrlNtS1O84UcIddTXCY6
// 1KdilQOm3LCzAdfkTc/tVcTso5/VOrajSyVB7CxIIRcjYUmzr+lrZZcCgYEAv+Nr
// t7qA0lN1Lu0W+Sn3X+Y+Uw4tE7IO5WF3ZAKeoEqDP5wFq6ECRnc2RnX/bwYgoy2J
// JeVkeh9pJrt19S4jxiLA4GXcMKO5N9HyA3lzJF6IUNEBcrBKezyFuz1tlmCakcOo
// htgSQUbLv/JUW5Hue0pEhRSLhFHTP/F/C79a6UUCgYAdqsR5Emxz1sF8/WrxHL2G
// VWNtEm/MMFjFM+r05vDvVdtaS/ZaNJX0xW5cmVuNgDU/ICafmexSe34Fvyd/fNk2
// QHfiH3U3UgZQ9gnA/vfwXIIol0yLEuq2sj++Wk66gH+37vFefmMYvxjqP5As5kLc
// bue4VAUJTa3nmJi/DmyaKwKBgEeSD49LpNjOABssmzD8EiRWwFBCLVX3R88Od3V5
// 9Khcom+LRiIpv6uAs2G8iTVj17CFP24/DSbvqEymBu0X9IfmVoJb+7C4oFDNobLi
// Daw3Bij+i8e3MVCd1lNsKf+4sG5FyAnjdYubWEuTmxs8ZvLdVIk+jHsh+eUTsgsz
// qDjxAoGBAJnuL6pmkG+0LApV8KdhXx9+IkiOHG23w1cs/msHFhJi+fYlPnratpEr
// CXJVgfVKAH6PxNmogJTCYogFhJJE2vTX4F6ubBFkjXUSR3viznv97HgYfLLfHx4b
// gkBRsEuVAP9Xhxup2yRXJmZCEbanjcBv8QBNpeb755WqZPjPiIJs
// -----END RSA PRIVATE KEY-----
// ''';

//   final publicKey = parsePublicKeyFromPem(publicKeyPem);
//   final privateKey = parsePrivateKeyFromPem(privateKeyPem);

//   // const plainText = "Hi Hello My Name is Someshwar Karmakar from HFG";

//   // // Encrypt the data
//   // encryptData(plainText, publicKey);

//   // // Assume we receive the encrypted data (base64 format)
//   // final encryptedBase64 = encryptData(
//   //   plainText,
//   //   publicKey,
//   // ); // Use the actual encrypted data from above

//   // Decrypt the data
//   var decryptedData = decryptData(uid ?? '', privateKey);

//   var encryptedData = encryptData(decryptedData, publicKey);

//   debugPrint('encryptedData: $encryptedData');

//   final jwtEncoded = createJwtWithExpiry(
//     encryptedUuid: encryptedData,
//     expiryInSeconds: 3600 * 5,
//     secretKey: 'dev',
//   );

//   debugPrint('jwtEncoded: $jwtEncoded');

//   return jwtEncoded;
// }

RSAPublicKey parsePublicKeyFromPem(String pem) {
  final parser = RSAKeyParser();
  return parser.parse(pem) as RSAPublicKey;
}

RSAPrivateKey parsePrivateKeyFromPem(String pem) {
  final parser = RSAKeyParser();
  return parser.parse(pem) as RSAPrivateKey;
}

String encryptData(String plainText) {

  const publicKeyPem = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyyrCsTYxVOAspPqg/9Ua
I6kCheAik1yXIKUblBaHkdRqGtpuQac1IOfkiZF5GrNdPtTpc+UhPpZpnpaBzYz3
AWzvNSp1VdK+nvj2sfWfmQjeLmB+ugFQGy2TTpVr5+MakHoDqm8fLHdBSF0NWasB
PNcOIXieVLi0WnabCXD5PSK5SSRsAejrx2LWZ8Y+wB3kQTj3MurhLDPypoMd2pIi
TNhMBRuCYNmaOB+XkmqLu0iE9Syh022AO1waC7gciNn0n7JjNwPJfT579q+p9ERw
pFYsV+OphYR7yULX3m5Pboe8A1AWdtg/Uba3k2XdhUviq9z3S55vzxZ1Mf4Ma5tz
8wIDAQAB
-----END PUBLIC KEY-----''';

  final publicKey = parsePublicKeyFromPem(publicKeyPem);

  final encrypter = Encrypter(
    RSA(
      publicKey: publicKey,
      encoding: RSAEncoding.OAEP,
      digest: RSADigest.SHA256,
    ),
  );

  // Encrypt the data
  final encryptedData = encrypter.encrypt(plainText);
  return encryptedData.base64; // Encrypted output in base64 format
}

String decryptData(String encryptedBase64) {
  const privateKeyPem = '''-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAn9EcL1e+WAeOFlcIqvPlWKJPrGKINx5Iop3VEG33iZOWIO0+
Q3O3KGTDA1hi833mXyxhM978FAMbqvPOmWv0OZeURFdUf9KhGmBV/yY9fKsroSHt
2dW3IwjXGvmrFLi6hUfxJrgP5tzaErYGpSUyZWUxIKmMGwd5wO9wzVEyFSE0+Kd7
+GwE+gBBS6CUMPHtNd4ReYVTYFsy0f7QWsEdWpvT3gaYxan9Z67rHyon4ZLEzQlk
3HawJM+uedJdwr/lsWD6VbG1mf2VrUKVTVjXFAR28vuCATchJs8PGvao0c2tKsQS
LykKayNOJ6HPC/gLc5QYDAXhTPnTkgDnCX7QswIDAQABAoIBAC79d4mOBYfxlLwJ
1CEbvEv+0WlQwVdffqDdwmdlxfo8HFDLINsJW4mzcsl5hAKu+nzyWhQ71Kd3sHtn
20+t9621XWFowg4hWsAcIjz2u+57j8T9amd52LKi50hlr4FUvXbxy7yEMxzAxBfr
UHHfSX2ZrsO5RlouLQTnAiZEYPLoDQQXLdqNXzColLGP9ZVHlOIFkB6fbWGsusHc
ZM58ti1com1kFPtVFbMgGoEYhMgc+Jr87KspJjPlu12kcAypDky6El5wq0Nq0dDw
wXrz6PwqxyhB8n0zsmE24lfDFOXoZFuBNQSYUfV0xMu1AQ+m8tT5xJiLSSPGMtdm
IEf8iCUCgYEA1TaM3fjphUwzMs9Y3eHPocFyL9U9o2sgWxbFmkJ5D0QY0jF7uTnA
T9K4uQ0O7lXQFpwxSigkgbF3F+xiN+Ag4Gia0AEauDIELrlNtS1O84UcIddTXCY6
1KdilQOm3LCzAdfkTc/tVcTso5/VOrajSyVB7CxIIRcjYUmzr+lrZZcCgYEAv+Nr
t7qA0lN1Lu0W+Sn3X+Y+Uw4tE7IO5WF3ZAKeoEqDP5wFq6ECRnc2RnX/bwYgoy2J
JeVkeh9pJrt19S4jxiLA4GXcMKO5N9HyA3lzJF6IUNEBcrBKezyFuz1tlmCakcOo
htgSQUbLv/JUW5Hue0pEhRSLhFHTP/F/C79a6UUCgYAdqsR5Emxz1sF8/WrxHL2G
VWNtEm/MMFjFM+r05vDvVdtaS/ZaNJX0xW5cmVuNgDU/ICafmexSe34Fvyd/fNk2
QHfiH3U3UgZQ9gnA/vfwXIIol0yLEuq2sj++Wk66gH+37vFefmMYvxjqP5As5kLc
bue4VAUJTa3nmJi/DmyaKwKBgEeSD49LpNjOABssmzD8EiRWwFBCLVX3R88Od3V5
9Khcom+LRiIpv6uAs2G8iTVj17CFP24/DSbvqEymBu0X9IfmVoJb+7C4oFDNobLi
Daw3Bij+i8e3MVCd1lNsKf+4sG5FyAnjdYubWEuTmxs8ZvLdVIk+jHsh+eUTsgsz
qDjxAoGBAJnuL6pmkG+0LApV8KdhXx9+IkiOHG23w1cs/msHFhJi+fYlPnratpEr
CXJVgfVKAH6PxNmogJTCYogFhJJE2vTX4F6ubBFkjXUSR3viznv97HgYfLLfHx4b
gkBRsEuVAP9Xhxup2yRXJmZCEbanjcBv8QBNpeb755WqZPjPiIJs
-----END RSA PRIVATE KEY-----
''';

  final privateKey = parsePrivateKeyFromPem(privateKeyPem);
  final encrypter = Encrypter(
    RSA(
      privateKey: privateKey,
      encoding: RSAEncoding.OAEP,
      digest: RSADigest.SHA256,
    ),
  );
  // Decrypt the base64-encoded data
  final encrypted = Encrypted.fromBase64(encryptedBase64);
  final decryptedData = encrypter.decrypt(encrypted);
  return decryptedData; // Decrypted output (original plain text)
}

/// Decodes a JWT token and extracts the UID from the payload
///
/// [jwtToken] - The JWT token string to decode
/// Returns the UID as a String, or null if the token is invalid or UID is not found
String? decodeJwtAndGetUid(String jwtToken) {
  try {
    // Split the JWT token into its three parts (header.payload.signature)
    final parts = jwtToken.split('.');
    if (parts.length != 3) {
      print('Invalid JWT token format');
      return null;
    }

    // Get the payload part (second part)
    final payload = parts[1];

    // Add padding if necessary for base64 decoding
    String paddedPayload = payload;
    while (paddedPayload.length % 4 != 0) {
      paddedPayload += '=';
    }

    // Decode the base64 payload
    final decodedBytes = base64Url.decode(paddedPayload);
    final decodedString = utf8.decode(decodedBytes);

    // Parse the JSON payload
    final Map<String, dynamic> payloadMap = json.decode(decodedString);

    // Extract the UID from the payload
    final uid = payloadMap['uid'];

    return uid?.toString();
  } catch (e) {
    print('Error decoding JWT token: $e');
    return null;
  }
}

/// Decodes a JWT token and returns the complete payload as a Map
///
/// [jwtToken] - The JWT token string to decode
/// Returns the complete payload as Map<String, dynamic>, or null if the token is invalid
Map<String, dynamic>? decodeJwtPayload(String jwtToken) {
  try {
    // Split the JWT token into its three parts (header.payload.signature)
    final parts = jwtToken.split('.');
    if (parts.length != 3) {
      print('Invalid JWT token format');
      return null;
    }

    // Get the payload part (second part)
    final payload = parts[1];

    // Add padding if necessary for base64 decoding
    String paddedPayload = payload;
    while (paddedPayload.length % 4 != 0) {
      paddedPayload += '=';
    }

    // Replace URL-safe characters
    paddedPayload = paddedPayload.replaceAll('-', '+').replaceAll('_', '/');

    // Decode the base64 payload
    final decodedBytes = base64Url.decode(payload);
    final decodedString = utf8.decode(decodedBytes);

    // Parse the JSON payload
    return json.decode(decodedString);
  } catch (e) {
    print('Error decoding JWT payload: $e');
    return null;
  }
}

/// Validates if a JWT token is expired
///
/// [jwtToken] - The JWT token string to validate
/// Returns true if the token is expired, false otherwise
bool isJwtExpired(String jwtToken) {
  try {
    final payload = decodeJwtPayload(jwtToken);
    if (payload == null) return true;

    final exp = payload['exp'];
    if (exp == null) return false; // No expiration claim

    final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final currentTime = DateTime.now();

    return currentTime.isAfter(expirationTime);
  } catch (e) {
    print('Error checking JWT expiration: $e');
    return true; // Consider invalid tokens as expired
  }
}

/// Encodes a JWT token with the specified payload format
///
/// [encryptedUuid] - The encrypted UUID data
/// [expiryTime] - Expiry timestamp (exp)
/// [issuedAt] - Issued at timestamp (iat)
/// [secretKey] - Secret key for signing the JWT
/// Returns the encoded JWT token as a String
String encodeJwt({
  required String encryptedUuid,
  required int expiryTime,
  required int issuedAt,
  required String secretKey,
}) {
  try {
    // Create the header
    final header = {'alg': 'HS256', 'typ': 'JWT'};

    // Create the payload
    final payload = {'exp': expiryTime, 'iat': issuedAt, 'uuid': encryptedUuid};

    // Encode header and payload to base64
    final encodedHeader = base64Url
        .encode(utf8.encode(json.encode(header)))
        .replaceAll('=', '');
    final encodedPayload = base64Url
        .encode(utf8.encode(json.encode(payload)))
        .replaceAll('=', '');

    // Create the signature input
    final signatureInput = '$encodedHeader.$encodedPayload';

    // Create HMAC-SHA256 signature
    final key = utf8.encode(secretKey);
    final signature = _createHmacSha256Signature(signatureInput, key);
    final encodedSignature = base64Url.encode(signature).replaceAll('=', '');

    // Combine all parts to create JWT
    return '$encodedHeader.$encodedPayload.$encodedSignature';
  } catch (e) {
    print('Error encoding JWT token: $e');
    return '';
  }
}

/// Creates HMAC-SHA256 signature for JWT
List<int> _createHmacSha256Signature(String data, List<int> key) {
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(utf8.encode(data));
  return digest.bytes;
}

/// Helper function to create JWT with current timestamp
///
/// [encryptedUuid] - The encrypted UUID data
/// [expiryInSeconds] - How many seconds from now the token should expire
/// [secretKey] - Secret key for signing the JWT
/// Returns the encoded JWT token as a String
String createJwtWithExpiry({
  required String encryptedUuid,
  required int expiryInSeconds,
  required String secretKey,
}) {
  final now = DateTime.now();
  final issuedAt = now.millisecondsSinceEpoch ~/ 1000; // Convert to seconds
  final expiryTime = issuedAt + expiryInSeconds;

  return encodeJwt(
    encryptedUuid: encryptedUuid,
    expiryTime: expiryTime,
    issuedAt: issuedAt,
    secretKey: secretKey,
  );
}

// JWT Decode --> uid --> decrypt --> (uid,privateKey)

// /// Processes JWT token from API header - decrypts the UID and returns the original data
// ///
// /// [jwtToken] - JWT token received from API header
// /// [privateKeyPem] - Private key in PEM format for decryption
// /// Returns the decrypted original data, or null if processing fails
// String? processJwtTokenFromApiHeader(String jwtToken, String privateKeyPem) {
//   try {
//     // Step 1: Decode JWT and extract UID
//     final uid = decodeJwtAndGetUid(jwtToken);
//     if (uid == null) {
//       print('Failed to extract UID from JWT token');
//       return null;
//     }

//     // Step 2: Parse private key
//     final privateKey = parsePrivateKeyFromPem(privateKeyPem);

//     // Step 3: Decrypt the UID to get original data
//     final decryptedData = decryptData(uid, privateKey);

//     return decryptedData;
//   } catch (e) {
//     print('Error processing JWT token from API header: $e');
//     return null;
//   }
// }

/// Creates a new JWT token with encrypted data for API requests
///
/// [originalData] - The original data to be encrypted and included in JWT
/// [publicKeyPem] - Public key in PEM format for encryption
/// [expiryInSeconds] - Token expiry time in seconds (default: 5 hours)
/// [secretKey] - Secret key for JWT signing (default: 'dev')
/// Returns the encoded JWT token, or null if processing fails
// String? createJwtTokenForApiRequest({
//   required String originalData,
//   required String publicKeyPem,
//   int expiryInSeconds = 3600 * 5, // 5 hours default
//   String secretKey = 'dev',
// }) {
//   try {
//     // Step 1: Parse public key
//     final publicKey = parsePublicKeyFromPem(publicKeyPem);

//     // Step 2: Encrypt the original data
//     final encryptedData = encryptData(originalData, publicKey);

//     // Step 3: Create JWT with encrypted data
//     final jwtToken = createJwtWithExpiry(
//       encryptedUuid: encryptedData,
//       expiryInSeconds: expiryInSeconds,
//       secretKey: secretKey,
//     );

//     return jwtToken;
//   } catch (e) {
//     print('Error creating JWT token for API request: $e');
//     return null;
//   }
// }

// /// Validates and processes JWT token from API header with built-in expiration check
// ///
// /// [jwtToken] - JWT token received from API header
// /// [privateKeyPem] - Private key in PEM format for decryption
// /// Returns the decrypted original data, or null if token is invalid/expired
// String? validateAndProcessJwtToken(String jwtToken, String privateKeyPem) {
//   try {
//     // Step 1: Check if JWT is expired
//     if (isJwtExpired(jwtToken)) {
//       print('JWT token is expired');
//       return null;
//     }

//     // Step 2: Process the JWT token
//     return processJwtTokenFromApiHeader(jwtToken, privateKeyPem);
//   } catch (e) {
//     print('Error validating and processing JWT token: $e');
//     return null;
//   }
// }

// /// Complete JWT token lifecycle management for API communication
// ///
// /// [originalData] - Original data to be encrypted
// /// [publicKeyPem] - Public key for encryption
// /// [privateKeyPem] - Private key for decryption
// /// [expiryInSeconds] - Token expiry time in seconds
// /// [secretKey] - Secret key for JWT signing
// /// Returns a map containing the created JWT token and a function to process received tokens
// Map<String, dynamic> createJwtTokenManager({
//   required String originalData,
//   required String publicKeyPem,
//   required String privateKeyPem,
//   int expiryInSeconds = 3600 * 5,
//   String secretKey = 'dev',
// }) {
//   // Create JWT token for sending
//   final jwtToken = createJwtTokenForApiRequest(
//     originalData: originalData,
//     publicKeyPem: publicKeyPem,
//     expiryInSeconds: expiryInSeconds,
//     secretKey: secretKey,
//   );

//   // Function to process received JWT tokens
//   String? processReceivedToken(String receivedJwtToken) {
//     return validateAndProcessJwtToken(receivedJwtToken, privateKeyPem);
//   }

//   return {'jwtToken': jwtToken, 'processReceivedToken': processReceivedToken};
// }

// /// Utility function to extract and validate JWT token from Authorization header
// ///
// /// [authorizationHeader] - Authorization header value (e.g., "Bearer <token>")
// /// [privateKeyPem] - Private key in PEM format for decryption
// /// Returns the decrypted original data, or null if processing fails
// String? processJwtFromAuthorizationHeader(
//   String authorizationHeader,
//   String privateKeyPem,
// ) {
//   try {
//     // Extract token from "Bearer <token>" format
//     if (!authorizationHeader.startsWith('Bearer ')) {
//       print('Invalid Authorization header format. Expected "Bearer <token>"');
//       return null;
//     }

//     final jwtToken = authorizationHeader.substring(
//       7,
//     ); // Remove "Bearer " prefix

//     // Process the JWT token
//     return validateAndProcessJwtToken(jwtToken, privateKeyPem);
//   } catch (e) {
//     print('Error processing JWT from Authorization header: $e');
//     return null;
//   }
// }

// /// API Response model for JWT token extraction
// class JwtApiResponse {
//   final String? jwtToken;
//   final Map<String, dynamic>? responseData;
//   final bool success;
//   final String? errorMessage;

//   JwtApiResponse({
//     this.jwtToken,
//     this.responseData,
//     required this.success,
//     this.errorMessage,
//   });
// }

// /// Processes API response and extracts JWT token from Authorization header
// ///
// /// [response] - Dio Response object from API call
// /// [privateKeyPem] - Private key in PEM format for decryption
// /// Returns JwtApiResponse with extracted token and decrypted data
// JwtApiResponse processApiResponseWithJwt(
//   dynamic response,
//   String privateKeyPem,
// ) {
//   try {
//     // Extract Authorization header from response
//     final headers = response.headers;
//     final authorizationHeader =
//         headers.value('authorization') ?? headers.value('Authorization');

//     if (authorizationHeader == null) {
//       return JwtApiResponse(
//         success: false,
//         errorMessage: 'No Authorization header found in response',
//       );
//     }

//     // Process JWT token from Authorization header
//     final decryptedData = processJwtFromAuthorizationHeader(
//       authorizationHeader,
//       privateKeyPem,
//     );

//     if (decryptedData == null) {
//       return JwtApiResponse(
//         success: false,
//         errorMessage: 'Failed to process JWT token from Authorization header',
//       );
//     }

//     return JwtApiResponse(
//       jwtToken: authorizationHeader,
//       responseData: response.data,
//       success: true,
//     );
//   } catch (e) {
//     return JwtApiResponse(
//       success: false,
//       errorMessage: 'Error processing API response: $e',
//     );
//   }
// }

// /// Specific function for /api/usersNew/fid/{fid} endpoint
// ///
// /// [fid] - Firebase ID to check
// /// [privateKeyPem] - Private key in PEM format for decryption
// /// [dio] - Dio instance for making HTTP request
// /// Returns the decrypted user data from JWT token
// Future<String?> processUsersNewFidApi({
//   required String fid,
//   required String privateKeyPem,
//   required dynamic dio, // Dio instance
// }) async {
//   try {
//     // Make API call to /api/usersNew/fid/{fid}
//     final response = await dio.get('/api/usersNew/fid/$fid');

//     // Process the response to extract JWT from Authorization header
//     final jwtResponse = processApiResponseWithJwt(response, privateKeyPem);

//     if (!jwtResponse.success) {
//       print(
//         'Failed to process JWT from API response: ${jwtResponse.errorMessage}',
//       );
//       return null;
//     }

//     // Extract the decrypted data from the JWT token
//     final decryptedData = processJwtFromAuthorizationHeader(
//       jwtResponse.jwtToken!,
//       privateKeyPem,
//     );

//     return decryptedData;
//   } catch (e) {
//     print('Error calling /api/usersNew/fid/$fid: $e');
//     return null;
//   }
// }

// /// Enhanced function for /api/usersNew/fid/{fid} with complete response handling
// ///
// /// [fid] - Firebase ID to check
// /// [privateKeyPem] - Private key in PEM format for decryption
// /// [dio] - Dio instance for making HTTP request
// /// Returns complete response with JWT token and decrypted data
// Future<JwtApiResponse> callUsersNewFidApi({
//   required String fid,
//   required String privateKeyPem,
//   required dynamic dio, // Dio instance
// }) async {
//   try {
//     // Make API call to /api/usersNew/fid/{fid}
//     final response = await dio.get(ApiEndpoints.checkUserExistsInAPI + fid);

//     // Process the response to extract JWT from Authorization header
//     final jwtResponse = processApiResponseWithJwt(response, privateKeyPem);

//     if (!jwtResponse.success) {
//       return jwtResponse;
//     }

//     // Extract the decrypted data from the JWT token
//     final decryptedData = processJwtFromAuthorizationHeader(
//       jwtResponse.jwtToken!,
//       privateKeyPem,
//     );

//     if (decryptedData == null) {
//       return JwtApiResponse(
//         success: false,
//         errorMessage: 'Failed to decrypt data from JWT token',
//       );
//     }

//     // Return success response with both JWT token and decrypted data
//     return JwtApiResponse(
//       jwtToken: jwtResponse.jwtToken,
//       responseData: {
//         ...jwtResponse.responseData ?? {},
//         'decryptedData': decryptedData,
//       },
//       success: true,
//     );
//   } catch (e) {
//     return JwtApiResponse(
//       success: false,
//       errorMessage: 'Error calling /api/usersNew/fid/$fid: $e',
//     );
//   }
// }

// /// Helper function to extract JWT token from any API response headers
// ///
// /// [response] - Dio Response object
// /// Returns the JWT token from Authorization header, or null if not found
String? extractJwtFromResponse(dynamic response) {
  try {
    final headers = response.headers;
    final authorizationHeader =
        headers.value('authorization') ?? headers.value('Authorization');

    if (authorizationHeader == null) {
      return null;
    }

    // Extract token from "Bearer <token>" format
    if (!authorizationHeader.startsWith('Bearer ')) {
      return null;
    }

    return authorizationHeader.substring(7); // Remove "Bearer " prefix
  } catch (e) {
    print('Error extracting JWT from response: $e');
    return null;
  }
}

// /// Complete workflow function for JWT token API integration
// ///
// /// [fid] - Firebase ID
// /// [privateKeyPem] - Private key for decryption
// /// [publicKeyPem] - Public key for encryption (if needed for subsequent requests)
// /// [dio] - Dio instance
// /// Returns complete workflow result
// Future<Map<String, dynamic>> completeJwtWorkflow({
//   required String fid,
//   required String privateKeyPem,
//   required String publicKeyPem,
//   required dynamic dio,
// }) async {
//   try {
//     // Step 1: Call the API and get JWT token
//     final apiResponse = await callUsersNewFidApi(
//       fid: fid,
//       privateKeyPem: privateKeyPem,
//       dio: dio,
//     );

//     if (!apiResponse.success) {
//       return {'success': false, 'error': apiResponse.errorMessage};
//     }

//     // Step 2: Extract decrypted data
//     final decryptedData = apiResponse.responseData?['decryptedData'];

//     // Step 3: Create a new JWT token for subsequent API calls (if needed)
//     final newJwtToken = createJwtTokenForApiRequest(
//       originalData: decryptedData ?? '',
//       publicKeyPem: publicKeyPem,
//       expiryInSeconds: 3600, // 1 hour
//       secretKey: 'dev',
//     );

//     return {
//       'success': true,
//       'originalJwtToken': apiResponse.jwtToken,
//       'decryptedData': decryptedData,
//       'newJwtToken': newJwtToken,
//       'responseData': apiResponse.responseData,
//     };
//   } catch (e) {
//     return {'success': false, 'error': 'Complete workflow failed: $e'};
//   }
// }
