part of login_with_amazon;

class AmazonUser {
  AmazonUser({
    this.email,
    this.userId,
  });

  final String email;
  final String userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AmazonUser &&
              runtimeType == other.runtimeType &&
              email == other.email &&
              userId == other.userId;

  @override
  int get hashCode =>
      email.hashCode ^
      userId.hashCode;

  @override
  String toString() {
    return 'AmazonUser{email: $email, userId: $userId}';
  }
}

