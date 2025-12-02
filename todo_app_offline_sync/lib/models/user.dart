/// User model representing an authenticated user
class User {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  User({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  /// Converts this user to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  /// Creates a user from a JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      uid,
      email,
      displayName,
      photoUrl,
    );
  }

  @override
  String toString() {
    return 'User(uid: $uid, email: $email, displayName: $displayName)';
  }
}
