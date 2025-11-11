/// Verification Status Constants and Helpers
///
/// Status Codes:
/// 0 = Pending approval (user cannot access app)
/// 1 = Verified (user can log in and use app)
/// 2 = Rejected (user cannot use app, must contact support)

class VerificationStatus {
  static const int pending = 0;
  static const int verified = 1;
  static const int rejected = 2;

  /// Get human-readable status name
  static String getStatusName(int status) {
    switch (status) {
      case pending:
        return 'Pending Approval';
      case verified:
        return 'Verified';
      case rejected:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  /// Check if user can access the app
  static bool canAccessApp(int status) {
    return status == verified;
  }

  /// Check if user is pending approval
  static bool isPending(int status) {
    return status == pending;
  }

  /// Check if user is rejected
  static bool isRejected(int status) {
    return status == rejected;
  }

  /// Get status description for UI
  static String getDescription(int status) {
    switch (status) {
      case pending:
        return 'Your account is under review. This usually takes 24-48 hours.';
      case verified:
        return 'Your account is verified and active.';
      case rejected:
        return 'Your account verification was rejected. Please contact support for more information.';
      default:
        return 'Unknown status';
    }
  }
}

