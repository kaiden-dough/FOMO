class User {
  final String id;
  final String name;
  final String avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  factory User.fromBackend({
    required String id,
    required String username,
  }) {
    return User(
      id: id,
      name: username,
      avatarUrl: 'https://api.dicebear.com/9.x/identicon/png?seed=$username',
    );
  }

  @override
  bool operator ==(Object other) => other is User && other.id == id;

  @override
  int get hashCode => id.hashCode;
}