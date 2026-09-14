enum Role {
  admin,
  user;

  /// Human-readable label for UI display.
  String get label {
    switch (this) {
      case Role.admin:
        return 'Admin';
      case Role.user:
        return 'User';
    }
  }
}
