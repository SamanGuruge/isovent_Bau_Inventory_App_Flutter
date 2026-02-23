import 'dart:math';

class OtpService {
  static final Map<String, _OtpSession> _sessions = <String, _OtpSession>{};

  Future<void> sendOtp({
    required String email,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final code = (Random().nextInt(9000) + 1000).toString();
    _sessions[email.toLowerCase()] = _OtpSession(
      code: code,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  bool verifyOtp({required String email, required String code}) {
    final session = _sessions[email.toLowerCase()];
    if (session == null) {
      return false;
    }
    if (DateTime.now().isAfter(session.expiresAt)) {
      _sessions.remove(email.toLowerCase());
      return false;
    }
    final isValid = session.code == code;
    if (isValid) {
      _sessions.remove(email.toLowerCase());
    }
    return isValid;
  }

  String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) {
      return email;
    }
    final local = parts.first;
    if (local.length <= 2) {
      return '*****@${parts.last}';
    }
    final start = local.substring(0, 1);
    final end = local.substring(local.length - 2);
    return '$start****$end@${parts.last}';
  }
}

class _OtpSession {
  _OtpSession({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}
