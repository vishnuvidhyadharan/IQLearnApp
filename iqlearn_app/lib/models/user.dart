class User {
  final int? id;
  final String? email;
  final String? mobile;
  final String? name;
  final String? groqApiKey;
  final DateTime? createdAt;

  User({
    this.id,
    this.email,
    this.mobile,
    this.name,
    this.groqApiKey,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'mobile': mobile,
      'name': name,
      'groq_api_key': groqApiKey,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      email: map['email'] as String?,
      mobile: map['mobile'] as String?,
      name: map['name'] as String?,
      groqApiKey: map['groq_api_key'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  User copyWith({
    int? id,
    String? email,
    String? mobile,
    String? name,
    String? groqApiKey,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      name: name ?? this.name,
      groqApiKey: groqApiKey ?? this.groqApiKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
